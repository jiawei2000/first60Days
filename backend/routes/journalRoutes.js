const express = require('express')
const router = express.Router()
const journalController = require('../controllers/journalController')
const { authenticateToken } = require('../middleware/authMiddleware');

//protected
router.post('/:babyId', journalController.createEntry);
router.put('/:babyId/:entryId', authenticateToken, journalController.editEntry);
router.get('/:babyId', authenticateToken, journalController.getEntries);
router.get('/:babyId/:entryId', authenticateToken, journalController.getEntryById);
router.get('/:babyId/cycleNo', authenticateToken, journalController.getCurrentCycleNo);

module.exports = router