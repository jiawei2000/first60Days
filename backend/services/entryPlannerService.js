const EntryPlanner = require("../models/EntryPlanner");

const db = require('../config/database');

class EntryPlannerService {

    static async createPlanner(babyId, plannerData) {
        if (!babyId) throw new Error("babyId is required");
        if (!plannerData || !plannerData.weekNo) throw new Error("weekNo is required in plannerData");

        const plannerCollection = db
            .collection("babies")
            .doc(babyId)
            .collection("entryPlanner");

        // Step 1: Check if there's already a planner with the same weekNo
        const existingQuery = await plannerCollection
            .where("weekNo", "==", plannerData.weekNo)
            .limit(1)
            .get();

        let plannerRef;

        if (!existingQuery.empty) {
            // Override existing doc
            const existingDoc = existingQuery.docs[0];
            plannerRef = plannerCollection.doc(existingDoc.id);
            console.log(`Updating existing planner for week ${plannerData.weekNo}...`);
        } else {
            // Create a new planner
            plannerRef = plannerCollection.doc(); // auto-generated ID
            console.log(`Creating new planner for week ${plannerData.weekNo}...`);
        }

        // Step 2: Validate that firstFeedTime and lastFeedTime are valid HH:mm strings
        const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)$/;
        if (!timeRegex.test(plannerData.firstFeedTime) || !timeRegex.test(plannerData.lastFeedTime)) {
            throw new Error("Invalid time format. Expected 'HH:mm'");
        }

        // Step 3: Initialize planner object
        const planner = new EntryPlanner(plannerRef.id, plannerData);

        // Step 4: Generate feed timings
        const message = planner.generateFeedTimings();

        // Step 5: Save to Firestore (stores strings, not timestamps)
        await plannerRef.set(planner.toFirestore(), { merge: false });

        // Step 6: Return planner and message
        return { planner, message };
    }

    static async getPlannerById(babyId, plannerId) {
        const docRef = db
            .collection("babies")
            .doc(babyId)
            .collection("entryPlanner")
            .doc(plannerId);

        const doc = await docRef.get();
        if (!doc.exists) return null;

        return new EntryPlanner(doc.id, doc.data());
    }



    //if users change their firstFeedTime and lastFeedTime, give them updated generated timings
    static async updatePlanner(babyId, plannerId, updateData) {
        if (!plannerId) throw new Error("plannerId is required");

        const plannerRef = db.collection("babies").doc(babyId).collection("entryPlanner").doc(plannerId);

        // Get existing planner
        const doc = await plannerRef.get();
        if (!doc.exists) {
            throw new Error(`Planner with ID ${plannerId} not found`);
        }

        const existingData = doc.data();

        // Merge updates with existing fields
        const mergedData = { ...existingData, ...updateData };

        // Rebuild planner and regenerate fields
        const updatedPlanner = new EntryPlanner(plannerId, mergedData);
        let message = updatedPlanner.generateFeedTimings();

        // Update only the necessary fields in Firestore
        await plannerRef.update(updatedPlanner.toFirestore());

        return { updatedPlanner, message };

    }

    //Update feedTimings only
    static async updateFeedTimings(babyId, plannerId, updateData) {
        if (!plannerId) throw new Error("plannerId is required");

        const plannerRef = db.collection("babies").doc(babyId).collection("entryPlanner").doc(plannerId);

        // Get existing planner
        const doc = await plannerRef.get();
        if (!doc.exists) {
            throw new Error(`Planner with ID ${plannerId} not found`);
        }

        const existingData = doc.data();

        // Merge updates with existing fields
        const mergedData = { ...existingData, ...updateData };

        // Rebuild planner and regenerate fields
        const updatedPlanner = new EntryPlanner(plannerId, mergedData);

        // Update only the necessary fields in Firestore
        await plannerRef.update(updatedPlanner.toFirestore());

        return updatedPlanner;
    }

    static async getPlanners(babyId) {
        const plannerRef = db.collection("babies").doc(babyId).collection("entryPlanner");

        const snapshot = await plannerRef.orderBy("createdAt", "desc").get();

        if (snapshot.empty) return [];

        return snapshot.docs.map(doc => {
            const data = doc.data();
            return new EntryPlanner(doc.id, data);
        });
    }

    static async deletePlanner(plannerId) {
        // Delete from Firestore if persistence is implemented
        return true;
    }
}

module.exports = EntryPlannerService;
