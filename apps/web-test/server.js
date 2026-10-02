// Minimal smoke-test app for the azplat web app.
//   /     shows the GREETING app setting (a Key Vault reference resolved by App Service)
//   /sql  signs in to Azure SQL as the managed identity and reports SQL's exact reply
const http = require('node:http');
const sql = require('mssql');

const port = process.env.PORT || 8080;

async function trySql() {
  const config = {
    server: process.env.SQL_SERVER,
    database: process.env.SQL_DATABASE,
    authentication: {
      // Token from the App Service managed identity endpoint; AZURE_CLIENT_ID
      // picks the user-assigned identity (Client ID = "sign in as this one").
      type: 'azure-active-directory-msi-app-service',
      options: { clientId: process.env.AZURE_CLIENT_ID },
    },
    options: { encrypt: true },
    connectionTimeout: 20000,
  };

  try {
    const pool = await new sql.ConnectionPool(config).connect();
    // client_net_address is the source IP SQL sees: 10.20.1.x means the
    // traffic came through snet-app's service endpoint.
    const result = await pool.request().query(
      "SELECT SUSER_SNAME() AS login, CONVERT(varchar(48), CONNECTIONPROPERTY('client_net_address')) AS clientAddress"
    );
    await pool.close();
    return { connected: true, ...result.recordset[0] };
  } catch (err) {
    return {
      connected: false,
      code: err.code,
      sqlErrorNumber: err.originalError?.info?.number ?? err.number,
      message: err.originalError?.message ?? err.message,
    };
  }
}

const server = http.createServer(async (req, res) => {
  if (req.url === '/sql') {
    const body = await trySql();
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(body, null, 2));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    greeting: process.env.GREETING ?? '(GREETING not set)',
    node: process.version,
    sqlServer: process.env.SQL_SERVER,
  }, null, 2));
});

server.listen(port, () => console.log(`web-test listening on ${port}`));
