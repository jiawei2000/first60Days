const db = require('../config/database');

const JournalEntry = require('../models/JournalEntry');

const { Timestamp } = require('firebase-admin/firestore');
const admin = require("firebase-admin");

class JournalService {
    static async createEntry(babyId, entryData) {

        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries");

        const newEntryRef = await journalRef.add({ ...entryData });

        return new JournalEntry(newEntryRef.id, entryData);
    }

    static async editEntry(babyId, entryId, updateData) {

        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries")
            .doc(entryId);

        // Only include fields that exist
        const filteredData = {};
        for (const [key, value] of Object.entries(updateData)) {
            if (value !== undefined && value !== null) {
                // Convert date strings to Firestore Timestamp if necessary
                if (['awakeTime', 'startFeedTime', 'startPlayTime', 'startSleepTime'].includes(key)) {
                    filteredData[key] = new Date(value);
                } else {
                    filteredData[key] = value;
                }
            }
        }

        await journalRef.update(filteredData);

        const snapshot = await journalRef.get();
        return new JournalEntry(snapshot.id, snapshot.data());
    }

    static async getEntries(babyId) {
        // Reference to baby's journalEntries subcollection
        if (!babyId) throw new Error("babyId is required"); // validate babyId

        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries");

        const snapshot = await journalRef.get(); // get all entries

        // Return empty array if no entries found
        if (snapshot.empty) return [];

        // Map documents to JournalEntry objects
        return snapshot.docs.map(doc => new JournalEntry(doc.id, doc.data()));
    }

    static async getEntryById(babyId, entryId) {
        if (!babyId || !entryId) throw new Error("babyId and entryId are required"); // validate params

        // Reference to baby's journalEntries subcollection
        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries")
            .doc(entryId);

        const snapshot = await journalRef.get(); // fetch single document

        if (!snapshot.exists) return null;

        // Return as JournalEntry object
        return new JournalEntry(snapshot.id, snapshot.data());
    }
}

module.exports = JournalService;
