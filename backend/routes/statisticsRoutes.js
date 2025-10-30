const express = require('express')
const router = express.Router()
const statisticsController = require('../controllers/statisticsController')
const { authenticateToken } = require('../middleware/authMiddleware');

// protected

//get all daily baby journal statistics of individual baby
router.get('/daily/baby/:babyId', authenticateToken, statisticsController.getDailyStatistics);

// get daily statistics by Id
router.get('/daily/:statisticId', authenticateToken, statisticsController.getDailyStatisticsById);

//get all weekly baby journal statistics of individual baby
router.get('/weekly/baby/:babyId', statisticsController.getWeeklyStatistics);

//get weekly statistics by Id
router.get('/weekly/:statisticId', statisticsController.getWeeklyStatisticsById);

module.exports = router
