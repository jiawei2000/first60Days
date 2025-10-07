const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken } = require('../middleware/authMiddleware');

// Public routes
router.post('/', userController.registerNew);
router.post('/login', userController.login);

// Protected routes

//to get all sub users created by main
router.get('/subAccounts', authenticateToken, userController.getSubAccounts)

router.post('/registerSub', authenticateToken, userController.registerSub);
router.put('/password', authenticateToken, userController.updatePassword);
//to be updated - should not need user ID in pararm
router.delete('/:userId', authenticateToken, userController.deleteUser);
//to get specific userID of sub account
router.get('/:userId', authenticateToken, userController.getUserById)

router.put('/username/:userId', authenticateToken, userController.updateUsername)

module.exports = router;
