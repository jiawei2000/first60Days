const express = require('express')
const router = express.Router()
const ImportedStatsController = require('../controllers/importedStatsController');

// Route to compute statistics for imported baby journal entries
router.post('/computeDaily/:babyId', ImportedStatsController.computeStatisticsForImportedEntries);
router.post('/computeWeekly/:babyId', ImportedStatsController.computeWeeklyStatistics);

module.exports = router;