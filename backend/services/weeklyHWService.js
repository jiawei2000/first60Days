const db = require('../config/database');
const { Timestamp } = require('firebase-admin/firestore');

const WeeklyHeightWeight = require('../models/WeeklyHeightWeight');

class WeeklyHWService {
    static async newWeeklyHW(babyID, { height, weight }) {
        const heightWeightRef = db.collection("weeklyHeightWeight").doc();
        const babyRef = db.collection('babies').doc(babyID);

        const heightWeight = new WeeklyHeightWeight(heightWeightRef.id, {
            height,
            weight,
            babyIDRef: babyRef,
            createdAt: Timestamp.now(),
        });

        await heightWeightRef.set(heightWeight.toFirestore());
        return { heightWeight };
    }

    static async getWeeklyHW(babyID) {
        const babyRef = db.collection('babies').doc(babyID);
        const snapshot = await db.collection('weeklyHeightWeight')
            .where('babyIDRef', '==', babyRef)
            .orderBy('createdAt', 'desc')
            .get();

        const heightWeights = snapshot.docs.map(doc => {
            const data = doc.data();
            return new WeeklyHeightWeight(doc.id, data);
        });

        return { heightWeights };
    }
}

module.exports = WeeklyHWService;