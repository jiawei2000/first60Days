// const db = require('../config/database');
// const bcrypt = require('bcryptjs');
// const jwt = require('jsonwebtoken');
// const { Timestamp, FieldValue } = require('firebase-admin/firestore');
// const JWT_SECRET = process.env.JWT_SECRET || 'no_jwt_in_env';
const UserService = require('../services/userService');

const userController = {
    async registerNew(req, res) {
        // ... your register new user logic here
        try {
            const { user, permission } = await UserService.registerNew(req.body);
            res.status(201).json({
                user,
                permission
            });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async registerSub(req, res) {
        // ... sub-account registration logic
        try {
            const currentUserId = req.user.id; // from JWT
            const { email, password, phoneNo, username, babyIDArr } = req.body;

            const result = await UserService.registerSub({
                currentUserId,
                email,
                password,
                phoneNo,
                username,
                babyIDArr
            });

            res.status(201).json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async login(req, res) {
        // ... login logic, return token
        try {
            const { token, user, permission } = await UserService.login(req.body);
            res.json({ token, user, permission });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async updatePassword(req, res) {
        // ... update password logic
        try {
            const userId = req.user.id; // from JWT
            const { newPassword } = req.body;

            const result = await UserService.updatePassword(userId, newPassword);

            res.status(200).json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async deleteUser(req, res) {
        // ... delete user (soft delete)
        try {
            const userId = req.user.id; // from JWT

            const result = await UserService.deleteUser(userId);

            res.status(200).json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    }
};

module.exports = userController;
