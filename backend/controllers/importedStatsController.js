const ImportedStatsService = require('../services/importedStatsService');

const importedStatsController = {
    async computeStatisticsForImportedEntries(req, res) {
        try {
            const { babyId } = req.params;
            const result = await ImportedStatsService.computeStatisticsForImportedEntries(babyId);
            res.status(200).json(result);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    },
    
    async computeWeeklyStatistics(req, res) {
        try {
            const { babyId } = req.params;
            const result = await ImportedStatsService.computeWeeklyStatistics(babyId);
            res.status(200).json(result);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
};

module.exports = importedStatsController;