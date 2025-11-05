const StatisticsService = require('../services/statisticsService');

class StatisticsController {
    async getDailyStatistics(req, res) {
        const { babyId } = req.params;
        try {
            const statistics = await StatisticsService.getDailyStatistics(babyId);
            res.json({
                success: true,
                message: 'Daily statistics retrieved successfully',
                data: { statistics: statistics }
            });
        } catch (error) {
            console.error('Error fetching daily statistics:', error);
            res.status(500).json({
                "success": false,
                "message": "Failed to retrieve baby statistics",
                "error": error.message
            });
            // res.status(500).json({ error: 'Internal server error' });
        }
    }

    async getDailyStatisticsById(req, res) {
        const { statisticId } = req.params;
        try {
            const statistic = await StatisticsService.getDailyStatisticsById(statisticId);
            res.json({
                success: true,
                message: 'Daily statistics retrieved successfully',
                data: { statistic: statistic }
            });
        } catch (error) {
            console.error('Error fetching daily statistics by ID:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to retrieve daily statistic by ID',
                error: error.message
            });
        }
    }

    async getWeeklyStatistics(req, res) {
        const { babyId } = req.params;
        try {
            const statistics = await StatisticsService.getWeeklyStatistics(babyId);
            res.json({
                success: true,
                message: 'Weekly statistics retrieved successfully',
                data: { statistics: statistics }
            });
        } catch (error) {
            console.error('Error fetching weekly statistics:', error);
            res.status(500).json({
                "success": false,
                "message": "Failed to retrieve baby weekly statistics",
                "error": error.message
            });
        }
    }
    async getWeeklyStatisticsById(req, res) {
        const { statisticId } = req.params;
        try {
            const statistic = await StatisticsService.getWeeklyStatisticsById(statisticId);
            res.json({
                success: true,
                message: 'Weekly statistics retrieved successfully',
                data: { statistic: statistic }
            });
        } catch (error) {
            console.error('Error fetching weekly statistics by ID:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to retrieve weekly statistic by ID',
                error: error.message
            });
        }
    }

    async getAllGenderStatistics(req, res) {
        try {
            const statistics = await StatisticsService.getAllGenderStatistics();
            res.json({
                success: true,
                message: 'Gender statistics retrieved successfully',
                data: { statistics: statistics }
            });
        } catch (error) {
            console.error('Error fetching gender statistics:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to retrieve gender statistics',
                error: error.message
            });
        }
    }

    async getStatisticsByGenderById(req, res) {
        const { statisticId } = req.params;
        try {
            const statistic = await StatisticsService.getStatisticsByGenderById(statisticId);
            res.json({
                success: true,
                message: 'Gender statistics retrieved successfully',
                data: { statistic: statistic }
            });
        } catch (error) {
            console.error('Error fetching gender statistics by ID:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to retrieve gender statistic by ID',
                error: error.message
            });
        }
    }
    async getAllAgeGroupStatistics(req, res) {
        try {
            const statistics = await StatisticsService.getAllAgeGroupStatistics();
            res.json({
                success: true,
                message: 'Age group statistics retrieved successfully',
                data: { statistics: statistics }
            });
        } catch (error) {
            console.error('Error fetching age group statistics:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to retrieve age group statistics',
                error: error.message
            });
        }
    }

    async getAgeGroupStatisticsById(req, res) {
        const { statisticId } = req.params;
        try {
            const statistic = await StatisticsService.getAgeGroupStatisticsById(statisticId);
            res.json({
                success: true,
                message: 'Age group statistics retrieved successfully',
                data: { statistic: statistic }
            });
        } catch (error) {
            console.error('Error fetching age group statistics by ID:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to retrieve age group statistic by ID',
                error: error.message
            });
        }
    }

    async recomputeDailyStatisticsById(req, res) {
        const { statisticId } = req.params;
        try {
            await StatisticsService.recomputeDailyStatistics(statisticId);
            res.json({
                success: true,
                message: 'Daily statistics recomputed successfully'
            });
        } catch (error) {
            console.error('Error recomputing daily statistics:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to recompute daily statistics',
                error: error.message
            });
        }
    }

    async createAgeGroupStatistics(req, res) {
        try {
            const result = await StatisticsService.createAgeGroupStatistics();
            res.json({
                success: true,
                message: 'Age group statistics created successfully',
                data: { statistic: result }
            });
        } catch (error) {
            console.error('Error creating age group statistics:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to create age group statistics',
                error: error.message
            });
        }
    }

    async createStatisticsByGender(req, res) {
        try {
            const result = await StatisticsService.createStatisticsByGender();
            res.json({
                success: true,
                message: 'Statistics by gender created successfully',
                data: { statistic: result }
            });
        } catch (error) {
            console.error('Error creating statistics by gender:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to create statistics by gender',
                error: error.message
            });
        }
    }

}

module.exports = new StatisticsController();
