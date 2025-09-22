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


    //updatePlanner need more specific usecase of update?
    //change only the feed timings?
    //change number of feed?
    static async updatePlanner(babyId, plannerId, updateData) {
        const docRef = db
            .collection("babies")
            .doc(babyId)
            .collection("entryPlanner")
            .doc(plannerId);

        const planner = new EntryPlanner(plannerId, updateData);
        planner.generateFeedTimings(); // regenerate feedTimings if first/last feed changed

        await docRef.update(planner.toFirestore());
        return planner;
    }

    static async deletePlanner(plannerId) {
        // Delete from Firestore if persistence is implemented
        return true;
    }
}

module.exports = EntryPlannerService;
