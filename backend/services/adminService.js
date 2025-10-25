const db = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Timestamp } = require('firebase-admin/firestore');
const firebaseAdmin = require("firebase-admin");

const Admin = require('../models/Admin');
const Trainer = require('../models/Trainer');
const User = require('../models/User');
const Permission = require('../models/Permission');

const { JWT_SECRET } = require('../middleware/authMiddleware');

class adminService {
    static async registerNew({ username, email, password, name }) {
        const adminsRef = db.collection('admins');

        // Check if email exists
        const emailSnapshot = await adminsRef.where('email', '==', email).get();
        if (!emailSnapshot.empty) {
            throw new Error('Email already exists');
        }

        // Check if username exists
        const usernameSnapshot = await adminsRef.where('username', '==', username).get();
        if (!usernameSnapshot.empty) {
            throw new Error('Username already exists');
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const adminRef = adminsRef.doc();
        const admin = new Admin(adminRef.id, {
            email,
            password: hashedPassword,
            username,
            name,
            createdAt: Timestamp.now(),
            deletedAt: null,
            lastLoginAt: null,
        });

        await adminRef.set(admin.toFirestore());
        return { admin };
    }

    static async login({ username, password, fcmToken }) {
        const adminsRef = db.collection('admins');
        const snapshot = await adminsRef.where('username', '==', username).get();

        // Check if user exists
        if (snapshot.empty) {
            throw new Error('No admin with that username');
        }

        const adminDoc = snapshot.docs[0];
        const admin = Admin.fromFirestore(adminDoc);

        // Check if admin is deleted
        if (admin.deletedAt) {
            throw new Error('Admin account is deleted');
        }

        // Validate password
        const isMatch = await bcrypt.compare(password, admin.password);
        if (!isMatch) {
            throw new Error('Invalid password');
        }

        // Update lastLoginAt
        await adminsRef.doc(admin.id).update({ lastLoginAt: Timestamp.now() });
        admin.lastLoginAt = Timestamp.now();

        // Issue JWT
        const token = jwt.sign(
            { id: admin.id, username: admin.username, role: 'admin' },
            JWT_SECRET,
            { expiresIn: '15m' }
        );

        return { token, admin };
    }

    static async registerTrainer(adminId, { username, email, password, name }) {
        const trainersRef = db.collection('trainers');
        const adminRef = db.collection('admins').doc(adminId);
        // Check if email exists
        const emailSnapshot = await trainersRef.where('email', '==', email).get();
        if (!emailSnapshot.empty) {
            throw new Error('Email already exists');
        }

        // Check if username exists
        const usernameSnapshot = await trainersRef.where('username', '==', username).get();
        if (!usernameSnapshot.empty) {
            throw new Error('Username already exists');
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const trainerRef = trainersRef.doc();
        const trainer = new Trainer(trainerRef.id, {
            email,
            password: hashedPassword,
            username,
            name,
            createdAt: Timestamp.now(),
            deletedAt: null,
            lastLoginAt: null,
            createdByAdminID: adminRef,
        });
        await trainerRef.set(trainer.toFirestore());
        return { trainer };
    }

    static async registerUser(adminId, { trainerId, username, email, password, name, phoneNo, relation }) {
        const usersRef = db.collection('users');
        const adminRef = db.collection('admins').doc(adminId);
        const trainerRef = db.collection('trainers').doc(trainerId);
        // Check if email exists
        const emailSnapshot = await usersRef.where('email', '==', email).get();
        if (!emailSnapshot.empty) {
            throw new Error('Email already exists');
        }

        // Check if username exists
        const usernameSnapshot = await usersRef.where('username', '==', username).get();
        if (!usernameSnapshot.empty) {
            throw new Error('Username already exists');
        }

        //check if trainer exists
        const trainerDoc = await trainerRef.get();
        if (!trainerDoc.exists) {
            throw new Error('Trainer does not exist');
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        //  Transaction
        return await db.runTransaction(async (t) => {
            const userRef = usersRef.doc();
            const permissionRef = db.collection("permissions").doc();

            // create user model instance
            const user = new User(userRef.id, {
                email,
                password: hashedPassword,
                phoneNo,
                username,
                createdAt: Timestamp.now(),
                lastLoginAt: null,
                deletedAt: null,
                permissionID: permissionRef,
                relation: relation || "Parent",
                fcmTokens: [],
                name,
                trainerID: trainerRef,
                createdByAdminID: adminRef
            });

            // create permission model
            const permission = new Permission(permissionRef.id, {
                // userID: userRef,
                babyIDArr: [],
                permissionType: "main",
                createdAt: Timestamp.now(),
                deletedAt: null,
                subAccArr: []
            });

            t.set(permissionRef, permission.toFirestore());
            t.set(userRef, user.toFirestore());

            return { user, permission };
        });
    }

    static async getAllTrainers() {
        const trainersRef = db.collection('trainers');
        const snapshot = await trainersRef.where('deletedAt', '==', null).get();
        return snapshot.docs.map(doc => Trainer.fromFirestore(doc));
    }

    //get all users (main)
    static async getAllUsers() {
        const usersRef = db.collection('users');
        const snapshot = await usersRef.where('deletedAt', '==', null).get();
        //only users (main) created by admins will have createdByAdminID set
        const filtered = snapshot.docs
            .map(doc => User.fromFirestore(doc))
            .filter(user => user.createdByAdminID != null);
        return filtered;
    }

    //to be continued...
    static async updateUserTrainer(userId, trainerId) {
        const userRef = db.collection('users').doc(userId);
        //check if user exists
        const userDoc = await userRef.get();
        if (!userDoc.exists) {
            throw new Error('User does not exist');
        }

        const trainerRef = db.collection('trainers').doc(trainerId);
        //check if trainer exists
        const trainerDoc = await trainerRef.get();
        if (!trainerDoc.exists) {
            throw new Error('Trainer does not exist');
        }

        //update trainerID field with trainer reference
        const result = await userRef.update({ trainerID: trainerRef });
        if (result.writeTime == null) {
            throw new Error('Failed to update user trainer');
        }

        return { success: true , message: 'User trainer updated successfully', updatedFields: { trainerID: trainerId } };
    }
}


module.exports = adminService;