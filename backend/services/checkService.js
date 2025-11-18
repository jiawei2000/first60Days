const db = require('../config/database');
const Check = require('../models/Check');
const { Timestamp } = require('firebase-admin/firestore');

const BabyService = require("./babyService");
const NotificationService = require("./notificationService");

class CheckService {
    static async processDailyChecks() {
        try {
            // Get yesterday’s date
            const yesterday = new Date();
            yesterday.setDate(yesterday.getDate() - 1);
            // yesterday.setDate(yesterday.getDate());

            const startOfDay = new Date(yesterday);
            startOfDay.setHours(0, 0, 0, 0);

            const endOfDay = new Date(yesterday);
            endOfDay.setHours(23, 59, 59, 999);

            // Get all babies
            const babiesSnap = await db.collection("babies").get();

            if (babiesSnap.empty) {
                console.log("No babies found.");
                return;
            }

            // Process all babies concurrently
            const results = await Promise.allSettled(
                babiesSnap.docs.map(async (babyDoc) => {
                    const babyId = babyDoc.id;

                    // Query journal entries for that baby from yesterday
                    const entriesSnap = await db
                        .collection("babies")
                        .doc(babyId)
                        .collection("journalEntries")
                        .where("awakeTime", ">=", startOfDay)
                        .where("awakeTime", "<=", endOfDay)
                        .get();

                    if (entriesSnap.empty) {
                        console.log(`No entries found for baby ${babyId}`);
                        return;
                    }

                    // Collect entries
                    const entries = entriesSnap.docs.map((doc) => ({
                        id: doc.id,
                        ...doc.data(),
                    }));

                    // Use Check class to process
                    const check = new Check(babyId, entries);
                    const stats = check.calculateStats(); // e.g., { entryCount, urineCount, stoolCount, intervalCount }

                    // Save results into "dailyChecks" subcollection
                    const dailyCheckRef = db
                        .collection("babies")
                        .doc(babyId)
                        .collection("dailyChecks")
                        .doc(); // auto ID

                    await dailyCheckRef.set({
                        ...stats,
                        date: startOfDay,
                        createdAt: Timestamp.now(),
                    });

                    // Fetch parent user ID
                    const parentId = await BabyService.getParentId(babyId);
                    const babyName = babyDoc.data().name;

                    //notification warnings 
                    if (stats.urineCount < 5) {
                        //Urine count less than 5
                        NotificationService.sendToUserId(
                            parentId,
                            "Low Urine Output",
                            `Baby ${babyName} might be dehydrated as they had only ${stats.urineCount} urine output yesterday. Consider increasing fluid intake.`,
                        );
                    }

                    if (stats.stoolCount == 0) {
                        //if no stool count, check pass 7 days records
                        //if no stools for the pass 3 days, increase fluid intake 
                        //in no stools for the pass 7 days, see doctor 
                        //retrieve daily statistics for past 7 days 
                        // -1 (yesterday) -2 (2 days ago) -3 (3 days ago) -4 (4 days ago) -5 (5 days ago) -6 (6 days ago) -7 (7 days ago)
                        const babyRef = db.collection("babies").doc(babyId);
                        const dailyStatisticsRef = db.collection("dailyStatistics");
                        //filter daily statistics for that baby for the past 7 days

                        //based on the pass 7 days, check if stool count is 0
                        let dateOf7daysAgo = new Date();
                        dateOf7daysAgo.setDate(yesterday.getDate() - 7);
                        dateOf7daysAgo.setHours(0, 0, 0, 0);
                        const dailyStatisticsSnap = await dailyStatisticsRef
                            .where("babyRef", "==", babyRef)
                            .get();

                        //filter the statistics to only include those within the last 7 days
                        //stats.date: "2025-11-08" is a string in the format YYYY-MM-DD
                        const past7DaysStats = dailyStatisticsSnap.docs
                            .map(doc => doc.data())
                            .filter(stat => {
                                const statDate = new Date(stat.date);
                                return statDate >= dateOf7daysAgo && statDate < startOfDay;
                            });

                        //sort by date descending - most recent first
                        past7DaysStats.sort((a, b) => new Date(b.date) - new Date(a.date));

                        //if past7DaysStats length is less than 3, we cannot make a decision
                        if (past7DaysStats.length >= 3) {

                            //if no stools for pass 3 days send warning, if no stool for pass 7 days send doctor warning
                            let noStoolFor3Days = true;
                            let noStoolFor7Days = true;
                            for (let i = 0; i < 7; i++) {
                                if (i < 3) {
                                    if (past7DaysStats[i] && past7DaysStats[i].stoolCount > 0) { //if any stool found in past 3 days, set to false
                                        noStoolFor3Days = false;
                                    }
                                }
                                if (past7DaysStats[i] && past7DaysStats[i].stoolCount > 0) { //if any stool found in past 7 days, set to false
                                    noStoolFor7Days = false;
                                }
                            }

                            if (noStoolFor3Days) {
                                NotificationService.sendToUserId(
                                    parentId,
                                    "No Stool for 3 Days",
                                    `Baby ${babyName} has not had any stool for the past 3 days. Consider increasing fluid intake.`,
                                );
                            }
                            if (noStoolFor7Days) {
                                NotificationService.sendToUserId(
                                    parentId,
                                    "No Stool for 7 Days",
                                    `Baby ${babyName} has not had any stool for the past 7 days. Please consult a doctor.`,
                                );
                            }
                        }
                    }

                    //number of entry count should technically follow entry planner
                    //from week 1-5 shud minimally have 8 
                    //from week 6-10 shud minimally have 7
                    if (stats.entryCount < 6) {
                        //warning 
                        NotificationService.sendToUserId(
                            parentId,
                            "Missing Journal Entries",
                            `Baby ${babyName} is missing journal entries. Please ensure all entries are logged.`,
                        );
                    }

                    if (stats.interval.count > 0) {
                        //an array of journal entries Id that have less than 2.5hrs 
                        let entryCount = stats.interval.count;
                        NotificationService.sendToUserId(
                            parentId,
                            "Frequent Feeding Intervals",
                            `Baby ${babyName} had ${entryCount} feeding intervals of less than 2.5 hours yesterday. Monitor feeding patterns closely.`,
                        );
                    }

                    //warning storage 

                    console.log(`Processed daily check for baby ${babyId}`);
                })
            );

            // Report how many succeeded/failed
            const succeeded = results.filter((r) => r.status === "fulfilled").length;
            const failed = results.filter((r) => r.status === "rejected").length;
            console.log(`Daily checks complete. ${succeeded} succeeded, ${failed} failed.`);

        } catch (error) {
            console.error("Error in processDailyChecks:", error);
        }
    }
}

module.exports = CheckService;
