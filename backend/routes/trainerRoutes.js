const express = require('express');
const router = express.Router();
const trainerController = require('../controllers/trainerController');
const { authenticateToken } = require('../middleware/authMiddleware');

// Public routes
// router.post('/', trainerController.registerNew);

router.post('/login', trainerController.login);

// Protected routes
router.put('/password', authenticateToken, trainerController.updatePassword);

//Get users managed by trainer
router.get('/users', authenticateToken, trainerController.getManagedUsers);

//get baby profiles for a managed user
router.get('/users/:userId/babies', authenticateToken, trainerController.getManagedUserBabies);


module.exports = router;