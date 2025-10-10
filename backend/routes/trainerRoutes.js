const express = require('express');
const router = express.Router();
const trainerController = require('../controllers/trainerController');
const { authenticateToken } = require('../middleware/authMiddleware');

// Public routes
router.post('/', trainerController.registerNew);
router.post('/login', trainerController.login);

// Protected routes
router.put('/password', authenticateToken, trainerController.updatePassword);

module.exports = router;