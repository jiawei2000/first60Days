const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticateToken, authorizeRoles } = require('../middleware/authMiddleware');


// Public routes
router.post('/', adminController.registerNew);
router.post('/login', adminController.login);

// -------------------------------------------------------------
// 🟢 POST Routes (Create resources)
// -------------------------------------------------------------

// Create new trainer accounts
router.post('/registerTrainer', authenticateToken, adminController.registerTrainer);

// Create new user accounts
router.post('/registerUser', authenticateToken, adminController.registerUser);

// -------------------------------------------------------------
// 🟡 PUT Routes (Update or modify resources)
// -------------------------------------------------------------

// Edit admin profile
router.put('/editAdminProfile', authenticateToken, adminController.editAdminProfile);

// Edit user (main) by ID
router.put('/editUser/:userId', authenticateToken, adminController.editUserById);

// Update trainer ID for a specific user
router.put('/updateUserTrainer/:userId', authenticateToken, adminController.updateUserTrainer);

// -------------------------------------------------------------
// 🔵 GET Routes (Retrieve resources)
// -------------------------------------------------------------

// Get user (main) by ID
router.get('/user/:userId', authenticateToken, adminController.getUserById);

// Get trainer by ID
router.get('/trainer/:trainerId', authenticateToken, adminController.getTrainerById);

// Get all trainers
router.get('/trainers', authenticateToken, adminController.getAllTrainers);

// Get all users (main)
router.get('/users', authenticateToken, adminController.getAllUsers);

//get admin dashboard data
router.get('/dashboard', adminController.getAdminDashboardData);


module.exports = router;