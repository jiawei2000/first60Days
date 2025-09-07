const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken } = require('../config/authMiddleware');

// Public routes
router.post('/registerNew', userController.registerNew);
router.post('/login', userController.login);

// Protected routes
router.post('/registerSub', authenticateToken, userController.registerSub);
router.put('/updatePassword', authenticateToken, userController.updatePassword);
router.delete('/delete', authenticateToken, userController.deleteUser);

module.exports = router;
