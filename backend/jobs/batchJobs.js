// batchJobs.js
const cron = require('node-cron');
const ProcessStatisticsService = require("../services/processStatisticsService");


//Daily journal entries check (run every midnight)
//run every midnight ("0 0 * * *")
//run every min ("* * * * *")
cron.schedule('* * * * *', async () => {
    console.log("Running daily checks job...");

    try {
        // await CheckService.processDailyChecks();

        //probably can do daily statistics here too
        await ProcessStatisticsService.processDailyStatistics();
        console.log("Daily statistics processing job completed.");

        //
        
    } catch (error) {
        console.error("Error in batch job:", error);
    }
});


