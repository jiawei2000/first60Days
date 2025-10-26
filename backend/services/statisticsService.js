const db = require('../config/database')
const { Timestamp } = require('firebase-admin/firestore');
class StatisticsService {
    async getDailyStatistics(babyId, date) {
        // Implement logic to fetch daily statistics for the given babyId and date
        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries");

        //convert string date to date object
        const targetDate = new Date(date);
        const startOfDay = new Date(targetDate);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(targetDate);
        endOfDay.setHours(23, 59, 59, 999);

        // Query journal entries for the specific date
        const snapshot = await journalRef
            .where("awakeTime", ">=", startOfDay)
            .where("awakeTime", "<=", endOfDay)
            .orderBy("awakeTime", "asc")  // "asc" for earliest first, "desc" for latest first
            .get();

        const entries = snapshot.docs.map(doc => doc.data()); //array of journal entries
        if (entries.length === 0) {
            return { message: 'No journal entries found for the specified date.' };
        }
        // Calculate and return statistics based on the journal entries
        let results = this.calculateDailyStatistics(entries);
        
        //add date
        results.date = targetDate.toISOString().split('T')[0]; //format YYYY-MM-DD
        //add created AT timestamp (now)
        results.createdAt = Timestamp.now();

        return results;
    }

    // Helper method to calculate daily statistics
    calculateDailyStatistics(entries) {
        const statistics = {
            //summed fields 
            totalFeeds: entries.length,
            totalUrineCount: 0,
            totalStoolCount: 0,
            totalSleepDuration: 0, // in hh:mm 
            totalPlayDuration: 0, // in hh:mm
            totalCyclesBeyond3Hrs: 0,
            monInterval: 0,

            //averaged fields
            averageMilkIntake: 0, // in ml average milk intake per bottle feed
            averagePlayDuration: 0, // in hh:mm
            averageLapseDuration: 0, // in hh:mm
        };
        //------------------------------------------------------------------------------------------
        // Interval calculation and monInterval
        let firstFeedTimeIndex = null;
        const MS_PER_HOUR = 1000 * 60 * 60;
        let awakeTimeIndx0 = entries[0].awakeTime.toDate();
        let awakeTimeIndx1 = entries[1].awakeTime.toDate();
        let awakeTimeIndxLast = entries[entries.length - 1].awakeTime.toDate();
        let monInterval1 = (awakeTimeIndx1 - awakeTimeIndx0) / MS_PER_HOUR; //difference in hours
        let monInterval2 = 24 - (awakeTimeIndxLast - awakeTimeIndx0) / MS_PER_HOUR; //difference in hours
        if (monInterval1 > monInterval2) {
            firstFeedTimeIndex = 1;
            statistics.monInterval = this.toHHMM(monInterval1); //convert to hh:mm
        }
        else {
            firstFeedTimeIndex = 0;
            statistics.monInterval = this.toHHMM(monInterval2); //convert to hh:mm
        }

        for (let i = firstFeedTimeIndex + 1; i < entries.length; i++) {
            let prevTime = entries[i - 1].awakeTime.toDate();
            let currTime = entries[i].awakeTime.toDate();
            let diffHours = (currTime - prevTime) / MS_PER_HOUR;
            if (diffHours > 3) {
                statistics.totalCyclesBeyond3Hrs += 1;
            }
        }

        //------------------------------------------------------------------------------------------
        // Iterate through entries to compute totals and averages
        // For average calculations
        let totalMilkIntakeCount = 0;
        let totalMilkAmount = 0;
        let totalLapseDuration = 0; //in minutes

        //entry fields: awakeTime, startFeedTime, startPlayTime, startSleepTime , hasUrine, hasStool, sleepDuration, feedType
        //boolean fields: hasUrine, hasStool
        //time stamps : awakeTime, startFeedTime, startPlayTime (nullable), startSleepTime
        //number fields: sleepDuration (in hours), 
        //array fields: feedTypes
        entries.forEach(entry => {
            if (entry.hasUrine) statistics.totalUrineCount += 1;
            if (entry.hasStool) statistics.totalStoolCount += 1;
            statistics.totalSleepDuration += entry.sleepDuration || 0;
            //convert play duration from ms to minutes
            // statistics.totalPlayDuration += (entry.startSleepTime - entry.startPlayTime) / 60000 || 0;
            if (entry.startPlayTime !== null ){
                statistics.totalPlayDuration += (entry.startSleepTime.toDate() - entry.startPlayTime.toDate()) / MS_PER_HOUR || 0;
            }

            totalLapseDuration += (entry.startFeedTime.toDate() - entry.awakeTime.toDate()) / MS_PER_HOUR || 0;

            //milk intake calculation
            let entryMilkAmount = 0;
            entry.feedType.forEach(feed => {
                if (feed.unit === 'ml') {
                    entryMilkAmount += feed.value;
                }
            });
            if (entryMilkAmount > 0) {
                totalMilkAmount += entryMilkAmount;
                totalMilkIntakeCount += 1;
            }
        });

        statistics.averagePlayDuration = this.toHHMM(statistics.totalPlayDuration / entries.length || 0);
        statistics.totalPlayDuration = this.toHHMM(statistics.totalPlayDuration);
        statistics.averageLapseDuration = this.toHHMM(totalLapseDuration / entries.length || 0);
        statistics.totalSleepDuration = this.toHHMM(statistics.totalSleepDuration);
        statistics.averageMilkIntake = totalMilkAmount / totalMilkIntakeCount || 0;

        return statistics;
    }

    //helper method to convert float hours to hh:mm format
    toHHMM(hoursFloat) {
        const hours = Math.floor(hoursFloat);
        const minutes = Math.round((hoursFloat - hours) * 60);
        // pad with zeros (e.g. "03:05")
        return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
    }

    // async getWeeklyStatistics(babyId, startDate, endDate) {
    //     // Implement logic to fetch weekly statistics for the given babyId and date range   
    // }
}

module.exports = new StatisticsService();
