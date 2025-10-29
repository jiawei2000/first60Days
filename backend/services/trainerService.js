const db = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Trainer = require('../models/Trainer');
const User = require('../models/User');
const Baby = require('../models/Baby');
const { JWT_SECRET } = require('../middleware/authMiddleware');

class TrainerService {
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

    static async getManagedUsers(trainerId) {
        const usersRef = db.collection('users');
        const trainerRef = db.collection('trainers').doc(trainerId);

        const snapshot = await usersRef.where('trainerID', '==', trainerRef).get();
        const users = [];

        snapshot.forEach(doc => {
            users.push(User.fromFirestore(doc));
        });
        return users;
    }

    static async getManagedUserBabies(userId, trainerId) {
        //check if user exist
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }

        // Check if the user is managed by the trainer
        // const trainerRef = db.collection('trainers').doc(trainerId);
        const trainerSnap = await db.collection('trainers').doc(trainerId).get();
        const userTrainerSnap = await userDoc.data().trainerID.get();
        if (userTrainerSnap.id !== trainerSnap.id) {
            throw new Error('Unauthorized access to user babies');
        }
        
        //Obtain permission reference to get baby profiles
        const permissionRef = userDoc.data().permissionID;
        if (!permissionRef) {
            throw new Error('Permission document does not exist for this user');
        }

        const permissionSnap = await permissionRef.get();
        if (!permissionSnap.exists) {
            throw new Error('Permission document does not exist');
        }
        // Get baby profile references
        const { babyIDArr } = permissionSnap.data();
        if (!babyIDArr || babyIDArr.length === 0) {
            return [];
        }

        const babies = [];
        for (const babyRef of babyIDArr) {
            const babySnap = await babyRef.get();
            if (babySnap.exists) {
                babies.push(Baby.fromFirestore(babySnap));
            }
        }
        return babies;
    }

}

module.exports = TrainerService;