const TrainerService = require('../services/trainerService');

const trainerController = {
    // async registerNew(req, res) {
    //     // ... your register new user logic here
    //     try {
    //         const { trainer } = await TrainerService.registerNew(req.body);
    //         res.status(201).json({
    //             trainer
    //         });
    //     } catch (error) {
    //         res.status(400).json({ error: error.message });
    //     }
    // },

    async login(req, res) {
        // ... login logic, return token
        try {
            const { token, trainer } = await TrainerService.login(req.body);
            res.json({ token, trainer });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async updatePassword(req, res) {
        // ... update password logic
        try {
            const userId = req.user.id; // from JWT
            const { newPassword } = req.body;

            const result = await TrainerService.updatePassword(userId, newPassword);

            res.status(200).json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getManagedUsers(req, res) {
        try {
            const trainerId = req.user.id; // from JWT
            const users = await TrainerService.getManagedUsers(trainerId);
            res.json({ users });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getManagedUserBabies(req, res) {
        try {
            const { userId } = req.params;
            const trainerId = req.user.id; // from JWT
            const babies = await TrainerService.getManagedUserBabies(userId, trainerId);
            res.json({ babies });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    }

};

module.exports = trainerController;