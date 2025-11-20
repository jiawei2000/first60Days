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
        const dailyStatistics = {};
        let dayCounter = 1;
        for (const [day, entries] of Object.entries(dailyEntriesMap)) {
            const stats = processStatisticsService.calculateDailyStatistics(entries);
            stats.day = dayCounter; // add day identifier
            stats.date = day; // add date for reference
            stats.babyIDRef = babyRef; // add baby reference

            dailyStatistics[day] = stats;
            dayCounter++; // increment day counter
        }

        // Store computed daily statistics back to Firestore
        const statsCollectionRef = db.collection('dailyStatistics');
        const batch = db.batch();
        for (const [day, stats] of Object.entries(dailyStatistics)) {
            const statsDocRef = statsCollectionRef.doc(); // Auto-generate ID
            batch.set(statsDocRef, stats);
        }
        await batch.commit();
        console.log('Stored computed daily statistics in Firestore.');

        // return { message: 'Successfully computed and stored statistics for imported entries.'};
        return { message: 'Successfully computed and stored statistics for imported entries.', data: dailyStatistics };
    }

    //a script for computing weekly statistics based on daily statistics
    static async computeWeeklyStatistics(babyId) {
        const babyRef = db.collection("babies").doc(babyId);
        if (!babyRef) {
            throw new Error('Baby not found');
        }

        // Fetch all daily statistics for the baby
        const dailyStatsSnapshot = await db.collection('dailyStatistics')
            .where('babyIDRef', '==', babyRef)
            .get();

        //sorted by date
        dailyStatsSnapshot.docs.sort((a, b) => {
            return new Date(a.data().date) - new Date(b.data().date);
        });

        // Convert snapshot to array of daily statistics
        const dailyStatistics = dailyStatsSnapshot.docs.map(doc => {
            return { id: doc.id, ...doc.data() };
        });
        console.log(`Total daily statistics to process: ${dailyStatistics.length}`);

        // Group daily statistics into weeks (7 days each)
        const weeklyStatistics = {};
        let weekCounter = 1;
        for (let i = 0; i < dailyStatistics.length; i += 7) {
            const weekDays = dailyStatistics.slice(i, i + 7);
            const weekStats = processStatisticsService.calculateWeeklyStatistics(weekDays);
            weekStats.week = weekCounter;
            weekStats.babyIDRef = babyRef; // add baby reference

            weeklyStatistics[`Week ${weekCounter}`] = weekStats;
            weekCounter++;
        }

        // Store computed weekly statistics back to Firestore
        const statsCollectionRef = db.collection('weeklyStatistics');
        const batch = db.batch();
        for (const [week, stats] of Object.entries(weeklyStatistics)) {
            const statsDocRef = statsCollectionRef.doc(); // Auto-generate ID
            batch.set(statsDocRef, stats);
        }
        await batch.commit();
        console.log('Stored computed weekly statistics in Firestore.');
        return { message: 'Successfully computed and stored weekly statistics for imported entries.', data: weeklyStatistics };
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