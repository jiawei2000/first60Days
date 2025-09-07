const db = require('../config/database');
const bcrypt = require('bcryptjs');
const { Timestamp } = require('firebase-admin/firestore');
const User = require('../models/User');
const Permission = require('../models/Permission');

class UserService {
    static async registerNew({ email, password, phoneNo, username }) {
        const usersRef = db.collection('users');

        // Check if email exists
        const snapshot = await usersRef.where('email', '==', email).get();
        if (!snapshot.empty) {
            throw new Error('User already exists');
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
                permissionID: permissionRef
            });

            // create permission model
            const permission = new Permission(permissionRef.id, {
                userID: userRef,
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
}

module.exports = UserService;
