const db = require('../config/database')
const { Timestamp } = require('firebase-admin/firestore');
const DailyStatistics = require('../models/dailyStatistics');

class StatisticsService {
    async getDailyStatistics(babyId) {
        const babyRef = db.collection("babies").doc(babyId);
        const statsSnap = await db.collection("dailyStatistics")
            .where("babyIDRef", "==", babyRef)
            .get();

        const statistics = statsSnap.docs.map(doc => doc.data());
        //sort by date ascending
        statistics.sort((a, b) => (a.date > b.date) ? 1 : -1);
        return statistics;
    }

    async getDailyStatisticsById(statisticId) {
        const statDoc = await db.collection("dailyStatistics").doc(statisticId).get();
        if (!statDoc.exists) {
            throw new Error('Statistic not found');
        }
        return statDoc.data();
    }

    async processDailyStatistics() {
        console.log("Processing daily statistics for all babies...");

        //retrieve all active babies
        const babiesSnap = await db.collection("babies").where("deletedAt", "==", null).get();
        if (babiesSnap.empty) {
            console.log("No active babies found.");
            return;
        }

        //filter entries for yesterday
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);

        const startOfDay = new Date(yesterday);
        startOfDay.setHours(0, 0, 0, 0);

        const endOfDay = new Date(yesterday);
        endOfDay.setHours(23, 59, 59, 999);

        // Process all babies sequentially
        for (const babyDoc of babiesSnap.docs) {
            const babyId = babyDoc.id;
            const babyRef = db.collection("babies").doc(babyId);


            // Query journal entries for that baby from yesterday
            const entriesSnap = await babyRef.collection("journalEntries")
                .where("awakeTime", ">=", startOfDay)
                .where("awakeTime", "<=", endOfDay)
                .orderBy("awakeTime", "asc")
                .get();

            const entries = entriesSnap.docs.map(doc => doc.data()); //array of journal entries
            if (entries.length === 0) {
                console.log(`No journal entries found for baby ${babyId} on ${yesterday.toISOString().split('T')[0]}.`);
                continue;
            }

            // Calculate statistics
            let result = this.calculateDailyStatistics(entries);
            //add date
            result.date = yesterday.toISOString().split('T')[0];
            //add created AT timestamp (now)
            result.createdAt = Timestamp.now();
            result.babyIDRef = babyRef;
            //add day
            const dailyStatsSnap = await db.collection("dailyStatistics").where("babyIDRef", "==", babyRef).get();
            
            result.day = dailyStatsSnap.size + 1; //increment day count
            
            //if result.day % 7 === 0 then create weekly stats
            // if (result.day % 7 === 0) {
                // const weeklyStats = this.calculateWeeklyStatistics(entries);
                // weeklyStats.date = yesterday.toISOString().split('T')[0];
                // weeklyStats.createdAt = Timestamp.now();
                // weeklyStats.babyIDRef = babyRef;
                // await babyRef.collection("weeklyStatistics").add(weeklyStats);
                // console.log(`Weekly statistics saved for baby ${babyId} on ${weeklyStats.date}.`);
            // }

            // Save to Firestore
            await db.collection("dailyStatistics").add(result);
            console.log(`Daily statistics saved for baby ${babyId} on ${result.date}.`);
        }

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
            if (entry.startPlayTime !== null) {
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
}

module.exports = new StatisticsService();
