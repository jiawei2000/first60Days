const express = require('express')
const router = express.Router()
const statisticsController = require('../controllers/statisticsController')
const { authenticateToken } = require('../middleware/authMiddleware');

// protected

//get ageGroupStatistics record by Id
router.get('/ageGroup/:statisticId', authenticateToken,statisticsController.getAgeGroupStatisticsById);

//get all daily baby journal statistics of individual baby
router.get('/daily/baby/:babyId', authenticateToken, statisticsController.getDailyStatistics);

// get daily statistics by Id
router.get('/daily/:statisticId', authenticateToken, statisticsController.getDailyStatisticsById);

//get all weekly baby journal statistics of individual baby
router.get('/weekly/baby/:babyId', authenticateToken, statisticsController.getWeeklyStatistics);

//get weekly statistics by Id
router.get('/weekly/:statisticId', authenticateToken, statisticsController.getWeeklyStatisticsById);

//get StatisticsbyGender record by Id 
router.get('/gender/:statisticId', authenticateToken, statisticsController.getStatisticsByGenderById);

// get all ageGroupStatistics records
router.get('/ageGroup', authenticateToken, statisticsController.getAllAgeGroupStatistics);

// get all StatisticsbyGender records
router.get('/gender', authenticateToken, statisticsController.getAllGenderStatistics);

// recompute and store daily statistics by statisticId
router.post('/recompute/daily/:statisticId', statisticsController.recomputeDailyStatisticsById);

module.exports = router
