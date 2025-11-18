const { Timestamp } = require('firebase-admin/firestore');
const db = require('../config/database')
const processStatisticsService = require('./processStatisticsService'); // Import the service to process statistics

class ImportedStatsService {
    //a script for computing statistics of imported baby journal entries

    static async computeStatisticsForImportedEntries(babyId) {
        const babyRef = db.collection("babies").doc(babyId);

        if (!babyRef) {
            throw new Error('Baby not found');
        }
        // console.log(`Computing statistics for imported entries of baby ID: ${babyId}`);
        // Fetch all journal entries for the baby, sorted by awakeTime
        const journalEntriesSnapshot = await babyRef.collection('journalEntries')
            .orderBy('awakeTime', 'asc') //sorted by awakeTime
            .get();

        //1st entry and last entry dates
        // const firstEntryDoc = journalEntriesSnapshot.docs[0];
        // const lastEntryDoc = journalEntriesSnapshot.docs[journalEntriesSnapshot.docs.length - 1];
        // console.log(`First entry date: ${firstEntryDoc.data().awakeTime.toDate()}`);
        // console.log(`Last entry date: ${lastEntryDoc.data().awakeTime.toDate()}`);
        // console.log(`Total entries to process: ${journalEntriesSnapshot.size}`);

        // convert snapshot to array of entries
        const journalEntries = journalEntriesSnapshot.docs.map(doc => {
            return { id: doc.id, ...doc.data() };
        });

        //can combine jan - june entries together, 
        //awakeTime, startFeedTime, startPlayTime, startSleepTime needs to be converted to June. day and year kept the same
        //combine september - december entries together
        //awakeTime, startFeedTime, startPlayTime, startSleepTime needs to be converted to September. day and year kept the same
        // journalEntries.forEach(entry => {
        //     const date = entry.awakeTime.toDate();
        //     const month = date.getMonth() + 1;
        //     if (month >= 1 && month <= 6) {
        //         date.setMonth(5); // June
        //     } else if (month >= 9 && month <= 12) {
        //         date.setMonth(8); // September
        //     }
        //     entry.awakeTime = Timestamp.fromDate(date);
        //     if (entry.startFeedTime) {
        //         const feedDate = entry.startFeedTime.toDate();
        //         if (month >= 1 && month <= 6) {
        //             feedDate.setMonth(5);
        //         } else if (month >= 9 && month <= 12) {
        //             feedDate.setMonth(8);
        //         }
        //         entry.startFeedTime = Timestamp.fromDate(feedDate);
        //     }
        //     if (entry.startPlayTime) {
        //         const playDate = entry.startPlayTime.toDate();
        //         if (month >= 1 && month <= 6) {
        //             playDate.setMonth(5);
        //         } else if (month >= 9 && month <= 12) {
        //             playDate.setMonth(8);
        //         }
        //         entry.startPlayTime = Timestamp.fromDate(playDate);
        //     }
        //     if (entry.startSleepTime) {
        //         const sleepDate = entry.startSleepTime.toDate();
        //         if (month >= 1 && month <= 6) {
        //             sleepDate.setMonth(5);
        //         } else if (month >= 9 && month <= 12) {
        //             sleepDate.setMonth(8);
        //         }
        //         entry.startSleepTime = Timestamp.fromDate(sleepDate);
        //     }
        // });
        // console.log('Adjusted journal entries for statistics computation.');
        console.log(`Total entries to process: ${journalEntries.length}`);

        //map entries per month for analysis
        let monthlyStats = this.mapEntriesPerMonth(journalEntries);
        console.log('Entries per month mapping:', monthlyStats);

        //need to group entries by day, then compute daily statistics for each day
        journalEntries.sort((a, b) => a.awakeTime.toDate() - b.awakeTime.toDate());
        const dailyEntriesMap = {};

        //group entries by day
        journalEntries.forEach(entry => {
            const date = entry.awakeTime.toDate();
            const dayKey = date.toISOString().split('T')[0]; // YYYY-MM-DD
            if (!dailyEntriesMap[dayKey]) {
                dailyEntriesMap[dayKey] = [];
            }
            dailyEntriesMap[dayKey].push(entry);
        });

        console.log('Grouped journal entries by day for statistics computation.');
        console.log(`Total days to process: ${Object.keys(dailyEntriesMap).length}`);
    
        // Compute daily statistics for each day
        // const dailyStatistics = {};
        // for (const [day, entries] of Object.entries(dailyEntriesMap)) {
        //     const stats = processStatisticsService.calculateDailyStatistics(entries);
        //     dailyStatistics[day] = stats;
        // }

        // // Store computed daily statistics back to Firestore
        // const statsCollectionRef = babyRef.collection('importedDailyStatistics');
        // const batch = db.batch();
        // for (const [day, stats] of Object.entries(dailyStatistics)) {
        //     const statsDocRef = statsCollectionRef.doc(day);
        //     batch.set(statsDocRef, stats);
        // }
        // await batch.commit();
        // console.log('Stored computed daily statistics in Firestore.');

        return { message: 'Successfully computed and stored statistics for imported entries.'};
        return { message: 'Successfully computed and stored statistics for imported entries.', data: dailyStatistics};
    }


    //help functions 
    //map months to the number of entries in that month
    static mapEntriesPerMonth(journalEntries) {
        const monthEntryCount = {};
        journalEntries.forEach(entry => {
            const month = entry.awakeTime.toDate().getMonth() + 1; // Months are 0-indexed
            const year = entry.awakeTime.toDate().getFullYear();
            const monthKey = `${year}-${month < 10 ? '0' + month : month}`;
            if (!monthEntryCount[monthKey]) {
                monthEntryCount[monthKey] = 0;
            }
            monthEntryCount[monthKey]++;
        });
        return monthEntryCount;
    }

}

module.exports = ImportedStatsService;