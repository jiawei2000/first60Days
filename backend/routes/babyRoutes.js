const express = require('express');
const router = express.Router();
const babyController = require('../controllers/babyController');
const { authenticateToken } = require('../config/authMiddleware');

// Protected routes
router.post('/newProfile', authenticateToken, babyController.newProfile)
router.put('/editProfile', authenticateToken, babyController.editProfile)
router.delete('/deleteProfile', authenticateToken, babyController.deleteProfile)
router.get('/getProfiles', authenticateToken, babyController.getProfiles)
router.get('/getProfileById', authenticateToken, babyController.getProfileById)

module.exports = router;