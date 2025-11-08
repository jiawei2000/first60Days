const e = require('express');
const db = require('../config/database');
const { Timestamp } = require('firebase-admin/firestore');

class ProcessStatisticsService {
    // Entry point
    async processDailyStatistics() {
        console.log("Processing daily statistics for all babies...");

        // Retrieve all active babies
        const babiesSnap = await db.collection("babies")
            .where("deletedAt", "==", null)
            .get();

        if (babiesSnap.empty) {
            console.log("No active babies found.");
            return;
        }

        // Get yesterday’s start and end timestamps
        // const yesterday = new Date();
        // yesterday.setUTCDate(yesterday.getUTCDate() - 1);
        // const startOfDay = new Date(Date.UTC(yesterday.getUTCFullYear(), yesterday.getUTCMonth(), yesterday.getUTCDate(), 0, 0, 0, 0));
        // const endOfDay = new Date(Date.UTC(yesterday.getUTCFullYear(), yesterday.getUTCMonth(), yesterday.getUTCDate(), 23, 59, 59, 999));

        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        // yesterday.setDate(yesterday.getDate());

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
            // console.log(`Query matched ${entriesSnap.size} documents.`);
            //filter for status == "COMPLETE"
            const entries = entriesSnap.docs.map(doc => doc.data()).filter(entry => entry.status === "COMPLETE");
            console.log(`total entries: ${entries.length} for baby ${babyId} on ${yesterday.toISOString().split('T')[0]}.`);
            
            // Calculate daily statistics
            const result = this.calculateDailyStatistics(entries);
            result.date = yesterday.toISOString().split('T')[0];
            result.createdAt = Timestamp.now();
            result.babyIDRef = babyRef;

            // Retrieve existing daily stats for this baby
            const dailyStatsSnap = await db.collection("dailyStatistics")
                .where("babyIDRef", "==", babyRef)
                .get();

            // Assign day index
            result.day = dailyStatsSnap.size + 1;

            // Weekly aggregation every 7 days
            if (result.day % 7 === 0) {
                console.log(`Calculating weekly statistics for baby ${babyId} for week ${result.day / 7}.`);

                // Sort daily stats by ascending day
                const dailyStatsEntries = dailyStatsSnap.docs.map(doc => doc.data());
                dailyStatsEntries.sort((a, b) => (a.day > b.day ? 1 : -1));

                // Retrieve last 6 days + current day
                const last7DaysStats = [...dailyStatsEntries.slice(-6), result];
                console.log(`Last 7 days statistics for baby ${babyId}:`, last7DaysStats);

                // Calculate weekly statistics
                const weeklyStats = this.calculateWeeklyStatistics(last7DaysStats);
                weeklyStats.week = result.day / 7;
                weeklyStats.createdAt = Timestamp.now();
                weeklyStats.babyIDRef = babyRef;

                await db.collection("weeklyStatistics").add(weeklyStats);
                console.log(`Weekly statistics saved for baby ${babyId} on ${weeklyStats.createdAt.toDate()}.`);
            }

            // Save daily statistics
            await db.collection("dailyStatistics").add(result);
            console.log(`Daily statistics saved for baby ${babyId} on ${result.date}.`);
        }
    }
    async processStatisticsByGender() {
        //regardless of age or gender, a will have a daily statistic entry as long as there is a journal entries for that day
        //filter dailyStatistics by date = yesterday
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const dateStr = yesterday.toISOString().split('T')[0];

        //get all dailyStatistics for that date
        const statsSnap = await db.collection("dailyStatistics")
            .where("date", "==", dateStr)
            .get();

        if (statsSnap.empty) {
            console.log(`No daily statistics found for date ${dateStr}.`);
            return;
        }

        //filter by gender
        const dailyStatsEntries = statsSnap.docs.map(doc => doc.data());
        let maleBabyStats = [];
        let femaleBabyStats = [];
        // Promise.all() ensures all async .get() calls finish before moving on to the logs.
        await Promise.all(
            dailyStatsEntries.map(async (entry) => {
                const babyRef = entry.babyIDRef;
                const babyDoc = await babyRef.get();
                const babyData = babyDoc.data();

                if (babyData.gender === 'Male') {
                    maleBabyStats.push(entry);
                } else {
                    femaleBabyStats.push(entry);
                }
            })
        );
        console.log(`Male daily entries: ${maleBabyStats.length}`); //check if there is any male daily entries
        console.log(`Female daily entries: ${femaleBabyStats.length}`); //check if there is any female daily entries

        const maleStatistics = this.calculateConsolidatedStatistics(maleBabyStats);
        const femaleStatistics = this.calculateConsolidatedStatistics(femaleBabyStats);

        let result = {
            maleStatistics: maleStatistics,
            femaleStatistics: femaleStatistics,
            createdAt: Timestamp.now(),
            date: dateStr
        };
        await db.collection("statisticsByGender").add(result);
        console.log(`Statistics by gender saved for date ${dateStr}.`);
    }

    async processStatisticsByAgeGroup() {
        //need sort babies by week 1 - 10
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const dateStr = yesterday.toISOString().split('T')[0];

        //get all dailyStatistics for that date
        const statsSnap = await db.collection("dailyStatistics")
            .where("date", "==", dateStr)
            .get();

        if (statsSnap.empty) {
            console.log(`No daily statistics found for date ${dateStr}.`);
            return;
        }

        const dailyStatsEntries = statsSnap.docs.map(doc => doc.data());

        let ageGroupStats = {
            1: [],
            2: [],
            3: [],
            4: [],
            5: [],
            6: [],
            7: [],
            8: [],
            9: [],
            10: []
        };

        dailyStatsEntries.forEach(async entry => {
            //assuming parents do entries daily, entry.day = baby age
            const ageWeek = Math.ceil(entry.day / 7); //convert day to week
            if (ageWeek >= 1 && ageWeek <= 10) {
                ageGroupStats[ageWeek].push(entry);
            }
        })

        //calculate consolidated statistics for each age group
        let result = {
            createdAt: Timestamp.now(),
            date: dateStr,
            ageGroupStatistics: {}
        };
        for (let week = 1; week <= 10; week++) {
            const stats = this.calculateConsolidatedStatistics(ageGroupStats[week]);
            result.ageGroupStatistics[`week${week}`] = stats;
        }
        await db.collection("ageGroupStatistics").add(result);
        console.log(`Age group statistics saved for date ${dateStr}.`);
    }




    // ---------------------------------------------------------------------------
    // Weekly statistics computation
    calculateWeeklyStatistics(last7DaysStats) {
        const statistics = {
            // Summed fields
            totalFeeds: 0,
            totalUrineCount: 0,
            totalStoolCount: 0,
            totalSleepDuration: 0,
            totalPlayDuration: 0,
            totalCyclesBeyond3Hrs: 0,

            // Averaged fields
            averageMonInterval: 0,
            averageMilkIntake: 0,
            averagePlayDuration: 0,
            averageLapseDuration: 0,

            // Metadata
            startDate: last7DaysStats[0].date,
            endDate: last7DaysStats[last7DaysStats.length - 1].date,
        };

        // Aggregate totals and averages
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

        // Compute 7-day averages
        statistics.averageMonInterval = this.toHHMM(statistics.averageMonInterval / 7);
        statistics.averageMilkIntake = this.roundTo(statistics.averageMilkIntake / 7);
        statistics.averagePlayDuration = this.toHHMM(statistics.averagePlayDuration / 7);
        statistics.averageLapseDuration = this.toHHMM(statistics.averageLapseDuration / 7);

        // Convert totals back to hh:mm
        statistics.totalPlayDuration = this.toHHMM(statistics.totalPlayDuration);
        statistics.totalSleepDuration = this.toHHMM(statistics.totalSleepDuration);

        return statistics;
    }

    // ---------------------------------------------------------------------------
    // Daily statistics computation
    calculateDailyStatistics(entries) {
        const statistics = {
            // Summed fields
            totalFeeds: entries.length,
            totalUrineCount: 0,
            totalStoolCount: 0,
            totalCyclesBeyond3Hrs: 0,
            totalSleepDuration: 0, // hh:mm
            totalPlayDuration: 0, // hh:mm
            monInterval: 0, // hh:mm

            // Averaged fields
            averagePlayDuration: 0, // hh:mm
            averageLapseDuration: 0,// hh:mm
            averageMilkIntake: 0,
        };
        console.log(entries);
        // Handle case with no entries
        if (entries.length === 0) {
            statistics.totalSleepDuration = '00:00';
            statistics.totalPlayDuration = '00:00';
            statistics.averagePlayDuration = '00:00';
            statistics.averageLapseDuration = '00:00';
            statistics.monInterval = '00:00';
            return statistics;
        }

        // Interval and MON interval computation
        const MS_PER_HOUR = 1000 * 60 * 60;
        const awakeTimeIndx0 = entries[0].awakeTime.toDate();
        const awakeTimeIndx1 = entries[1].awakeTime.toDate();
        const awakeTimeIndxLast = entries[entries.length - 1].awakeTime.toDate();

        const monInterval1 = (awakeTimeIndx1 - awakeTimeIndx0) / MS_PER_HOUR;
        const monInterval2 = 24 - (awakeTimeIndxLast - awakeTimeIndx0) / MS_PER_HOUR;

        let firstFeedTimeIndex;
        if (monInterval1 > monInterval2) {
            firstFeedTimeIndex = 1;
            statistics.monInterval = this.toHHMM(monInterval1);
        } else {
            firstFeedTimeIndex = 0;
            statistics.monInterval = this.toHHMM(monInterval2);
        }

        // Count cycles beyond 3 hours
        for (let i = firstFeedTimeIndex + 1; i < entries.length; i++) {
            const prevTime = entries[i - 1].awakeTime.toDate();
            const currTime = entries[i].awakeTime.toDate();
            const diffHours = (currTime - prevTime) / MS_PER_HOUR;
            if (diffHours > 3) statistics.totalCyclesBeyond3Hrs += 1;
        }

        // -----------------------------------------------------------------------
        // Process entries for totals and averages
        let totalMilkFeed = 0;
        let totalMilkAmount = 0;
        let totalLapseDuration = 0;

        entries.forEach(entry => {
            if (entry.hasUrine) statistics.totalUrineCount += 1;
            if (entry.hasStool) statistics.totalStoolCount += 1;
            statistics.totalSleepDuration += entry.sleepDuration || 0;

            // Play duration (in hours)
            if (entry.startPlayTime !== null) {
                statistics.totalPlayDuration +=
                    (entry.startSleepTime.toDate() - entry.startPlayTime.toDate()) / MS_PER_HOUR || 0;
            }

            // Lapse duration (in hours)
            totalLapseDuration +=
                (entry.startFeedTime.toDate() - entry.awakeTime.toDate()) / MS_PER_HOUR || 0;

            // Milk intake (ml)
            let entryMilkAmount = 0;
            entry.feedType.forEach(feed => {
                if (feed.unit === 'ml') entryMilkAmount += feed.value;
            });
            if (entryMilkAmount > 0) {
                totalMilkAmount += entryMilkAmount;
                totalMilkFeed += 1;
            }
        });

        // Finalize daily statistics
        statistics.averagePlayDuration = this.toHHMM(statistics.totalPlayDuration / entries.length || 0);
        statistics.totalPlayDuration = this.toHHMM(statistics.totalPlayDuration);
        statistics.averageLapseDuration = this.toHHMM(totalLapseDuration / entries.length || 0);
        statistics.totalSleepDuration = this.toHHMM(statistics.totalSleepDuration);
        statistics.averageMilkIntake = this.roundTo(totalMilkAmount / totalMilkFeed) || 0;

        return statistics;
    }

    calculateConsolidatedStatistics(dailyStatsEntries) {
        //to be implemented later
        const statistics = {
            // averaged fields
            averageTotalFeed: 0, // average feed per baby
            averageTotalUrineCount: 0,
            averageTotalStoolCount: 0,
            averageSleepDuration: 0, // hh:mm
            averagePlayDuration: 0, // hh:mm
            averageMonInterval: 0, // hh:mm
            averageMilkIntake: 0, // ml per bottle feed per baby
            totalBabies: dailyStatsEntries.length
        };
        if (dailyStatsEntries.length === 0) {
            statistics.averageSleepDuration = '00:00';
            statistics.averagePlayDuration = '00:00';
            statistics.averageMonInterval = '00:00';
            return statistics;
        }
        // Aggregate totals and averages
        dailyStatsEntries.forEach(dayStat => {
            statistics.averageTotalFeed += dayStat.totalFeeds;
            statistics.averageTotalUrineCount += dayStat.totalUrineCount;
            statistics.averageTotalStoolCount += dayStat.totalStoolCount;
            statistics.averageSleepDuration += this.toFloatHours(dayStat.totalSleepDuration);
            statistics.averagePlayDuration += this.toFloatHours(dayStat.totalPlayDuration);
            statistics.averageMonInterval += this.toFloatHours(dayStat.monInterval);
            statistics.averageMilkIntake += parseFloat(dayStat.averageMilkIntake);
        });

        const count = dailyStatsEntries.length;

        // Compute averages
        statistics.averageTotalFeed = this.roundTo(statistics.averageTotalFeed / count)
        statistics.averageTotalUrineCount = this.roundTo(statistics.averageTotalUrineCount / count);
        statistics.averageTotalStoolCount = this.roundTo(statistics.averageTotalStoolCount / count);
        statistics.averageSleepDuration = this.toHHMM(statistics.averageSleepDuration / count);
        statistics.averagePlayDuration = this.toHHMM(statistics.averagePlayDuration / count);
        statistics.averageMonInterval = this.toHHMM(statistics.averageMonInterval / count);
        statistics.averageMilkIntake = this.roundTo(statistics.averageMilkIntake / count);
        return statistics;
    }

    // ---------------------------------------------------------------------------
    // Helper: float hours → hh:mm
    toHHMM(hoursFloat) {
        const hours = Math.floor(hoursFloat);
        const minutes = Math.round((hoursFloat - hours) * 60);
        return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
    }

    // Helper: hh:mm → float hours
    toFloatHours(hhmm) {
        const [hours, minutes] = hhmm.split(':').map(Number);
        return hours + minutes / 60;
    }
    roundTo(value, decimals = 2) {
        const factor = Math.pow(10, decimals);
        return Math.round(value * factor) / factor;
    }

}

module.exports = new ProcessStatisticsService();
