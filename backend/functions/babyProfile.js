const express = require('express');
const db = require('../database');
const router = express.Router()
const { authenticateToken } = require('./auth');
const { Timestamp } = require('firebase-admin/firestore');

//user create new baby profile and permission 
router.post('/babyProfile/newBaby', authenticateToken, async (req, res) => {
    //create a new baby profile
    try {
        const {
            userId, name, dob,
        } = req.body;

        // Validate required fields
        if (!userId) {
            return res.status(400).json({ error: "userId required" });
        }

        // Reference to the baby and permission collection 
        const babyRef = db.collection("babies");
        const permissionRef = db.collection("permissions");

        // Create a new baby document with auto-generated ID
        const newBabyDoc = await babyRef.add({
            name, dob,
            createdAt: Timestamp.now(),
            deletedAt: null,
            feedSchedule: null,
        });

        //create a new permission document with auto-generated ID 
        const newPermissionDoc = await permissionRef.add({
            permissionType: "main",
            createdAt: Timestamp.now(),
            deletedAt: null,
            userID: db.collection("users").doc(userId),
            babyID: db.collection("babies").doc(newBabyDoc.id)
        })

        res.status(201).json({
            message: "Journal entry created successfully",
            babyId: newBabyDoc.id,
            permissionId: newPermissionDoc.id
        });

    } catch (error) {
        console.error("Error creating journal entry:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
})

//update baby profile 
router.put('/babyProfile/editBaby', authenticateToken, async (req, res) => {
    try {
        // const { babyId } = req.params;
        const babyId = req.body.babyId;
        const body = req.body;

        // Validate required fields
        if (!babyId) {
            return res.status(400).json({ error: "babyId is required" });
        }
        //Optional: Check if baby belongs to the main user 
        // Reference to the baby document
        const babyDoc = db.collection("babies").doc(babyId)

        // Build update object dynamically
        const updateData = {};

        // Only add fields that exist in the request body
        if (body.dob) updateData.dob = new Date(body.dob);
        if (body.name !== undefined) updateData.name = body.name;

        // Update the document
        await babyDoc.update(updateData);

        res.status(200).json({ message: "Journal entry updated successfully" });

    } catch (error) {
        console.error("Error updating journal entry:", error);
        res.status(500).json({ error: error.message });
    }
})

//delete baby profile
//what happens to the sub Account if main deletes baby profile?
//Do we actually delete the baby records in the database?? soft delete. 
//v1: if delete baby profile, both permission and baby doc needs to be deleted. 
//v2: if delete baby profile, baby doc and all permission doc related to the baby needs to be deleted 
router.delete('/babyProfile/delete', authenticateToken, async (req, res) => {
    try {
        const babyId = req.body.babyId;
        const batch = db.batch();

        // Validate required fields
        if (!babyId) {
            return res.status(400).json({ error: "babyId is required" });
        }
        //Optional: security check if baby belongs to the main user 
        //Delete baby profile doc with matching babyID
        const babyRef = db.collection('babies').doc(babyId);
        batch.update(babyRef, { deletedAt: Timestamp.now() })

        //Delete permission docs with matching babyID 
        const permissionsRef = db.collection("permissions");
        const snapshot = await permissionsRef.where("babyID", "==", babyId).get();

        snapshot.forEach((doc) => {
            const docRef = permissionsRef.doc(doc.id);
            batch.update(docRef, { deletedAt: Timestamp.now() });
        });

        await batch.commit();

        res.json({ message: 'Baby profile deleted' });
    }
    catch (error) {
        res.status(400).json({ error: error.message });
    }
});

//get a list of baby profile permitted to user  
router.get('/babyProfile/profiles/:userId', authenticateToken, async (req, res) => {
    //get all journal entries from a particular document ID of baby
    try {
        const { userId } = req.params;
        // Reference to baby's journalEntries subcollection
        const permissionRef = db.collection("permissions");
        const snapshot = await permissionsRef.where("userID", "==", userId).get();

        if (snapshot.empty) {
            return res.status(404).json({ message: "No permissions found" });
        }

        const babyProfiles = [];
        //each permissions have a babyID field which is a reference data type 
        //add the get the baby document and add it into baby profiles 
        const babyPromises = snapshot.docs.map(async (doc) => {
            const permissionData = doc.data();

            // Assuming babyID is a Firestore DocumentReference
            if (permissionData.babyID) {
                const babySnap = await permissionData.babyID.get();
                if (babySnap.exists) {
                    babyProfiles.push({
                        id: babySnap.id,
                        ...babySnap.data()
                    });
                }
            }
        });

        await Promise.all(babyPromises);

        res.status(200).json(babyProfiles);

    } catch (error) {
        res.status(500).json({ error: "Internal Server Error" });
    }
})

//get a particular baby profile
router.get('/babyProfile/profile/:babyId', authenticateToken, async (req, res) => {
    //get all journal entries from a particular document ID of baby
    try {
        const { babyId } = req.params;

        //reference to baby document 
        const babyDoc = db.collection("babies").doc(babyId);

        const snapshot = await babyDoc.get();

        if (!snapshot.exists) {
            return res.status(404).json({ message: "No baby profile found" });
        }

        // Format the results
        res.status(200).json({
            id: snapshot.id,
            ...snapshot.data()
        });

    } catch (error) {
        res.status(500).json({ error: "Internal Server Error" });
    }
})



module.exports = router;