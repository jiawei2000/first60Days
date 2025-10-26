const db = require('../config/database')

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
            .where("date", ">=", startOfDay)
            .where("date", "<=", endOfDay)
            .orderBy("awakeTime", "asc")  // "asc" for earliest first, "desc" for latest first
            .get();

        const entries = snapshot.docs.map(doc => doc.data()); //array of journal entries
        // Calculate and return statistics based on the journal entries
        return this.calculateDailyStatistics(entries);
    }

    // Helper method to calculate daily statistics
    calculateDailyStatistics(entries) {
        const statistics = {
            totalFeeds: 0,
            totalSleepDuration: 0, // in minutes
            totalDiaperChanges: 0
        };

        entries.forEach(entry => {
            statistics.totalFeedings += entry.feedings || 0;
            statistics.totalSleepDuration += entry.sleepDuration || 0;
            statistics.totalDiaperChanges += entry.diaperChanges || 0;
        });

        return statistics;
    }

    // async getWeeklyStatistics(babyId, startDate, endDate) {
    //     // Implement logic to fetch weekly statistics for the given babyId and date range   
    // }
}

module.exports = new StatisticsService();
