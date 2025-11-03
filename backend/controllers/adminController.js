const AdminService = require('../services/adminService');

const adminController = {
    async registerNew(req, res) {
        // ... your register new admin logic here
        try {
            const { admin } = await AdminService.registerNew(req.body);
            res.status(201).json({
                admin
            });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async login(req, res) {
        try {
            const { token, admin } = await AdminService.login(req.body);
            res.json({ token, admin });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async registerTrainer(req, res) {
        try {
            const adminId = req.user.id; // from JWT
            const { trainer } = await AdminService.registerTrainer(adminId, req.body);
            res.status(201).json({ trainer });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async registerUser(req, res) {
        try {
            const adminId = req.user.id; // from JWT
            const { user } = await AdminService.registerUser(adminId, req.body);
            res.status(201).json({ user });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getAllTrainers(req, res) {
        try {
            const trainers = await AdminService.getAllTrainers();
            res.json({ trainers });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getAllUsers(req, res) {
        try {
            const users = await AdminService.getAllUsers();
            res.json({ users });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async updateUserTrainer(req, res) {
        try {
            const { userId } = req.params;
            const { trainerId } = req.body;
            const result = await AdminService.updateUserTrainer(userId, trainerId);
            res.json({ success: result.success, message: result.message, updatedFields: result.updatedFields });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getUserById(req, res) {
        try {
            const { userId } = req.params;
            const user = await AdminService.getUserById(userId);
            res.json({ user });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getTrainerById(req, res) {
        try {
            const { trainerId } = req.params;
            const trainer = await AdminService.getTrainerById(trainerId);
            res.json({ trainer });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async editUserById(req, res) {
        try {
            const { userId } = req.params;
            const updatedData = req.body;
            const user = await AdminService.editUserById(userId, updatedData);
            res.json({ user });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async editAdminProfile(req, res) {
        try {
            const adminId = req.user.id; // from JWT
            const updatedData = req.body;
            const admin = await AdminService.editAdminProfile(adminId, updatedData);
            res.json({ admin });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },
}

module.exports = adminController;