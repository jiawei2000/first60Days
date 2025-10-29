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
            const { username, password, phoneNo, relation, babyIDArr, name } = req.body;

            const result = await UserService.registerSub({
                currentUserId,
                username,
                password,
                phoneNo,
                relation,
                babyIDArr,
                name
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

    // async deleteUser(req, res) {
    //     // ... delete user (soft delete)
    //     try {
    //         const userId = req.user.id; // from JWT

    //         const result = await UserService.deleteUser(userId);

    //         res.status(200).json(result);
    //     } catch (error) {
    //         res.status(400).json({ error: error.message });
    //     }
    // },
    async deleteUser(req, res) {
        try {
            // ID from URL parameter
            const { userId } = req.params;
            const requesterId = req.user.id;
            console.log(`Trainer ${requesterId} requested deletion of user ${userId}`);

            const result = await UserService.deleteUser(userId); // delete target user

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
    },

    async getSubAccounts(req, res) {
        try {
            const userId = req.user.id; // from JWT
            const result = await UserService.getAllSubUsers(userId);
            //return array of sub accounts 
            res.status(200).json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getMainAccount(req, res) {
        try {
            const userId = req.user.id; // from JWT
            const result = await UserService.getMainUser(userId);
            //return array of sub accounts 
            res.status(200).json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async updateUsername(req, res) {
        // ... update password logic
        try {
            const { userId } = req.params;
            const { newUsername } = req.body;

            const result = await UserService.updateUsername(userId, newUsername);

            res.status(200).json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getAllUsers(req, res) {
        try {
            const result = await UserService.getAllUsers();

            res.status(200).json(result);
        } catch (error) {
            res.status(500).json({
                message: "Failed to retrieve users",
                error: error.message,
            });
        }
    }
};

module.exports = userController;
