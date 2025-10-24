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

    async assignTrainerToUser(req, res) {
        try {
            const { userId, trainerId } = req.body;
            await AdminService.assignTrainerToUser(userId, trainerId);
            res.status(204).send();
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getBabyJournalStats(req, res) {
        try {
            const stats = await AdminService.getBabyJournalStats();
            res.json({ stats });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    }
}

module.exports = adminController;