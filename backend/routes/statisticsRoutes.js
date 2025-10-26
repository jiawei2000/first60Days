const express = require('express')
const router = express.Router()
const statisticsController = require('../controllers/statisticsController')
const { authenticateToken } = require('../middleware/authMiddleware');

// protected

//daily baby journal statistics of individual baby  
router.get('/daily/:babyId', authenticateToken, statisticsController.getDailyStatistics);

//weekly baby journal statistics of indiividual baby 

