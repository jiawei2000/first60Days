const express = require('express');
const db = require('../database');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'no_jwt_in_env';

// Verify JWT
function authenticateToken(req, res, next) {
	const authHeader = req.headers['authorization'];
	const token = authHeader && authHeader.split(' ')[1];
	if (!token) return res.status(401).json({ error: 'No token provided' });
	jwt.verify(token, JWT_SECRET, (err, user) => {
		if (err) return res.status(403).json({ error: 'Invalid token' });
		req.user = user;
		next();
	});
}

// Register
router.post('/users/register', async (req, res) => {
	const { email, password } = req.body;
	try {
		const usersRef = db.collection('users');
        console.log(usersRef);
		const snapshot = await usersRef.where('email', '==', email).get();
		if (!snapshot.empty) {
			return res.status(400).json({ error: 'User already exists' });
		}
		const hashedPassword = await bcrypt.hash(password, 10);
		const userRef = await usersRef.add({ email, password: hashedPassword });
		res.status(201).json({ id: userRef.id, email });
	} catch (error) {
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
		const token = jwt.sign({ id: userDoc.id, email: user.email }, JWT_SECRET, { expiresIn: '1d' });
		res.json({ token });
	} catch (error) {
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
	} catch (error) {
		res.status(400).json({ error: error.message });
	}
});

// Delete user
router.delete('/users/delete', authenticateToken, async (req, res) => {
	const userId = req.user.id;
	try {
		await db.collection('users').doc(userId).delete();
		res.json({ message: 'User deleted' });
	} catch (error) {
		res.status(400).json({ error: error.message });
	}
});

module.exports = router;