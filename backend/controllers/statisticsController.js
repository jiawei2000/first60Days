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

}

module.exports = new StatisticsController();
