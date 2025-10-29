// batchJobs.js
const cron = require('node-cron');
const StatisticsService = require("../services/statisticsService");

//Daily journal entries check (run every midnight)
//run every midnight ("0 0 * * *")
//run every min ("* * * * *")
cron.schedule('* * * * *', async () => {
    console.log("Running daily checks job...");

    try {
        // await CheckService.processDailyChecks();

        //probably can do daily statistics here too
        await StatisticsService.processDailyStatistics();
        console.log("Daily checks job completed.");
        
    } catch (error) {
        console.error("Error in daily checks job:", error);
    }
});


