const StatisticsService = require('../services/statisticsService');

class StatisticsController {
    async getDailyStatistics(req, res) {
        const { babyId } = req.params;
        const { date } = req.body
        try {
            const statistics = await StatisticsService.getDailyStatistics(babyId, date);
            res.json(statistics);
        } catch (error) {
            console.error('Error fetching daily statistics:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    // async getWeeklyStatistics(req, res) {
    //     const { babyId } = req.params;
    //     try {
    //         const statistics = await StatisticsService.getWeeklyStatistics(babyId);
    //         res.json(statistics);
    //     } catch (error) {
    //         console.error('Error fetching weekly statistics:', error);
    //         res.status(500).json({ error: 'Internal server error' });
    //     }
    // }

    
}

module.exports = new StatisticsController();
