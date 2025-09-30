const db = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Timestamp } = require('firebase-admin/firestore');
const admin = require("firebase-admin");
const User = require('../models/User');
const Permission = require('../models/Permission');

const { JWT_SECRET } = require('../middleware/authMiddleware');

class UserService {
    static async registerNew({ email, password, phoneNo, username }) {
        const usersRef = db.collection('users');

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
                fcmTokens: []
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

    static async login({ username, password, fcmToken }) {
        const usersRef = db.collection('users');
        const snapshot = await usersRef.where('username', '==', username).get();

        if (snapshot.empty) {
            throw new Error('Invalid credentials');
        }

        const userDoc = snapshot.docs[0];
        const user = User.fromFirestore(userDoc);

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            throw new Error('Invalid credentials');
        }

        // Update lastLoginAt
        await usersRef.doc(user.id).update({ lastLoginAt: Timestamp.now() });
        user.lastLoginAt = Timestamp.now();

        if (fcmToken) {
        await usersRef.doc(user.id).update({
            fcmTokens: admin.firestore.FieldValue.arrayUnion(fcmToken)
        });
            user.fcmTokens = [...(user.fcmTokens || []), fcmToken];
        }

        // Load permission object
        const permissionDoc = await user.permissionID.get();
        const permission = Permission.fromFirestore(permissionDoc);

        // Issue JWT
        const token = jwt.sign(
            { id: user.id, email: user.email },
            JWT_SECRET,
            { expiresIn: '1d' }
        );

        return { token, user, permission };
    }

    static async registerSub({ currentUserId, email, password, phoneNo, username, babyIDArr }) {
        const usersRef = db.collection('users');

        // Get current main user’s permission
        const mainUserDoc = await usersRef.doc(currentUserId).get();
        if (!mainUserDoc.exists) {
            throw new Error('Main user not found');
        }

        const mainUser = User.fromFirestore(mainUserDoc);
        const mainPermissionDoc = await mainUser.permissionID.get();
        const mainPermission = Permission.fromFirestore(mainPermissionDoc);

        if (mainPermission.permissionType !== "main") {
            throw new Error('Only users with "main" permission can create sub accounts');
        }

        // Ensure email not taken
        const snapshot = await usersRef.where('email', '==', email).get();
        if (!snapshot.empty) {
            throw new Error('User already exists');
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        // Convert baby IDs to references
        const babyRefs = (babyIDArr || []).map(id => db.collection('babies').doc(id));

        // Transaction for atomic writes
        const result = await db.runTransaction(async (t) => {
            const subUserRef = usersRef.doc();

            // Create sub permission
            const subPermissionRef = db.collection('permissions').doc();
            const subPermission = new Permission(subPermissionRef.id, {
                // userID: subUserRef,
                babyIDArr: babyRefs,
                permissionType: "sub",
                createdAt: Timestamp.now(),
                deletedAt: null,
                subAccArr: [],
            });
            t.set(subPermissionRef, subPermission.toFirestore());

            // Create sub user
            const subUser = new User(subUserRef.id, {
                email,
                password: hashedPassword,
                phoneNo,
                username,
                createdAt: Timestamp.now(),
                lastLoginAt: null,
                deletedAt: null,
                permissionID: subPermissionRef,
                fcmTokens: []
            });
            t.set(subUserRef, subUser.toFirestore());

            // Update main permission with new sub user
            t.update(mainPermissionDoc.ref, {
                subAccArr: admin.firestore.FieldValue.arrayUnion(subUserRef)
            });

            return { subUser, subPermission };
        });

        return {
            id: result.subUser.id,
            email: result.subUser.email,
            phoneNo: result.subUser.phoneNo,
            username: result.subUser.username,
            permission: result.subPermission
        };
    }

    static async updatePassword(userId, newPassword) {
        const userDoc = await db.collection('users').doc(userId).get();

        if (!userDoc.exists) {
            throw new Error('User not found');
        }

        const user = User.fromFirestore(userDoc);

        const hashedPassword = await bcrypt.hash(newPassword, 10);

        await db.collection('users').doc(userId).update({
            password: hashedPassword
        });

        // Update the user instance (optional)
        user.password = hashedPassword;

        return {
            message: 'Password updated successfully',
            userId: user.id
        };
    }

    //needs to be updated. 
    static async deleteUser(userId) {
        const userDoc = await db.collection('users').doc(userId).get();

        if (!userDoc.exists) {
            throw new Error('User not found');
        }

        const user = User.fromFirestore(userDoc);

        await db.collection('users').doc(userId).update({
            deletedAt: Timestamp.now()
        });

        // Optionally update the user instance
        user.deletedAt = Timestamp.now();

        return {
            message: 'User deleted successfully',
            userId: user.id
        };
    }

    static async getUserById(userId) {
        const userRef = db.collection('users').doc(userId)
        const userSnap = await userRef.get()

        //if usersnap don't exist, throw error 
        if (!userSnap.exists) {
            throw new Error('User not found');
        }

        return new User(userSnap.id, userSnap.data());
    }

    static async getAllUsers() {
        const usersRef = db.collection('users');
        const snapshot = await usersRef.get();

        if (snapshot.empty) {
            return [];
        }

        return snapshot.docs.map(doc => User.fromFirestore(doc));
    }
}

module.exports = UserService;
