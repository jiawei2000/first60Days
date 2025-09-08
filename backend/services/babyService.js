const db = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config/authMiddleware');

const Baby = require('../models/Baby');

const { Timestamp } = require('firebase-admin/firestore');
const admin = require("firebase-admin");

class BabyService {
    static async newProfile(userId, { name, dob }) {
        if (!name || !dob) {
            throw new Error("Name and DOB are required");
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

            // Create baby doc
            const babyRef = db.collection("babies").doc();
            const baby = new Baby(babyRef.id, {
                name,
                dob,
                createdAt: Timestamp.now(),
                deletedAt: null,
                feedSchedule: null,
            });

            // Save baby doc in transaction
            t.set(babyRef, baby.toFirestore());

            // Update permission doc with new baby ref
            t.update(permissionRef, {
                babyIDArr: admin.firestore.FieldValue.arrayUnion(babyRef),
            });

            return baby;
        });

        return result;
    }

    static async editProfile(babyId, updateFields) {
        if (!babyId) {
            throw new Error("babyId is required");
        }

        const babyRef = db.collection("babies").doc(babyId);

        // Build updateData dynamically
        const updateData = {};
        if (updateFields.dob) updateData.dob = new Date(updateFields.dob);
        if (updateFields.name !== undefined) updateData.name = updateFields.name;

        if (Object.keys(updateData).length === 0) {
            throw new Error("No valid fields provided for update");
        }

        await babyRef.update(updateData);

        // Return updated baby instance
        const updatedDoc = await babyRef.get();
        return Baby.fromFirestore(updatedDoc);
    }

    static async deleteProfile(userId, babyId) {
        if (!babyId) {
            throw new Error("babyId is required");
        }

        const batch = db.batch();

        const babyRef = db.collection("babies").doc(babyId);

        // Soft delete the baby
        batch.update(babyRef, { deletedAt: Timestamp.now() });

        // Get main user's permission
        const userSnap = await db.collection('users').doc(userId).get();
        if (!userSnap.exists) {
            throw new Error("User not found");
        }

        const permissionRef = userSnap.data().permissionID;
        if (!permissionRef) {
            throw new Error("Main user's permission not found");
        }

        const permissionSnap = await permissionRef.get();
        if (!permissionSnap.exists) {
            throw new Error("Main user's permission not found");
        }

        // Remove baby from main permission
        batch.update(permissionRef, {
            babyIDArr: FieldValue.arrayRemove(babyRef),
        });

        // Clean up sub-user permissions
        const { subAccArr } = permissionSnap.data(); // array of sub-user references
        if (Array.isArray(subAccArr) && subAccArr.length > 0) {
            for (const subUserRef of subAccArr) {
                // Get sub-user's permission doc
                const subPermSnap = await db
                    .collection("permissions")
                    .where("userID", "==", subUserRef) // userID is a reference
                    .get();

                subPermSnap.forEach((doc) => {
                    batch.update(doc.ref, {
                        babyIDArr: FieldValue.arrayRemove(babyRef),
                    });
                });
            }
        }

        await batch.commit();

        return { message: "Baby profile deleted successfully" };
    }

    static async getProfiles(userId) {
        const userSnap = await db.collection("users").doc(userId).get();
        if (!userSnap.exists) {
            throw new Error("User not found");
        }

        const permissionRef = userSnap.data().permissionID;
        if (!permissionRef) {
            throw new Error("Permission document does not exist");
        }

        const permissionSnap = await permissionRef.get();
        if (!permissionSnap.exists) {
            throw new Error("Permission document does not exist");
        }

        const { babyIDArr } = permissionSnap.data();
        if (!babyIDArr || babyIDArr.length === 0) {
            return [];
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

        return babyProfiles;
    }

    static async getProfileById(babyId) {
        const babyRef = db.collection("babies").doc(babyId);
        const snapshot = await babyRef.get();

        if (!snapshot.exists) {
            throw new Error("Baby profile not found");
        }

        // Option A: return plain data
        return { id: snapshot.id, ...snapshot.data() };

        // Option B (if using Baby model consistently):
        // return new Baby(snapshot.id, snapshot.data());
    }
}

module.exports = BabyService;