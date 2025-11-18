const express = require('express')
const router = express.Router()
const ImportedStatsController = require('../controllers/importedStatsController');

// Route to compute statistics for imported baby journal entries
router.post('/compute/:babyId', ImportedStatsController.computeStatisticsForImportedEntries);

module.exports = router;