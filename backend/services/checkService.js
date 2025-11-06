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
                    if (stats.urineCount < 5){
                        //Urine count less than 5
                        NotificationService.sendToUserId(
                            parentId, 
                            "Low Urine Output",
                            `Baby ${babyName} might be dehydrated as they had only ${stats.urineCount} urine output yesterday. Consider increasing fluid intake.`,
                        );
                    }

                    if (stats.stoolCount == 0){
                        //if no stool count, check pass 7 days records
                        
                        //if no stools for the pass 3 days, increase fluid intake 
                        
                        //in no stools for the pass 7 days, see doctor 
                        
                    }

                    //number of entry count should technically follow entry planner
                    //from week 1-5 shud minimally have 8 
                    //from week 6-10 shud minimally have 7
                    if (stats.entryCount < 6){
                        //warning 
                        NotificationService.sendToUserId(
                            parentId, 
                            "Missing Journal Entries",
                            `Baby ${babyName} is missing journal entries. Please ensure all entries are logged.`,
                        );
                    }

                    if (stats.interval.count > 0){
                        //an array of journal entries Id that have less than 2.5hrs 
                        let entries = stats.interval.cycleNo
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
