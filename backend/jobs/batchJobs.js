// batchJobs.js
const cron = require('node-cron');
const CheckService = require("../services/checkService");

//Daily journal entries check (run every midnight)
//run every midnight ("0 0 * * *")
//run every min ("* * * * *")
cron.schedule('* * * * *', async () => {
    console.log("Running daily checks job...");

    try {
        await CheckService.processDailyChecks();
    } catch (error) {
        console.error("Error in daily checks job:", error);
    }
});