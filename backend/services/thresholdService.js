const db = require('../config/database');


class ThresholdService {
    static async createDailyThreshold(thresholdData) {
        const dailyThresholdCollection = db.collection('dailyThresholds');
        const docRef = await dailyThresholdCollection.add(thresholdData);
        return { id: docRef.id, ...thresholdData };
    }

    static async createWeeklyThreshold(thresholdData) {
        const weeklyThresholdCollection = db.collection('weeklyThresholds');
        const docRef = await weeklyThresholdCollection.add(thresholdData);
        return { id: docRef.id, ...thresholdData };
    }

    static async getAllDailyThresholds() {
        const dailyThresholdCollection = db.collection('dailyThresholds');
        const snapshot = await dailyThresholdCollection.get();
        const thresholds = [];
        snapshot.forEach(doc => {
            thresholds.push({ id: doc.id, ...doc.data() });
        });
        return thresholds;
    }

    static async getAllWeeklyThresholds() {
        const weeklyThresholdCollection = db.collection('weeklyThresholds');
        const snapshot = await weeklyThresholdCollection.get();
        const thresholds = [];
        snapshot.forEach(doc => {
            thresholds.push({ id: doc.id, ...doc.data() });
        });
        return thresholds;
    }

    static async updateDailyThreshold(id, thresholdData) {
        const dailyThresholdCollection = db.collection('dailyThresholds');
        const docRef = dailyThresholdCollection.doc(id);

        // Check if document exists
        const snapshot = await docRef.get();
        if (!snapshot.exists) {
            throw new Error(`Threshold document with ID ${id} not found`);
        }

        const existingData = snapshot.data();

        // Validate that all top-level keys in payload exist in the document
        for (const key of Object.keys(thresholdData)) {
            if (!Object.prototype.hasOwnProperty.call(existingData, key)) {
                throw new Error(`Invalid field "${key}". This field does not exist in the threshold document.`);
            }
        }
        // Prepare Firestore update object
        // Example input:
        // {
        //   "totalFeeds": {
        //     "value": { "week1": 9, "week2": 8 }
        //   }
        // }
        // → converts to:
        // { "totalFeeds.value": { "week1": 9, "week2": 8 } }

        const updatePayload = {};
        for (const [key, subObj] of Object.entries(thresholdData)) {
            if (typeof subObj === "object" && subObj !== null) {
                for (const [subKey, subValue] of Object.entries(subObj)) {
                    updatePayload[`${key}.${subKey}`] = subValue;
                }
            } else {
                // fallback if someone sends a flat field
                updatePayload[key] = subObj;
            }
        }

        // Perform partial update
        await docRef.update(updatePayload);

        // Return updated document
        const updatedDoc = await docRef.get();
        return { id: updatedDoc.id, ...updatedDoc.data() };
    }

    static async updateWeeklyThreshold(id, thresholdData) {
        const weeklyThresholdCollection = db.collection('weeklyThresholds');
        const docRef = weeklyThresholdCollection.doc(id);

        // Check if document exists
        const snapshot = await docRef.get();
        if (!snapshot.exists) {
            throw new Error(`Threshold document with ID ${id} not found`);
        }

        const existingData = snapshot.data();

        // Validate that all top-level keys in payload exist in the document
        for (const key of Object.keys(thresholdData)) {
            if (!Object.prototype.hasOwnProperty.call(existingData, key)) {
                throw new Error(`Invalid field "${key}". This field does not exist in the threshold document.`);
            }
        }

        // Prepare Firestore update object
        const updatePayload = {};
        for (const [key, subObj] of Object.entries(thresholdData)) {
            if (typeof subObj === "object" && subObj !== null) {
                for (const [subKey, subValue] of Object.entries(subObj)) {
                    updatePayload[`${key}.${subKey}`] = subValue;
                }
            } else {
                // fallback if someone sends a flat field
                updatePayload[key] = subObj;
            }
        }

        // Perform partial update
        await docRef.update(updatePayload);

        // Return updated document
        const updatedDoc = await docRef.get();
        return { id: updatedDoc.id, ...updatedDoc.data() };
    }

    static async evaluateDailyStatisticsAgainstThresholds(dailyStatisticsId) {
        // Fetch daily statistics
        const dailyStatsRef = db.collection('dailyStatistics').doc(dailyStatisticsId);
        const dailyStatsSnap = await dailyStatsRef.get();
        if (!dailyStatsSnap.exists) {
            throw new Error(`Daily statistics with ID ${dailyStatisticsId} not found`);
        }

        // Get daily statistics data
        const dailyStats = dailyStatsSnap.data();
        let day = dailyStats.day; // e.g., 8
        let week = Math.ceil(day / 7); // e.g., 2
        console.log(`Evaluating thresholds for day ${day}, week ${week}`);

        // Fetch daily thresholds (assuming there's only one set of thresholds)
        const dailyThresholdsRef = db.collection('dailyThresholds');
        const thresholdsSnap = await dailyThresholdsRef.limit(1).get();
        if (thresholdsSnap.empty) {
            throw new Error('No daily thresholds found');
        }

        const thresholdStatus = {};

        const threshold = thresholdsSnap.docs[0].data();
        //threshold example: { totalFeeds: values: { week1: 9, week2: 8, week3: 7, week4: 6, week5: 5, week6: 5 } , label, status }

        // Evaluate each metric
        for (const [metric, config] of Object.entries(threshold)) {
            console.log(`Evaluating metric: ${metric}`);
            const weekValues = config.value; // e.g. { week1: 9, week2: 8 }
            const thresholdValue = weekValues[`week${week}`];
            const message = config.message; // e.g. { above: '...', below: '...' }
            const label = config.label; // e.g. { above: '...', below: '...' }

            const dailyValue = dailyStats[metric];

            //hh:mm fields: totalSleepDuration, totalPlayDuration, monInterval, averagePlayDuration, averageLapseDuration
            const timeFields = ['totalSleepDuration', 'totalPlayDuration', 'monInterval', 'averagePlayDuration', 'averageLapseDuration'];

            let status;

            //if hh:mm field, convert thresholdValue and dailyValue to minutes for comparison
            //else: remaining fields are number fields
            if (timeFields.includes(metric)) {
                const thresholdMinutes = ThresholdService.hhmmToMinutes(thresholdValue);
                const dailyMinutes = ThresholdService.hhmmToMinutes(dailyValue);
                if (dailyMinutes < thresholdMinutes) {
                    status = 'below';
                }
                else {
                    status = 'above';
                }
            }
            else {
                //number fields
                if (dailyValue < thresholdValue) {
                    status = 'below';
                }
                else {
                    status = 'above';
                }
            }

            thresholdStatus[metric] = {
                message: message[status],
                label: label[status],
                status: status
            };
        }

        return thresholdStatus;
    }

    // Similar method for weekly statistics
    static async evaluateWeeklyStatisticsAgainstThresholds(weeklyStatisticsId) {
        // Fetch weekly statistics
        const weeklyStatsRef = db.collection('weeklyStatistics').doc(weeklyStatisticsId);
        const weeklyStatsSnap = await weeklyStatsRef.get();
        if (!weeklyStatsSnap.exists) {
            throw new Error(`Weekly statistics with ID ${weeklyStatisticsId} not found`);
        }
        // Get weekly statistics data
        const weeklyStats = weeklyStatsSnap.data();
        let week = weeklyStats.week; // e.g., 2
        console.log(`Evaluating thresholds for week ${week}`);

        // Fetch weekly thresholds (assuming there's only one set of thresholds)
        const weeklyThresholdsRef = db.collection('weeklyThresholds');
        const thresholdsSnap = await weeklyThresholdsRef.limit(1).get();
        if (thresholdsSnap.empty) {
            throw new Error('No weekly thresholds found');
        }
        const thresholdStatus = {};

        const threshold = thresholdsSnap.docs[0].data();
        //threshold example: { totalFeeds: values: { week1: 9, week2: 8 } , label, status }

        // Evaluate each metric
        for (const [metric, config] of Object.entries(threshold)) {
            console.log(`Evaluating metric: ${metric}`);
            const weekValues = config.value; // e.g. { week1: 9, week2: 8 }
            const thresholdValue = weekValues[`week${week}`];
            const message = config.message; // e.g. { above: '...', below: '...' }
            const label = config.label; // e.g. { above: '...', below: '...' }

            const weeklyValue = weeklyStats[metric];

            let status;
            //hh:mm fields: totalSleepDuration, totalPlayDuration, monInterval, averagePlayDuration, averageLapseDuration
            const timeFields = ['totalSleepDuration', 'totalPlayDuration', 'averageMonInterval', 'averagePlayDuration', 'averageLapseDuration'];
            //if hh:mm field, convert thresholdValue and weeklyValue to minutes for comparison
            //else: remaining fields are number fields
            if (timeFields.includes(metric)) {
                const thresholdMinutes = ThresholdService.hhmmToMinutes(thresholdValue);
                const weeklyMinutes = ThresholdService.hhmmToMinutes(weeklyValue);
                if (weeklyMinutes < thresholdMinutes) {
                    status = 'below';
                } else {
                    status = 'above';
                }
            } else {
                //number fields
                if (weeklyValue < thresholdValue) {
                    status = 'below';
                } else {
                    status = 'above';
                }
            }

            thresholdStatus[metric] = {
                message: message[status],
                label: label[status],
                status: status
            };
        }
        return thresholdStatus;
    }

    //helper method to convert hh:mm to total minutes
    static hhmmToMinutes(hhmm) {
        const [hours, minutes] = hhmm.split(':').map(Number);
        return hours * 60 + minutes;
    }
}
module.exports = ThresholdService;
