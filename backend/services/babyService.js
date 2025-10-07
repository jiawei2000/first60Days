const db = require('../config/database');

const Baby = require('../models/Baby');

const { Timestamp } = require('firebase-admin/firestore');
const admin = require("firebase-admin");

class BabyService {
    static async newProfile(userId, { name, dob, expectedDueDate, term, weight, healthConditions }) {
        // Required fields check
        switch (true) {
            case !name:
                throw new Error("Name is required");
            case !dob:
                throw new Error("Date of Birth is required");
            case !expectedDueDate:
                throw new Error("Expected Due Date is required");
            case !term:
                throw new Error("Term is required");
            case !weight:
                throw new Error("Weight is required");
            case !healthConditions:
                throw new Error("Health Conditions are required");
        }

        // Use Baby.validateData to normalize fields
        const formattedData = Baby.validateData({ name, dob, expectedDueDate, term, weight, healthConditions });

        // Transaction to create baby and update permissions
        const result = await db.runTransaction(async (t) => {
            // Get user document
            const userRef = db.collection("users").doc(userId);
            const userSnap = await t.get(userRef);
            if (!userSnap.exists) throw new Error("User not found");

            const permissionRef = userSnap.data().permissionID;
            if (!permissionRef) throw new Error("Permission reference not found");

            // Create new Baby instance
            const babyRef = db.collection("babies").doc();
            const baby = new Baby(babyRef.id, {
                ...formattedData,
                createdAt: Timestamp.now(),
                deletedAt: null,
                // feedSchedule: null,
            });

            // Save baby in Firestore
            t.set(babyRef, baby.toFirestore());

            // Update permission doc with new baby reference
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

        // Validate and format allowed fields using Baby.validateData
        const allowedFields = ['name', 'dob'];
        const filteredFields = {};
        for (const key of allowedFields) {
            if (updateFields[key] !== undefined) filteredFields[key] = updateFields[key];
        }

        if (Object.keys(filteredFields).length === 0) {
            throw new Error("No valid fields provided for update");
        }

        // Use Baby.validateData for type normalization
        const formattedData = Baby.validateData(filteredFields, { partial: true });

        // Update Firestore
        await babyRef.update(formattedData);

        // Return updated Baby instance
        const updatedDoc = await babyRef.get();
        return new Baby(updatedDoc.id, updatedDoc.data());
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
            babyIDArr: admin.firestore.FieldValue.arrayRemove(babyRef),
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
                        babyIDArr: admin.firestore.FieldValue.arrayRemove(babyRef),
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
                babyProfiles.push(
                    new Baby(babySnap.id, babySnap.data())
                );
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

        return new Baby(snapshot.id, snapshot.data());
    }
}

module.exports = BabyService;