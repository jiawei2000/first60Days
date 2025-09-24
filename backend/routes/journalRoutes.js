const express = require('express')
const router = express.Router()
// const babyController = require('../controllers/babyController');
const journalController = require('../controllers/journalController')
const { authenticateToken } = require('../config/authMiddleware')

//protected
router.post('/createEntry', authenticateToken, journalController.createEntry)
router.put('/editEntry', authenticateToken, journalController.editEntry)
router.post('/getEntries', authenticateToken, journalController.getEntries)
router.post('/getEntryById', authenticateToken, journalController.getEntryById)
router.get('/getCurrentCycleNo', authenticateToken, journalController.getCurrentCycleNo)

module.exports = router