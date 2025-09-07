const db = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Timestamp, FieldValue } = require('firebase-admin/firestore');
const JWT_SECRET = process.env.JWT_SECRET || 'no_jwt_in_env';
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
    },

    async login(req, res) {
        // ... login logic, return token
    },

    async updatePassword(req, res) {
        // ... update password logic
    },

    async deleteUser(req, res) {
        // ... delete user (soft delete)
    }
};

module.exports = userController;
