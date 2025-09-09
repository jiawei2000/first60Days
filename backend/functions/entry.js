const express = require('express');
const db = require('../database');
const router = express.Router()
const { authenticateToken } = require('./auth');

//Create Entry 
router.post('/journal/newEntry', authenticateToken, async (req, res) => {
    //create a new entry for a particular baby 
    try {
        // --- forensic logs ---
        console.log('>> /journal/newEntry headers:', req.headers);
        // show raw keys received
        console.log('>> keys:', Object.keys(req.body));
        // show whether cycleNo key exists at all
        console.log('>> has cycleNo:', Object.prototype.hasOwnProperty.call(req.body, 'cycleNo'));
        // show the actual value and its JS type
        console.log('>> cycleNo value:', req.body.cycleNo, 'type:', typeof req.body.cycleNo);
        // full body (safe-ish)
        console.log('>> body:', JSON.stringify(req.body));
        const {
            babyId, awakeTime, cycleNo,
            feedType, remarks, sleepDuration,
            startFeedTime, startPlayTime, startSleepTime,
            stool, urine
        } = req.body;

        // Validate required fields
        if (!babyId) {
            return res.status(400).json({ error: "babyId are required" });
        }
        // Reference to the baby's journalEntries subcollection
        const journalRef = db.collection("babies").doc(babyId).collection("journalEntries");

        // Create a new document with auto-generated ID
        const newEntryRef = await journalRef.add({
            awakeTime, cycleNo, feedType, remarks,
            sleepDuration, startFeedTime, startPlayTime,
            startSleepTime, stool, urine
        });

        res.status(201).json({
            message: "Journal entry created successfully",
            entryId: newEntryRef.id
        });

    } catch (error) {
        console.error("Error creating journal entry:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
})


//Edit Entry
router.put('/journal/editEntry/:babyId/:entryId', authenticateToken, async (req, res) => {
    try {
        const { babyId, entryId } = req.params;
        const body = req.body;

        if (!babyId || !entryId) {
            return res.status(400).json({ error: "babyId and entryId are required" });
        }

        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries")
            .doc(entryId);

        // Build update object dynamically
        const updateData = {};

        // Only add fields that exist in the request body
        if (body.awakeTime) updateData.awakeTime = new Date(body.awakeTime);
        if (body.cycleNo !== undefined) updateData.cycleNo = body.cycleNo;
        if (body.feedType) updateData.feedType = body.feedType;
        if (body.remarks !== undefined) updateData.remarks = body.remarks;
        if (body.sleepDuration !== undefined) updateData.sleepDuration = body.sleepDuration;
        if (body.startFeedTime) updateData.startFeedTime = new Date(body.startFeedTime);
        if (body.startPlayTime) updateData.startPlayTime = new Date(body.startPlayTime);
        if (body.startSleepTime) updateData.startSleepTime = new Date(body.startSleepTime);
        if (body.urine !== undefined) updateData.urine = body.urine;
        if (body.stool !== undefined) updateData.stool = body.stool;

        // updateData.updatedAt = new Date(); // optional, track last edit

        // Update the document
        await journalRef.update(updateData);

        res.status(200).json({ message: "Journal entry updated successfully" });
    } catch (error) {
        console.error("Error updating journal entry:", error);
        res.status(500).json({ error: error.message });
    }
})

//View Entries 
router.get('/journal/entries/:babyId', authenticateToken, async (req, res) => {
    //get all journal entries from a particular document ID of baby
    try {
        const { babyId } = req.params;
        // Reference to baby's journalEntries subcollection
        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries");

        const snapshot = await journalRef.get(); //an array of entries 

        if (snapshot.empty) {
            return res.status(404).json({ message: "No journal entries found" });
        }

        // Format the results
        const entries = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        res.status(200).json(entries);

    } catch (error) {
        console.error("Error getting journal entries:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
})

//View Entry 
router.get('/journal/entry/:babyId/:entryId',authenticateToken, async (req, res) => {
    //retreive a single journal entry from a particular baby 
    try {
        const { babyId, entryId } = req.params;

        // Reference to baby's journalEntries subcollection
        const journalRef = db
            .collection("babies")
            .doc(babyId)
            .collection("journalEntries")
            .doc(entryId);

        const snapshot = await journalRef.get(); //a single document entry 

        if (!snapshot.exists) {
            return res.status(404).json({ message: "No journal entry found" });
        }

        // Format the results
        res.status(200).json({
            id: snapshot.id,
            ...snapshot.data()
        });

    } catch (error) {
        console.error("Error getting journal entries:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
})

module.exports = router;