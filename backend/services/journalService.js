const db = require('../config/database');

const JournalEntry = require('../models/JournalEntry');

class JournalService {
    static async createEntry(babyId, entryData) {
        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries");

        // Determine completion status
        entryData.status = JournalEntry.checkStatus(entryData);

        // Create normalized instance
        const entry = new JournalEntry(null, entryData);

        //  Save to Firestore
        const newEntryRef = await journalRef.add(entry.toFirestore());

        // Return instance with new ID
        return new JournalEntry(newEntryRef.id, entryData);
    }

    static async editEntry(babyId, entryId, updateData) {
        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries")
            .doc(entryId);

        // ✅ 1. Fetch existing data
        const existingSnap = await journalRef.get();
        if (!existingSnap.exists) {
            throw new Error(`Journal entry ${entryId} not found for baby ${babyId}.`);
        }

        const existingData = existingSnap.data();

        // 2. Merge existing data with incoming updates
        const mergedData = { ...existingData, ...updateData };

        // 3. Recalculate completion status for the entire entry
        mergedData.status = JournalEntry.checkStatus(mergedData);

        // 4. Validate & normalize fields (partial = true for selective updates)
        const validatedData = JournalEntry.validateData(mergedData, { partial: true });

        // 5. Update Firestore document
        await journalRef.update(validatedData);

        // 6. Return the updated normalized entry
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

    static async getCurrentCycleNo(babyId) {
        // Determine start and end of the day
        //this is not a good implementation. Needs to be updated.
        const now = new Date();
        const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
        const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);


        //reference to babyjournal entries 
        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries");

        //entries of the day     
        const entrySnap = await journalRef
            .where("awakeTime", ">=", startOfDay)
            .where("awakeTime", "<=", endOfDay)
            .orderBy("awakeTime", "desc")
            .limit(1)
            .get();
        console.log(entrySnap);
        //Find the next cycleNo
        let nextCycleNo = 1;
        if (!entrySnap.empty) {
            const lastEntry = entrySnap.docs[0].data();
            nextCycleNo = (lastEntry.cycleNo || 0) + 1;
        }
        return nextCycleNo;
    }
}

module.exports = JournalService;
