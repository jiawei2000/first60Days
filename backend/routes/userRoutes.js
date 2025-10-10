const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken, authorizeRoles } = require('../middleware/authMiddleware');
const auditMiddleware = require('../middleware/auditMiddleware');

// Public routes
router.post('/', userController.registerNew);
router.post('/login', userController.login);

// Protected routes

//to get all sub users created by main
router.get('/subAccounts', authenticateToken, userController.getSubAccounts)

router.post('/registerSub', authenticateToken, userController.registerSub);
router.put('/password', authenticateToken, userController.updatePassword);

//to be updated - should not need user ID in pararm
router.delete('/:userId', authenticateToken, authorizeRoles('trainer'), auditMiddleware('DELETE_USER'), userController.deleteUser);

//to get specific userID of sub account
router.get('/:userId', authenticateToken, userController.getUserById)

router.put('/username/:userId', authenticateToken, userController.updateUsername)

module.exports = router;