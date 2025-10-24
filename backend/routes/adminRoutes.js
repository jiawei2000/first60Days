const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticateToken, authorizeRoles } = require('../middleware/authMiddleware');

// Public routes
router.post('/', adminController.registerNew);
router.post('/login', adminController.login);

// Protected routes
//create new sub accounts 
router.post('/registerTrainer', authenticateToken, adminController.registerTrainer);
router.post('/registerUser', authenticateToken, adminController.registerUser);

module.exports = router;