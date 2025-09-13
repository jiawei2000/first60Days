// batchJobs.js
const cron = require('node-cron');
const CheckService = require("../services/checkService");

// Example 1: Cleanup old journal entries (run every midnight)
cron.schedule('0 0 * * *', async () => {
    console.log("Running daily checks job...");

    try {
        await CheckService.processDailyChecks();
    } catch (error) {
        console.error("Error in daily checks job:", error);
    }
});


