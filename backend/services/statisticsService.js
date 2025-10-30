const db = require('../config/database')
const { Timestamp } = require('firebase-admin/firestore');
const DailyStatistics = require('../models/dailyStatistics');

class StatisticsService {
    async getWeeklyStatistics(babyId) {
        const babyRef = db.collection("babies").doc(babyId);
        const statsSnap = await db.collection("weeklyStatistics")
            .where("babyIDRef", "==", babyRef)
            .get();
        const statistics = statsSnap.docs.map(doc => doc.data());
        //sort by startDate ascending
        statistics.sort((a, b) => (a.startDate > b.startDate) ? 1 : -1);
        return statistics;
    }

    async getWeeklyStatisticsById(statisticId) {
        const statDoc = await db.collection("weeklyStatistics").doc(statisticId).get();
        if (!statDoc.exists) {
            throw new Error('Statistic not found');
        }
        return statDoc.data();
    }
    
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
            //unsorted count of existing daily statistics for that baby
            const dailyStatsSnap = await db.collection("dailyStatistics").where("babyIDRef", "==", babyRef).get();
            //add day
            result.day = dailyStatsSnap.size + 1; //increment day count

            // Save to Firestore

            //if day is multiple of 7, calculate and save weekly statistics
            if (result.day % 7 === 0) {
                console.log(`Calculating weekly statistics for baby ${babyId} for week ${result.day / 7}.`);
                const dailyStatsEntries = dailyStatsSnap.docs.map(doc => doc.data());

                //sort daily stats by day ascending. From day 1 to day n
                dailyStatsEntries.sort((a, b) => (a.day > b.day) ? 1 : -1);

                //retrieve last 6 days + current day (7 days)
                let last7DaysStats = dailyStatsEntries.slice(-6);
                last7DaysStats.push(result); //add current day stats
                console.log(`Last 7 days statistics for baby ${babyId}:`, last7DaysStats);
                // break;
                const weeklyStats = this.calculateWeeklyStatistics(last7DaysStats);

                //misc 
                weeklyStats.week = result.day / 7;
                weeklyStats.createdAt = Timestamp.now();
                weeklyStats.babyIDRef = babyRef;

                await db.collection("weeklyStatistics").add(weeklyStats);
                console.log(`Weekly statistics saved for baby ${babyId} on ${(weeklyStats.createdAt).toDate()}.`);
            }
            // break;
            await db.collection("dailyStatistics").add(result);
            console.log(`Daily statistics saved for baby ${babyId} on ${result.date}.`);
        }

    }
    calculateWeeklyStatistics(last7DaysStats) {
        const statistics = {
            //summed fields 
            totalFeeds: 0,
            totalUrineCount: 0,
            totalStoolCount: 0,
            totalSleepDuration: 0, // in hh:mm 
            totalPlayDuration: 0, // in hh:mm
            totalCyclesBeyond3Hrs: 0,

            //averaged fields
            averageMonInterval: 0, // in hh:mm | monInterval per day  //sum every day and divide by 7
            averageMilkIntake: 0, // in ml | Milk amound per bottle per day 
            averagePlayDuration: 0, // in hh:mm | play duration per entry per day 
            averageLapseDuration: 0, // in hh:mm | Lapse duration per entry per day 

            //startDate, endDates
            startDate: last7DaysStats[0].date,
            endDate: last7DaysStats[last7DaysStats.length - 1].date,
        }
        //loop through each stats in the last 7 days
        // Loop through each day's statistics
        last7DaysStats.forEach(dayStat => {
            statistics.totalFeeds += dayStat.totalFeeds;
            statistics.totalUrineCount += dayStat.totalUrineCount;
            statistics.totalStoolCount += dayStat.totalStoolCount;
            statistics.totalCyclesBeyond3Hrs += dayStat.totalCyclesBeyond3Hrs;
            statistics.totalPlayDuration += this.toFloatHours(dayStat.totalPlayDuration);
            statistics.totalSleepDuration += this.toFloatHours(dayStat.totalSleepDuration);

            statistics.averageMonInterval += this.toFloatHours(dayStat.monInterval);
            statistics.averageMilkIntake += dayStat.averageMilkIntake;
            statistics.averagePlayDuration += this.toFloatHours(dayStat.averagePlayDuration);
            statistics.averageLapseDuration += this.toFloatHours(dayStat.averageLapseDuration);
        });
        // Calculate averages over 7 days
        statistics.averageMonInterval = this.toHHMM(statistics.averageMonInterval / 7);
        statistics.averageMilkIntake = statistics.averageMilkIntake / 7;
        statistics.averagePlayDuration = this.toHHMM(statistics.averagePlayDuration / 7);
        statistics.averageLapseDuration = this.toHHMM(statistics.averageLapseDuration / 7);

        // Convert total durations back to hh:mm format
        statistics.totalPlayDuration = this.toHHMM(statistics.totalPlayDuration);
        statistics.totalSleepDuration = this.toHHMM(statistics.totalSleepDuration);

        return statistics;
    }


    // Helper method to calculate daily statistics
    calculateDailyStatistics(entries) {
        const statistics = {
            //summed fields 
            totalFeeds: entries.length,
            totalUrineCount: 0,
            totalStoolCount: 0,
            totalCyclesBeyond3Hrs: 0,
            totalSleepDuration: 0, // in hh:mm 
            totalPlayDuration: 0, // in hh:mm
            monInterval: 0, // in hh:mm

            //averaged fields
            averagePlayDuration: 0, // in hh:mm average play duration per entry
            averageLapseDuration: 0, // in hh:mm average lapse duration per entry
            averageMilkIntake: 0, // in ml average milk amount per bottle feed
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
        let totalMilkFeed = 0;
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
                totalMilkFeed += 1;
            }
        });

        statistics.averagePlayDuration = this.toHHMM(statistics.totalPlayDuration / entries.length || 0);
        statistics.totalPlayDuration = this.toHHMM(statistics.totalPlayDuration);
        statistics.averageLapseDuration = this.toHHMM(totalLapseDuration / entries.length || 0);
        statistics.totalSleepDuration = this.toHHMM(statistics.totalSleepDuration);
        statistics.averageMilkIntake = totalMilkAmount / totalMilkFeed || 0;

        return statistics;
    }

    //helper method to convert float hours to hh:mm format
    toHHMM(hoursFloat) {
        const hours = Math.floor(hoursFloat);
        const minutes = Math.round((hoursFloat - hours) * 60);
        // pad with zeros (e.g. "03:05")
        return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
    }

    //helper method to convert hh:mm format to float hours
    toFloatHours(hhmm) {
        const [hours, minutes] = hhmm.split(':').map(Number);
        return hours + (minutes / 60);
    }
}

module.exports = new StatisticsService();
