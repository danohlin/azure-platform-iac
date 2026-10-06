# azure-platform-iac

A Terraform learning project that deploys the most commonly used Azure services, wired together the way a real workload would be, with passwordless managed identity, RBAC, VNet integration, and centralized monitoring. It uses the cheapest SKUs, and it's designed to be applied and destroyed repeatedly.

## What gets deployed

| Module | Azure service | What it teaches | SKU |
|---|---|---|---|
| `resource-group` | Resource Group + Budget | Scoping, tagging, cost alerts | free |
| `network` | VNet, subnets, NSGs | Delegation, service endpoints, NSG rules | free |
| `monitoring` | Log Analytics + Application Insights | Centralized logs and APM | PerGB, 1 GB/day cap |
| `identity` | User-assigned managed identity | Passwordless auth between services | free |
| `key-vault` | Key Vault (RBAC mode) | Secrets, Key Vault references | Standard |
| `storage` | Storage account, blob, queue, lifecycle | Entra-only data access, tiering | Standard_LRS |
| `sql` | Azure SQL server + database | Entra admin, VNet rules, firewall | Basic (5 DTU) |
| `container-registry` | Container Registry | Image storage, AcrPull via identity | Basic |
| `app-service` | App Service (Linux, Node 24) | PaaS web hosting, VNet integration | B1 |
| `container-apps` | Container Apps | Serverless containers, scale to zero | Consumption |
| `function-app` | Azure Functions | Event-driven serverless | Flex Consumption |

```
bootstrap/   one-time: storage account for remote Terraform state (local state)
envs/dev/    the root module: calls every module below
modules/     one folder per service
```

### How the pieces connect

- **One managed identity** is shared by the web app, container app, and function app. It gets `Key Vault Secrets User`, `Storage Blob Data Owner` / `Queue Data Contributor`, and `AcrPull`. No keys or connection strings are handed out.
- **App Service** runs in `snet-app`. The subnet's `Microsoft.Sql` service endpoint and a SQL VNet rule let it reach the database without opening SQL to "all Azure services". Its `GREETING` setting is a **Key Vault reference**.
- **Container Apps** runs in `container_apps_location` (default `westus2`) because centralus had no Container Apps capacity (see Troubleshooting). A VNet-injected environment must share its VNet's region, so for now it uses an Azure-managed network instead of `snet-container-apps`. Passing `subnet_id` to the module again turns VNet injection back on once both are in the same region. It still pulls from ACR with the managed identity and ships logs to the central Log Analytics workspace. The app scales to zero when idle, so expect a cold start of about 15 seconds on the first request.
- **Functions (Flex Consumption)** reads its code package and host storage from the storage account through the managed identity. Shared-key access on that account is disabled.
- **SQL** has you as the Entra admin. A generated SQL-auth password is also stored in Key Vault as `sql-admin-password`, as a break-glass path.

## Cost

About **$20–25/month if left running**, mostly the App Service B1 plan (~$13) and SQL Basic (~$5). Everything else is consumption-based and effectively $0 at idle. The budget in `resource-group` emails you at 50% and 80% of actual spend and at 100% of forecast.

**Run `terraform destroy` when you finish a session.** An hour of use costs a few cents.

## Prerequisites

- Terraform >= 1.15 (tested with 1.15.7; current is 1.16.x)
- Azure CLI, logged in: `az login`, then `az account set --subscription <id>`
- Your account needs **Owner** or **User Access Administrator + Contributor** on the subscription, because this config creates role assignments.
- VS Code: open the folder and accept the recommended extensions.

## First-time setup

### 1. Bootstrap remote state (once)

```sh
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # fill in subscription_id
terraform init
terraform apply
terraform output -raw backend_config > ../envs/dev/dev.tfbackend
```

`bootstrap/terraform.tfstate` stays local and gitignored. Don't delete it, or Terraform loses track of the state account.

### 2. Deploy the platform

```sh
cd ../envs/dev
cp terraform.tfvars.example terraform.tfvars   # subscription, email, UPN
terraform init -backend-config=dev.tfbackend
terraform plan -out=tfplan
terraform apply tfplan
```

The first apply takes about 10–15 minutes. Most of that is the Container Apps environment, plus three deliberate 60-second pauses that let RBAC assignments propagate before anything uses them.

### 3. Try it out

```sh
terraform output
curl -I "$(terraform output -raw web_app_url)"
curl    "$(terraform output -raw container_app_url)"
az keyvault secret show --vault-name "$(terraform output -raw key_vault_name)" -n app-greeting --query value
az storage blob list --account-name "$(terraform output -raw storage_account_name)" -c data --auth-mode login
az acr repository list -n "$(terraform output -raw acr_name)"
```

Then look at it all in the portal. **Application Insights → Live metrics / Transaction search** shows the requests you just made.

## Daily loop

```sh
cd envs/dev
terraform apply      # start of session
# ...experiment...
terraform destroy    # end of session (bootstrap stays)
```

## Secret scanning

- **Locally:** `.githooks/pre-commit` runs gitleaks on staged changes and blocks the commit on a finding. Enable it once per clone with `git config core.hooksPath .githooks`. Requires [gitleaks](https://github.com/gitleaks/gitleaks) on `PATH`.
- **In CI:** `.github/workflows/secret-scan.yml` runs gitleaks over the full history and trufflehog over the pushed commits (`--results=verified,unknown`) on every push to `main` and every pull request.

## Ideas for next steps

- Push your own image: `az acr build -r <acr> -t hello:v1 .`, then set the `image` variable in the `container-apps` module.
- Deploy the queue function in `apps/func-jobs` (runs `processJob` for each message on the `jobs` queue): run `npm install` there, zip `host.json package.json package-lock.json src node_modules`, then `az functionapp deployment source config-zip -g <rg> -n <func> --src func-jobs.zip`. Afterwards, remove the stray `AzureWebJobsStorage` setting (see Troubleshooting).
- Let the managed identity into SQL: connect as yourself and run `CREATE USER [id-azplat-dev] FROM EXTERNAL PROVIDER; ALTER ROLE db_datareader ADD MEMBER [id-azplat-dev];`
- Replace public access with **private endpoints** in `snet-data` (Key Vault, Storage, SQL, ACR).
- Add diagnostic settings that send every resource's logs to Log Analytics.
- Add a `prod` environment under `envs/` that reuses the same modules with bigger SKUs.

## Troubleshooting

- **403 writing a Key Vault secret, or a Function app that won't start:** RBAC propagation took longer than 60 seconds. Run `terraform apply` again.
- **SQL `ProvisioningDisabled` / "Provisioning is restricted in this region":** Azure limits new SQL servers in busy regions (East US, East US 2, North Central US) for many subscriptions. SQL VNet rules only work when the VNet and the server are in the same region, so move the whole environment rather than just SQL. Before choosing a region, check it (`Available` means OK, `Visible` means restricted):
  ```powershell
  $sub = az account show --query id -o tsv
  az rest --method get --url "https://management.azure.com/subscriptions/$sub/providers/Microsoft.Sql/locations/centralus/capabilities?api-version=2023-08-01" --query status -o tsv
  ```
- **`MissingSubscriptionRegistration`:** the subscription hasn't enabled that service's resource provider. Run `az provider register -n <Namespace> --wait`, then re-run the plan. It's a one-time step per subscription. `resource_providers_to_register` in `envs/dev/providers.tf` is supposed to handle this, but it didn't register `Microsoft.Insights` on first use.
- **Function host errors ("Server failed to authenticate the request", "error performing a read operation on the Blob Storage Secret Repository", or the deploy failing with "Failed to fetch host key"):** azurerm (5.6.0 and earlier) adds an `AzureWebJobsStorage` connection string with an empty account key to Flex Consumption apps, even with identity-based storage ([issue #33211](https://github.com/hashicorp/terraform-provider-azurerm/issues/33211)). The host prefers it over the `AzureWebJobsStorage__*` identity settings. Delete it with `az functionapp config appsettings delete -g <rg> -n <func> --setting-names AzureWebJobsStorage`. `terraform plan` won't show it, but the provider adds it back every time it updates the function app, so repeat the delete after any apply that changes the app.
- **`ManagedEnvironmentCapacityHeavyUsageError` / `AKSCapacityHeavyUsage` creating the Container Apps environment:** the region has no capacity for new environments, which run on AKS behind the scenes. It persisted in centralus for days. Set `container_apps_location` to another region. If the failed environment still exists (status **Failed**, not in Terraform state), delete it first: `az containerapp env delete -g <rg> -n <cae-name> --yes`.
- **Name already taken:** the random suffix makes this unlikely. Change `prefix` in `terraform.tfvars`.
