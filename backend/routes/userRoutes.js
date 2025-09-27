const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken } = require('../config/authMiddleware');

// Public routes
router.post('/', userController.registerNew);
router.post('/login', userController.login);

// Protected routes
router.post('/registerSub', authenticateToken, userController.registerSub);
router.put('/password', authenticateToken, userController.updatePassword);
router.delete('/:userId', authenticateToken, userController.deleteUser);
router.get('/:userId', authenticateToken, userController.getUserById)

module.exports = router;
