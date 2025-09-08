const express = require('express');
const db = require('../database');
const router = express.Router()
const { authenticateToken } = require('./auth');
const { Timestamp } = require('firebase-admin/firestore');
const admin = require("firebase-admin");

//user create new baby profile and permission 
// router.post('/babyProfile/newBaby', authenticateToken, async (req, res) => {
//     //create a new baby profile
//     try {
//         const {
//             name, dob,
//         } = req.body;

//         // Validate required fields
//         if (!userId) {
//             return res.status(400).json({ error: "userId required" });
//         }

//         // Reference to the baby and permission collection 
//         const babyRef = db.collection("babies");

//         // Create a new baby document with auto-generated ID
//         const newBabyDoc = await babyRef.add({
//             name, dob,
//             createdAt: Timestamp.now(),
//             deletedAt: null,
//             feedSchedule: null,
//         });

//         //add babyRef into babyIDArr field (array data type) in permission doc 
//         const babyDocRef = babyRef.doc(newBabyDoc.id)
//         const userSnap = await db.collection("users").doc(userId).get();
//         if (!userSnap.exists) {
//             return res.status(404).json({ message: "User not found" });
//         }

//         //reference to permission doc
//         const permissionRef = userSnap.data().permissionID;

//         if (!permissionRef) {
//             return res.status(404).json({ message: "Permission reference not found for this user" });
//         }

//         // Update the permission document to include babyDocRef in babyIDArr
//         await permissionRef.update({
//             babyIDArr: admin.firestore.FieldValue.arrayUnion(babyDocRef),
//         });


//         res.status(201).json({
//             message: "Baby created and added to permissions",
//             babyId: newBabyDoc.id,
//         });

//     } catch (error) {
//         res.status(500).json({ error: "Internal Server Error" });
//     }
// })
router.post('/babyProfile/newBaby', authenticateToken, async (req, res) => {
    const userId = req.user.id;

    try {
        const { name, dob } = req.body;

        if (!name || !dob) {
            return res.status(400).json({ error: "Name and DOB are required" });
        }

        const result = await db.runTransaction(async (t) => {
            // Get user doc
            const userRef = db.collection("users").doc(userId);
            const userSnap = await t.get(userRef);

            if (!userSnap.exists) {
                throw new Error("User not found");
            }

            const permissionRef = userSnap.data().permissionID;
            if (!permissionRef) {
                throw new Error("Permission reference not found");
            }

            // Create baby doc reference
            const babyRef = db.collection("babies").doc();

            // Create baby inside transaction
            t.set(babyRef, {
                name,
                dob,
                createdAt: Timestamp.now(),
                deletedAt: null,
                feedSchedule: null,
            });

            // Update permission doc with new baby ref
            t.update(permissionRef, {
                babyIDArr: admin.firestore.FieldValue.arrayUnion(babyRef),
            });

            // Return babyId so we can use it outside
            return { babyId: babyRef.id };
        });

        res.status(201).json({
            message: "Baby created and added to permissions",
            babyId: result.babyId,
        });

    }
    catch (error) {
        console.error("Error in /babyProfile/newBaby:", error.message);
        if (error.message === "User not found" || error.message === "Permission reference not found") {
            return res.status(404).json({ error: error.message });
        }
        res.status(500).json({ error: "Internal Server Error" });
    }
});

//update baby profile 
router.put('/babyProfile/editBaby', authenticateToken, async (req, res) => {
    try {
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

        res.status(200).json({ message: "Baby profile updated successfully" });

    } catch (error) {
        console.error("Error updating baby profile:", error);
        res.status(500).json({ error: error.message });
    }
})

//delete baby profile
router.delete('/babyProfile/delete', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const { babyId } = req.body;
        const batch = db.batch();

        // Validate required fields
        if (!babyId) {
            return res.status(400).json({ error: "babyId is required" });
        }

        // Baby reference
        const babyRef = db.collection("babies").doc(babyId);

        // Soft-delete baby profile
        batch.update(babyRef, { deletedAt: Timestamp.now() });

        // Find all permissions with access to this baby
        const userSnap = await db.collection('users').doc(userId).get()
        const permissionRef = userSnap.data().permissionID; //permission reference of main user 

        const permissionSnap = await permissionRef.get();
        if (!permissionSnap.exists) {
            return res.status(404).json({ error: "Main user's permission not found" });
        }

        // Remove babyRef from main user's permission doc
        batch.update(permissionRef, {
            babyIDArr: admin.firestore.FieldValue.arrayRemove(babyRef),
        });

        // Get sub-users from the main user's permission doc
        const { subUserId } = permissionSnap.data(); // this is an array of userRefs
        if (Array.isArray(subUserId) && subUserId.length > 0) {
            for (const subUserRef of subUserId) {
                // Get sub-user's permission doc
                const subUserSnap = await db
                    .collection("permissions")
                    .where("userId", "==", subUserRef) // userId is stored as a Reference
                    .get();

                subUserSnap.forEach((doc) => {
                    batch.update(doc.ref, {
                        babyIdArr: admin.firestore.FieldValue.arrayRemove(babyRef),
                    });
                });
            }
        }

        await batch.commit();

        res.json({ message: "Baby profile deleted successfully" });
    } catch (error) {
        console.error("Error deleting baby profile:", error);
        res.status(400).json({ error: error.message });
    }
});

//get baby profiles permitted to user  
router.get('/babyProfiles', authenticateToken, async (req, res) => {
    //get all journal entries from a particular document ID of baby
    try {
        const userId = req.user.id;
        // Reference to baby's journalEntries subcollection
        const userSnap = await db.collection("users").doc(userId).get();
        if (!userSnap.exists) {
            return res.status(404).json({ error: "User not found" });
        }
        const permissionRef = userSnap.data().permissionID; //permission reference of main user 
        const permissionSnap = await permissionRef.get();
        if (!permissionSnap.exists) {
            return res.status(404).json({ error: "Permission document does not exist" });
        }

        const { babyIDArr } = permissionSnap.data();
        if (!babyIDArr || babyIDArr.length === 0) {
            return res.status(200).json({ babyProfiles: [] });
        }

        const babyProfiles = [];
        for (const babyRef of babyIDArr) {
            const babySnap = await babyRef.get();
            if (babySnap.exists) {
                babyProfiles.push({
                    id: babySnap.id,
                    ...babySnap.data(),
                });
            }
        }

        res.status(200).json({ babyProfiles });

    } catch (error) {
        res.status(500).json({ error: "Internal Server Error" });
    }
})

//get a particular baby profile
router.get('/babyProfile/:babyId', authenticateToken, async (req, res) => {
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