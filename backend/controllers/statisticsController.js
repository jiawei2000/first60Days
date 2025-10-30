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
}

module.exports = new StatisticsController();
