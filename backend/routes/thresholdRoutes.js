const express = require('express');
const router = express.Router();
const { authenticateToken, authorizeRoles } = require('../middleware/authMiddleware');
const thresholdController = require('../controllers/thresholdController');

//evaluate daily statistics of a baby against threshold settings
router.post('/evaluate/daily/:dailyStatisticsId', thresholdController.evaluateDailyStatisticsAgainstThresholds);
//evaluate weekly statistics of a baby against threshold settings
router.post('/evaluate/weekly/:weeklyStatisticsId', thresholdController.evaluateWeeklyStatisticsAgainstThresholds);

//create new daily threshold settings (1 time setup)
router.post('/daily', thresholdController.createDailyThreshold);
router.post('/weekly', thresholdController.createWeeklyThreshold);

//get all daily threshold settings
router.get('/daily', thresholdController.getAllDailyThresholds);
router.get('/weekly', thresholdController.getAllWeeklyThresholds);

//edit daily threshold settings
router.put('/daily/:id', thresholdController.updateDailyThreshold);
router.put('/weekly/:id', thresholdController.updateWeeklyThreshold);


module.exports = router;
