const express = require('express');
const db = require('../database');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const router = express.Router();
const { Timestamp, FieldValue } = require('firebase-admin/firestore');


const JWT_SECRET = process.env.JWT_SECRET || 'no_jwt_in_env';

// Verify JWT
function authenticateToken(req, res, next) {
	const authHeader = req.headers['authorization'];
	const token = authHeader && authHeader.split(' ')[1];
	if (process.env.SKIP_AUTH === "true") {
		console.log("Auth skipped in testing mode");
		return next();
	}
	
	if (!token) {
		return res.status(401).json({ error: 'No token provided' });
	}
	jwt.verify(token, JWT_SECRET, (err, user) => {
		if (err) {
			return res.status(403).json({ error: 'Invalid token' });
		}
		req.user = user;
		next();
	});
}

// Register new account, done by Trainers
router.post('/users/registerNew', async (req, res) => {
    const { email, password, phoneNo, username } = req.body;

    try {
        const usersRef = db.collection('users');

        // Check if email exists
        const snapshot = await usersRef.where('email', '==', email).get();
        if (!snapshot.empty) {
            return res.status(400).json({ error: 'User already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const result = await db.runTransaction(async (t) => {
            // Create user document
            const userRef = usersRef.doc();

            // Create permissions document
            const permissionRef = db.collection("permissions").doc();
            const permissionData = {
                userID: userRef,
                babyIDArr: [],
                permissionType: "main",
                createdAt: Timestamp.now(),
                deletedAt: null,
                subAccArr: []
            };
            t.set(permissionRef, permissionData);

            const userData = {
                createdAt: Timestamp.now(),
                deletedAt: null,
                email,
                lastLoginAt: null,
                password: hashedPassword,
                phoneNo,
                username,
                permissionID: permissionRef
            };
            t.set(userRef, userData);

            return { id: userRef.id, ...userData, permissions: permissionData };
        });
        res.status(201).json(result);
    } 

    catch (error) {
        res.status(400).json({ error: error.message });
    }
});

router.post('/users/registerSub', authenticateToken, async (req, res) => {
    const { email, password, phoneNo, username, babyIDArr } = req.body;

    try {
        const currentUserId = req.user.id;

        // Get current user's permission
        const userDoc = await db.collection("users").doc(currentUserId).get();
        const permissionRef = userDoc.data().permissionID;
        const permissionDoc = await permissionRef.get();

        if (!permissionDoc.exists || permissionDoc.data().permissionType !== "main") {
            return res.status(403).json({ error: 'Only users with "main" permission can create sub accounts' });
        }

        const mainPermissionRef = permissionDoc.ref;

        // Check email not taken
        const usersRef = db.collection('users');
        const snapshot = await usersRef.where('email', '==', email).get();
        if (!snapshot.empty) {
            return res.status(400).json({ error: 'User already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        // Convert baby IDs into references
        let babyRefs = null;
        if (babyIDArr) {
            const ids = Array.isArray(babyIDArr) ? babyIDArr : [babyIDArr];
            babyRefs = ids.map(id => db.collection('babies').doc(id));
        }

        const result = await db.runTransaction(async (t) => {
            // Create sub user
            const userRef = usersRef.doc();

            // Create permission for sub user
            const permissionRef = db.collection("permissions").doc();
            const permissionData = {
                userID: userRef,
                babyIDArr: babyRefs,
                permissionType: "sub",
                createdAt: Timestamp.now(),
                deletedAt: null,
                subAccArr: [],
            };
            t.set(permissionRef, permissionData);

            const userData = {
                createdAt: Timestamp.now(),
                deletedAt: null,
                email,
                lastLoginAt: null,
                password: hashedPassword,
                phoneNo,
                username,
                permissionID: permissionRef
            };
            t.set(userRef, userData);

            // Update main user's permission with new sub
            t.update(mainPermissionRef, {
                subAccArr: FieldValue.arrayUnion(userRef)
            });

            return { id: userRef.id, ...userData, permissions: permissionData };
        });
        res.status(201).json(result);
    } 
    
    catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Login
router.post('/users/login', async (req, res) => {
	const { email, password } = req.body;
	try {
		const usersRef = db.collection('users');
		const snapshot = await usersRef.where('email', '==', email).get();
		if (snapshot.empty) {
			return res.status(400).json({ error: 'Invalid credentials' });
		}
		const userDoc = snapshot.docs[0];
		const user = userDoc.data();
		const isMatch = await bcrypt.compare(password, user.password);
		if (!isMatch) {
			return res.status(400).json({ error: 'Invalid credentials' });
		}

		// Update lastLoginAt
		await usersRef.doc(userDoc.id).update({ lastLoginAt: Timestamp.now() });

		const token = jwt.sign({ id: userDoc.id, email: user.email }, JWT_SECRET, { expiresIn: '1d' });
		res.json({ token });
	} 
	catch (error) {
		res.status(400).json({ error: error.message });
	}
});


// Update password
router.put('/users/updatePassword', authenticateToken, async (req, res) => {
	const userId = req.user.id;
	const { newPassword } = req.body;
	try {
		const usersRef = db.collection('users').doc(userId);
		const hashedPassword = await bcrypt.hash(newPassword, 10);
		await usersRef.update({ password: hashedPassword });
		res.json({ message: 'Password updated' });
	} 
	catch (error) {
		res.status(400).json({ error: error.message });
	}
});

// Delete user
router.delete('/users/delete', authenticateToken, async (req, res) => {
	const userId = req.user.id;
	try {
		const usersRef = db.collection('users').doc(userId);

		await usersRef.update({
			deletedAt: Timestamp.now()
		});

		res.json({ message: 'User deleted' });
	} 
	catch (error) {
		res.status(400).json({ error: error.message });
	}
});


module.exports = {
    router,
    authenticateToken
};