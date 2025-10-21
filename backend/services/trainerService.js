const db = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Trainer = require('../models/Trainer');

const { JWT_SECRET } = require('../middleware/authMiddleware');

class TrainerService {
    static async registerNew({ email, password, username }) {
        const trainersRef = db.collection('trainers');

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
                });
        await trainerRef.set(trainer.toFirestore());
        return { trainer };
    }

    static async login({ username, password }) {
        const trainersRef = db.collection('trainers');
        const snapshot = await trainersRef.where('username', '==', username).get();

        // Check if user exists
        if (snapshot.empty) {
            throw new Error('No user with that username');
        }

        const trainerDoc = snapshot.docs[0];
        const trainer = Trainer.fromFirestore(trainerDoc);

        // Validate password
        const isMatch = await bcrypt.compare(password, trainer.password);
        if (!isMatch) {
            throw new Error('Invalid password');
        }

        // Issue JWT
        const token = jwt.sign(
            { id: trainer.id, username: trainer.username, role:'trainer' },
            JWT_SECRET,
            { expiresIn: '15m' }
        );

        return { token, trainer };
    }

    static async updatePassword(trainerId, newPassword) {
        const trainerDoc = await db.collection('trainers').doc(trainerId).get();

        if (!trainerDoc.exists) {
            throw new Error('Trainer not found');
        }

        const trainer = Trainer.fromFirestore(trainerDoc);

        const hashedPassword = await bcrypt.hash(newPassword, 10);

        await db.collection('trainers').doc(trainerId).update({
            password: hashedPassword
        });

        // Update the trainer instance (optional)
        trainer.password = hashedPassword;

        return {
            message: 'Password updated successfully',
            trainerId: trainer.id
        };
    }    
}

module.exports = TrainerService;