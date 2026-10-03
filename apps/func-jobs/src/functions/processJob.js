// Runs once per message in the storage queue 'jobs'. The Functions host does
// the polling, and deletes the message when this handler returns without
// throwing. After maxDequeueCount failures (host.json) it moves the message
// to 'jobs-poison'.
const { app } = require('@azure/functions');

app.storageQueue('processJob', {
  queueName: 'jobs',
  // App settings prefixed "JobsStorage__" tell the host which account to use
  // and to sign in with the managed identity (no connection string).
  connection: 'JobsStorage',
  handler: async (message, context) => {
    const { id, dequeueCount, insertionTime } = context.triggerMetadata;
    context.log(`processJob: message ${id}, attempt ${dequeueCount}, queued at ${insertionTime}`);
    context.log('processJob: payload', message);

    // JSON messages arrive already parsed. {"fail": true} simulates a bad job
    // so the retry -> poison-queue path can be seen.
    if (message && typeof message === 'object' && message.fail) {
      throw new Error(`processJob: simulated failure for message ${id}`);
    }

    context.log(`processJob: message ${id} done`);
  },
});
