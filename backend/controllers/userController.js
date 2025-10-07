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
            const { username, password, phoneNo, relation, babyIDArr } = req.body;

            const result = await UserService.registerSub({
                currentUserId,
                username,
                password,
                phoneNo,
                relation,
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
    },
    async getUserById(req, res) {
        // ... get user by Id
        try {
            // const userId = req.user.id; // from JWT
            const { userId } = req.params; 
            const result = await UserService.getUserById(userId);

            res.status(200).json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    }
};

module.exports = userController;
