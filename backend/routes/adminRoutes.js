const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticateToken, authorizeRoles } = require('../middleware/authMiddleware');

// Public routes
router.post('/', adminController.registerNew);
router.post('/login', adminController.login);

// Protected routes
//create new trainer accounts 
router.post('/registerTrainer', authenticateToken, adminController.registerTrainer);
//create new user accounts
router.post('/registerUser', authenticateToken, adminController.registerUser);

//get all trainers
router.get('/trainers', authenticateToken, adminController.getAllTrainers);

//get all users (main)
router.get('/users', authenticateToken, adminController.getAllUsers);

//update trainer ID for a user
router.put('/updateUserTrainer/:userId', authenticateToken, adminController.updateUserTrainer);

module.exports = router;