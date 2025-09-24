const EntryPlanner = require("../models/EntryPlanner");

const db = require('../config/database');

class EntryPlannerService {
    static async createPlanner(babyId, plannerData) {
        // Step 1: Firestore doc reference (auto-generated ID)
        const plannerRef = db
            .collection("babies")
            .doc(babyId)
            .collection("entryPlanner")
            .doc(); // generates doc ID

        // Step 2: Initialize EntryPlanner with the generated ID
        const planner = new EntryPlanner(plannerRef.id, plannerData);

        // Step 3: Generate feed timings & MONInterval
        planner.generateFeedTimings();

        // Step 4: Save to Firestore using toFirestore()
        await plannerRef.set(planner.toFirestore());

        // Step 5: Return the planner instance with ID and generated fields
        return planner;
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


    //updatePlanner 

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
        updatedPlanner.generateFeedTimings();

        // Update only the necessary fields in Firestore
        await plannerRef.update(updatedPlanner.toFirestore());

        return updatedPlanner;

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
