const express = require('express');
const router = express.Router();
const babyController = require('../controllers/babyController');
const { authenticateToken } = require('../config/authMiddleware');

// Protected routes
router.post('/', authenticateToken, babyController.newProfile)
router.put('/:babyId', authenticateToken, babyController.editProfile)
router.delete('/:babyId', authenticateToken, babyController.deleteProfile)
router.get('/', authenticateToken, babyController.getProfiles)
router.get('/:babyId', authenticateToken, babyController.getProfileById)

module.exports = router;