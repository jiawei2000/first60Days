const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken, authorizeRoles } = require('../middleware/authMiddleware');
const auditMiddleware = require('../middleware/auditMiddleware');

// Public routes
router.post('/', userController.registerNew);
router.post('/login', userController.login);

// Protected routes
//get all user accounts (main & subs)
router.get("/", authenticateToken, userController.getAllUsers);
//to get all sub users created by main
router.get('/subAccounts', authenticateToken, userController.getSubAccounts)
//create new sub accounts 
router.post('/registerSub', authenticateToken, userController.registerSub);
//update password of main 
router.put('/password', authenticateToken, userController.updatePassword);
//Main update username of subs 
router.put('/username/:userId', authenticateToken, userController.updateUsername)

router.get('/getMainAccount', authenticateToken, userController.getMainAccount);


//to be updated - should not need user ID in pararm
router.delete('/:userId', authenticateToken, authorizeRoles('trainer'), auditMiddleware('DELETE_USER'), userController.deleteUser);
//to get specific userID of sub account
router.get('/:userId', authenticateToken, userController.getUserById)


module.exports = router;