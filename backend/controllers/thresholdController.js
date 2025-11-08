const ThresholdService = require('../services/thresholdService');

const thresholdController = {
    async createDailyThreshold(req, res) {
        try {
            const thresholdData = req.body;
            const result = await ThresholdService.createDailyThreshold(thresholdData);
            res.status(201).json(result);
        } catch (error) {
            console.error('Error creating daily threshold:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },

    async createWeeklyThreshold(req, res) {
        try {
            const thresholdData = req.body;
            const result = await ThresholdService.createWeeklyThreshold(thresholdData);
            res.status(201).json(result);
        } catch (error) {
            console.error('Error creating weekly threshold:', error);
            res.status(500).json({ error: error.message || 'Internal server error' });
        }
    },

    //get all daily threshold settings
    async getAllDailyThresholds(req, res) {
        try {
            const thresholds = await ThresholdService.getAllDailyThresholds();
            res.status(200).json(thresholds);
        } catch (error) {
            console.error('Error fetching daily thresholds:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },

    //get all weekly threshold settings
    async getAllWeeklyThresholds(req, res) {
        try {
            const thresholds = await ThresholdService.getAllWeeklyThresholds();
            res.status(200).json(thresholds);
        } catch (error) {
            console.error('Error fetching weekly thresholds:', error);
            res.status(500).json({ error: error.message || 'Internal server error' });
        }
    },

    //edit daily threshold settings
    async updateDailyThreshold(req, res) {
        try {
            const { id } = req.params;
            const thresholdData = req.body;
            const result = await ThresholdService.updateDailyThreshold(id, thresholdData);
            res.status(200).json(result);
        } catch (error) {
            console.error('Error updating daily threshold:', error);
            res.status(500).json({ error: error.message || 'Internal server error' });
        }
    },

    //edit weekly threshold settings
    async updateWeeklyThreshold(req, res) {
        try {
            const { id } = req.params;
            const thresholdData = req.body;
            const result = await ThresholdService.updateWeeklyThreshold(id, thresholdData);
            res.status(200).json(result);
        } catch (error) {
            console.error('Error updating weekly threshold:', error);
            res.status(500).json({ error: error.message || 'Internal server error' });
        }
    },

    //evaluate daily statistics of a baby against threshold settings
    async evaluateDailyStatisticsAgainstThresholds(req, res) {
        try {
            const { dailyStatisticsId } = req.params;
            const result = await ThresholdService.evaluateDailyStatisticsAgainstThresholds(dailyStatisticsId);
            res.status(200).json(result);
        } catch (error) {
            console.error('Error evaluating daily statistics:', error);
            res.status(500).json({ error: error.message || 'Internal server error' });
        }
    },

    //evaluate weekly statistics of a baby against threshold settings
    async evaluateWeeklyStatisticsAgainstThresholds(req, res) {
        try {
            const { weeklyStatisticsId } = req.params;
            const result = await ThresholdService.evaluateWeeklyStatisticsAgainstThresholds(weeklyStatisticsId);
            res.status(200).json(result);
        } catch (error) {
            console.error('Error evaluating weekly statistics:', error);
            res.status(500).json({ error: error.message || 'Internal server error' });
        }
    }
};

module.exports = thresholdController;
