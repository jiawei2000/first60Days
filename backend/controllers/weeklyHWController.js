const WeeklyHeightWeightService = require('../services/weeklyHWService');

const WeeklyHeightWeightController  = {
    async newWeeklyHW (req, res) {
        try {
            const babyID = req.params.babyID;
            const { heightWeight } = await WeeklyHeightWeightService.newWeeklyHW(babyID, req.body);
            res.status(201).json({ heightWeight });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },
    async getWeeklyHWByBabyID(req, res) {
        try {
            const babyID = req.params.babyID;
            const { heightWeights } = await WeeklyHeightWeightService.getWeeklyHW(babyID);
            res.status(200).json({ heightWeights });
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    }
};

module.exports = WeeklyHeightWeightController;