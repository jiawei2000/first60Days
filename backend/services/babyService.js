const db = require('../config/database');

const Baby = require('../models/Baby');

const { Timestamp } = require('firebase-admin/firestore');
const admin = require("firebase-admin");

class BabyService {
    static async newProfile(userId, { name, dob, expectedDueDate, term, weight, healthConditions, gender, height, vaccination, allergies }) {
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

        // Transaction to create baby and update permissions
        return await db.runTransaction(async (t) => {
            // Get user document
            const userRef = db.collection("users").doc(userId);
            const userSnap = await t.get(userRef);
            if (!userSnap.exists) throw new Error("User not found");

            const permissionRef = userSnap.data().permissionID;
            if (!permissionRef) throw new Error("Permission reference not found");

            // Create new Baby instance
            const babyRef = db.collection("babies").doc();
            const baby = new Baby(babyRef.id, {
                name,
                dob,
                expectedDueDate,
                createdAt: Timestamp.now(),
                deletedAt: null,
                term,
                weight,
                healthConditions,
                gender,
                height,
                vaccination,
                allergies
            });

            // Save baby in Firestore
            t.set(babyRef, baby.toFirestore());

            // Update permission doc with new baby reference
            t.update(permissionRef, {
                babyIDArr: admin.firestore.FieldValue.arrayUnion(babyRef),
            });

            return { babyId: babyRef.id, baby: baby.toFirestore() };
        });
    }

    static async editProfile(babyId, updateFields) {
        if (!babyId) {
            throw new Error("babyId is required");
        }

        const babyRef = db.collection("babies").doc(babyId);
        const babySnap = await babyRef.get();

        if (!babySnap.exists) {
            throw new Error("Baby not found");
        }

        const validFields = [
            "name",
            "dob",
            "expectedDueDate",
            "term",
            "weight",
            "healthConditions",
            "height",
            "gender",
            "vaccination",
            "allergies"
        ];

        const updateData = {};

        // Only include valid fields that are provided
        for (const key of validFields) {
            if (updateFields[key] !== undefined && updateFields[key] !== null) {
                // Convert date strings to Firestore Timestamp
                if (key === "dob" || key === "expectedDueDate") {
                    updateData[key] = Timestamp.fromDate(new Date(updateFields[key]));
                } else {
                    updateData[key] = updateFields[key];
                }
            }
        }

        if (Object.keys(updateData).length === 0) {
            throw new Error("No valid fields provided for update");
        }

        await babyRef.update({
            ...updateData
        });

        // const updatedSnap = await babyRef.get();
        return {
            babyId: babyId,
            message: "Baby profile updated successfully",
            updatedFields: updateData,
        };
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
                    Baby.fromFirestore(babySnap)
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

    static async getWeekNo(babyId) {
        const babyRef = db.collection("babies").doc(babyId);
        const snapshot = await babyRef.get();

        if (!snapshot.exists) {
            throw new Error("Baby profile not found");
        }
        const babyData = snapshot.data();
        const dob = babyData.dob?.toDate ? babyData.dob.toDate() : new Date(babyData.dob); // handle Firestore Timestamp or string

        if (!dob) {
            throw new Error("Date of birth not found in baby profile");
        }

        // Calculate the number of weeks since birth
        const today = new Date();
        const diffInMs = today - dob;
        const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24));

        // First 7 days = Week 1, so we use ceil
        const weekNo = Math.ceil(diffInDays / 7);

        return { weekNo };

    }

    static async getParentId(babyId) {
        const babyRef = db.collection("babies").doc(babyId);
        const snapshot = await babyRef.get();
        if (!snapshot.exists) {
            throw new Error("Baby profile not found");
        }
        
        const permissionQuery = await db.collection("permissions")
            .where("babyIDArr", "array-contains", babyRef)
            .limit(1)
            .get();

        if (permissionQuery.empty) {
            throw new Error("Permission document not found for this baby");
        }
        
        const permissionDoc = permSnap.docs[0];
        const permissionRef = permissionDoc.ref;

        const userSnap = await db.collection('users')
            .where('permissionRef', '==', permissionRef)
            .limit(1)
            .get();

        if (userSnap.empty) {
            throw new Error('No user linked to this permission document');
        }

        const parentId = userSnap.docs[0].id;

        return parentId;
    }
}

module.exports = BabyService;