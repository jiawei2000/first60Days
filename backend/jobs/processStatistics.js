// batchJobs.js
const cron = require('node-cron');
const ProcessStatisticsService = require("../services/processStatisticsService");


//Daily journal entries check (run every midnight)
//run every midnight ("0 0 * * *")
//run every min ("* * * * *")
cron.schedule('* * * * *', async () => {
    console.log("Running daily checks job...");

    try {
      //probably can do daily statistics here too
        await ProcessStatisticsService.processDailyStatistics();
        console.log("Daily statistics processing job completed.");
        // //pause for a bit to avoid overload
        // await new Promise(resolve => setTimeout(resolve, 2000));

        // await ProcessStatisticsService.processStatisticsByGender();
        // console.log("Gender statistics processing job completed.");
        // await new Promise(resolve => setTimeout(resolve, 2000));
        
        // await ProcessStatisticsService.processStatisticsByAgeGroup();
        // console.log("Age group statistics processing job completed.");
    
        
    } catch (error) {
        console.error("Error in batch job:", error);
    }
});


