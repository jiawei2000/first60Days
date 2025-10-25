const BabyService = require('../services/babyService');

const BabyController = {
    async newProfile(req, res) {
        const userId = req.user.id; //from JWT
        try {
            // const { name, dob, expectedDueDate, term, weight, healthConditions } = req.body;

            const { babyId, baby } = await BabyService.newProfile(userId, req.body);
    
            res.status(201).json({
                message: "Baby created and added to permissions",
                babyId,
                baby,
            });

        } catch (error) {
            console.error("Error in createBaby:", error.message);
            if (error.message === "User not found" || error.message === "Permission reference not found") {
                return res.status(404).json({ error: error.message });
            }
            if (error.message === "Name and DOB are required") {
                return res.status(400).json({ error: error.message });
            }
            res.status(500).json({ error: "Internal Server Error" });
        }
    },

    async editProfile(req, res) {
        try {
            const { babyId } = req.params;
            const  result = await BabyService.editProfile(babyId, req.body);

            res.status(200).json({
                message: result.message,
                babyId: result.babyId,
                updatedFields: result.updatedFields,
            });
        } catch (error) {
            console.error("Error in updateBaby:", error.message);
            if (error.message === "babyId is required" || error.message === "No valid fields provided for update") {
                return res.status(400).json({ error: error.message });
            }
            res.status(500).json({ error: "Internal Server Error" });
        }
    },

    async deleteProfile(req, res) {
        try {
            const userId = req.user.id;
            const { babyId } = req.params;
            const result = await BabyService.deleteProfile(userId, babyId);

            res.status(200).json(result);
        } catch (error) {
            console.error("Error in deleteBaby:", error.message);
            if (error.message.includes("not found") || error.message === "babyId is required") {
                return res.status(404).json({ error: error.message });
            }
            res.status(500).json({ error: "Internal Server Error" });
        }
    },

    async getProfiles(req, res) {
        try {
            const userId = req.user.id; // from JWT
            const babyProfiles = await BabyService.getProfiles(userId);
            res.status(200).json({ babyProfiles });
        } catch (error) {
            console.error("Error in getUserBabies:", error.message);
            if (error.message.includes("not found") || error.message.includes("does not exist")) {
                return res.status(404).json({ error: error.message });
            }
            res.status(500).json({ error: "Internal Server Error" });
        }

    },

    async getProfileById(req, res) {
        try {
            const { babyId } = req.params;
            const babyProfile = await BabyService.getProfileById(babyId);

            res.status(200).json(babyProfile);
        } catch (error) {
            console.error("Error in getBabyById:", error.message);
            if (error.message.includes("not found")) {
                return res.status(404).json({ error: error.message });
            }
            res.status(500).json({ error: "Internal Server Error" });
        }
    },

    async getWeekNo(req, res) {
        try {
            const { babyId } = req.params;

            if (!babyId) {
                return res.status(400).json({ error: "babyId is required" });
            }

            const result = await BabyService.getWeekNo(babyId);
            return res.status(200).json(result);
        } catch (error) {
            console.error("Error fetching week number:", error);
            return res.status(500).json({ error: error.message });
        }
    }
}

module.exports = BabyController;