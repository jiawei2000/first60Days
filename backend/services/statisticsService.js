const db = require('../config/database')
const DailyStatistics = require('../models/dailyStatistics');

class StatisticsService {
    async getWeeklyStatistics(babyId) {
        const babyRef = db.collection("babies").doc(babyId);
        if (!babyRef) {
            throw new Error('Baby not found');
        }
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

    async getDailyStatisticsByGender(date) {
        //get all babies
        const babiesSnap = await db.collection("babies").where("deletedAt", "==", null).get();
        if (babiesSnap.empty) {
            throw new Error('No active babies found');
        };
        const maleBabyRefs = [];
        const femaleBabyRefs = [];
        babiesSnap.forEach(babyDoc => {
            const babyData = babyDoc.data();
            if (babyData.gender === 'Male') {
                maleBabyRefs.push(babyDoc.ref);
            } else if (babyData.gender === 'Female') {
                femaleBabyRefs.push(babyDoc.ref);
            }
        });

        const result = computeStatisticsbyGender(date, maleBabyRefs, femaleBabyRefs);
        return result;
    }
}

module.exports = new StatisticsService();
