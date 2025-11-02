const db = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Timestamp } = require('firebase-admin/firestore');
const admin = require("firebase-admin");
const User = require('../models/User');
const Permission = require('../models/Permission');

const { JWT_SECRET } = require('../middleware/authMiddleware');

class UserService {
    //this register new user method will only be used by dev. needs to be removed afterwatds 
    static async registerNew({ email, password, phoneNo, username, name }) {
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
                relation: "Parent", // default relation for main account
                fcmTokens: [],
                name,
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

        // Check if user exists
        if (snapshot.empty) {
            throw new Error('No user with that username');
        }

        const userDoc = snapshot.docs[0];
        const user = User.fromFirestore(userDoc);

        // Check if user is deleted
        if (user.deletedAt) {
            throw new Error('User account is deleted');
        }

        // Validate password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            throw new Error('Invalid password');
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
            { id: user.id, username: user.username, role:'user' },
            JWT_SECRET,
            { expiresIn: '15m' }
        );

        return { token, user, permission };
    }

    static async registerSub({ currentUserId, username, password, phoneNo, relation, babyIDArr, name }) {
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

        // Check if username exists
        const usernameSnapshot = await usersRef.where('username', '==', username).get();
        if (!usernameSnapshot.empty) {
            throw new Error('Username already exists');
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        // Convert baby IDs to references
        const babyRefs = (babyIDArr || []).map(id => db.collection('babies').doc(id));

        // Transaction for atomic writes
        return await db.runTransaction(async (t) => {
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
                password: hashedPassword,
                phoneNo,
                username,
                createdAt: Timestamp.now(),
                lastLoginAt: null,
                deletedAt: null,
                permissionID: subPermissionRef,
                relation: relation,
                fcmTokens: [], 
                name
            });
            t.set(subUserRef, subUser.toFirestore());

            // Update main permission with new sub user
            t.update(mainPermissionDoc.ref, {
                subAccArr: admin.firestore.FieldValue.arrayUnion(subUserRef)
            });

            return { subUser, subPermission };
        });
        // return { subUser, subPermission };
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

    static async getAllSubUsers(userId) {
        // Get main user's permission
        const userSnap = await db.collection('users').doc(userId).get();

        if (!userSnap.exists) {
            throw new Error("User not found");
        }

        //get main user permission 
        const permissionRef = userSnap.data().permissionID;
        if (!permissionRef) {
            throw new Error("Main user's permission not found");
        }

        const permissionSnap = await permissionRef.get();
        if (!permissionSnap.exists) {
            throw new Error("Main user's permission not found");
        }
        
        //get an array of sub user reference 
        const { subAccArr } = permissionSnap.data(); // array of sub-user references
        let retSubAccArr = [] //return an array of user (sub) object 
        for (const subUserRef of subAccArr) {
            // Get sub-user's permission doc
            let subUserSnap = await subUserRef.get()
            retSubAccArr.push(User.fromFirestore(subUserSnap))  
        }
        return retSubAccArr
    }

    static async getMainUser(subUserId){
        const subUserDoc = await db.collection('users').doc(subUserId).get();

        if (!subUserDoc.exists) {
            throw new Error('Sub-user not found');
        }

        const subUser = User.fromFirestore(subUserDoc);

        const permissionDoc = await subUser.permissionID.get();
        if (!permissionDoc.exists) {
            throw new Error('Permission document not found');
        }
        
        const permission = Permission.fromFirestore(permissionDoc);

        const babyRefs = permission.babyIDArr || [];
        if (babyRefs.length === 0) {
            throw new Error('No babies linked to this sub account. Cannot determine main user.');
        }

        let mainPermSnap = null;

        for (const babyRef of babyRefs) {
            const mainPermQuery = await db.collection('permissions')
                .where('permissionType', '==', 'main')
                .where('babyIDArr', 'array-contains', babyRef)
                .get();

            if (!mainPermQuery.empty) {
                // take the first match
                mainPermSnap = mainPermQuery.docs[0];
                break;
            }
        }

        if (!mainPermSnap) {
            throw new Error('No matching main permission found for this sub-user');
        }

        const mainAccQuery = await db.collection('users').where('permissionID', '==', mainPermSnap.ref).get();

        if (mainAccQuery.empty) {
            throw new Error('Main user not found for main permission');
        }

        const mainUser = User.fromFirestore(mainAccQuery.docs[0]);

        return mainUser;
    }

    static async updateUsername(userId, newUsername) {
        const userDoc = await db.collection('users').doc(userId).get();

        if (!userDoc.exists) {
            throw new Error('User not found');
        }

        const user = User.fromFirestore(userDoc);

        // const hashedPassword = await bcrypt.hash(newPassword, 10);

        await db.collection('users').doc(userId).update({
            username: newUsername
        });

        return {
            message: 'Username updated successfully',
            userId: user.id
        };
    }
    
}

module.exports = UserService;
