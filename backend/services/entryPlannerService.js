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

    static async getPlanner(plannerId) {
        // If stored in Firestore:
        // const doc = await db.collection("entryPlanners").doc(plannerId).get();
        // return doc.exists ? doc.data() : null;

        // Placeholder for now
        return null;
    }

    static async updatePlanner(plannerId, updateData) {
        // Fetch existing, update fields, regenerate feedTimings if needed
        // Save to Firestore if persistence is implemented
        return null;
    }

    static async deletePlanner(plannerId) {
        // Delete from Firestore if persistence is implemented
        return true;
    }
}

module.exports = EntryPlannerService;
