const db = require('../config/database');
const Check = require('../models/Check');
const { Timestamp } = require('firebase-admin/firestore');

class CheckService {
    static async processDailyChecks() {
        try {
            // Get yesterday’s date
            const yesterday = new Date();
            yesterday.setDate(yesterday.getDate() - 1);

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
                        .where("createdAt", ">=", startOfDay)
                        .where("createdAt", "<=", endOfDay)
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
