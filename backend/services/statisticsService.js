const { Timestamp } = require('firebase-admin/firestore');
const db = require('../config/database')
const DailyStatistics = require('../models/dailyStatistics');
const processStatisticsService = require('./processStatisticsService'); // Import the service to process statistics

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

    async getAllGenderStatistics() {
        const statsSnap = await db.collection("statisticsByGender").get();
        if (statsSnap.empty) {
            throw new Error('No gender statistics found');
        }
        const statistics = statsSnap.docs.map(doc => doc.data());
        //sort by date ascending
        statistics.sort((a, b) => (a.date > b.date) ? 1 : -1);
        return statistics;
    }

    async getStatisticsByGenderById(statisticId) {
        const statDoc = await db.collection("statisticsByGender").doc(statisticId).get();
        if (!statDoc.exists) {
            throw new Error('Statistic not found');
        }
        return statDoc.data();
    }

    async getAllAgeGroupStatistics() {
        const statsSnap = await db.collection("ageGroupStatistics").get();
        if (statsSnap.empty) {
            throw new Error('No age group statistics found');
        }
        const statistics = statsSnap.docs.map(doc => doc.data());
        //sort by ageGroup ascending
        statistics.sort((a, b) => (a.ageGroup > b.ageGroup) ? 1 : -1);
        return statistics;
    }

    async getAgeGroupStatisticsById(statisticId) {
        const statDoc = await db.collection("ageGroupStatistics").doc(statisticId).get();
        if (!statDoc.exists) {
            throw new Error('Statistic not found');
        }
        return statDoc.data();
    }

    //recompute daily statistics for an empty/incompete daily statistics entry/ID - to be implemented
    async recomputeDailyStatistics(statisticId) {
        //to be implemented
        const dailyStatisticsDoc = await db.collection("dailyStatistics").doc(statisticId).get();
        if (!dailyStatisticsDoc.exists) {
            throw new Error('Daily Statistics not found');
        }

        const babyIDRef = dailyStatisticsDoc.data().babyIDRef; //this is a DocumentReference
        const date = dailyStatisticsDoc.data().date; // date string in 'YYYY-MM-DD' format

        //convert date string to Date object for querying
        const dailyStatisticsDate = new Date(date);
        const startOfDay = new Date(Date.UTC(dailyStatisticsDate.getUTCFullYear(), dailyStatisticsDate.getUTCMonth(), dailyStatisticsDate.getUTCDate(), 0, 0, 0, 0));
        const endOfDay = new Date(Date.UTC(dailyStatisticsDate.getUTCFullYear(), dailyStatisticsDate.getUTCMonth(), dailyStatisticsDate.getUTCDate(), 23, 59, 59, 999));



        const journalEntriesSnap = await babyIDRef.collection("journalEntries")
            .where("awakeTime", ">=", startOfDay)
            .where("awakeTime", "<=", endOfDay)
            .orderBy("awakeTime", "asc")
            .get();

        if (journalEntriesSnap.empty) {
            console.log(`No journal entries found for baby ${babyIDRef.id} on ${date}.`);
            return;
        }

        // Process journal entries to recompute daily statistics
        const journalEntries = journalEntriesSnap.docs.map(doc => doc.data());
        const newStatistics = processStatisticsService.calculateDailyStatistics(journalEntries);
        //only need to update the existing document
        await db.collection("dailyStatistics").doc(statisticId).set(newStatistics, { merge: true });
        console.log(`Recomputed daily statistics for baby ${babyIDRef.id} on ${date}.`);
    }

    async createAgeGroupStatistics(data) {
        const ageGroupStatsRef = db.collection("ageGroupStatistics").doc();
        const ageGroupStatsData = {
            ...data,
            createdAt: Timestamp.now(),
        };
        await ageGroupStatsRef.set(ageGroupStatsData);
        return ageGroupStatsData;
    }

    async createStatisticsByGender(data) {
        const genderStatsRef = db.collection("statisticsByGender").doc();
        const genderStatsData = {
            ...data,
            createdAt: Timestamp.now()
        };
        await genderStatsRef.set(genderStatsData); 
        return genderStatsData;
    }

}

module.exports = new StatisticsService();
