const express = require('express');
const router = express.Router();
const multer = require('multer');

const ExcelController = require('../controllers/excelController');

// Multer: keep file in memory (Buffer at req.file.buffer)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 15 * 1024 * 1024 }, // 15MB, adjust as needed
});

router.get('/usersInfo', ExcelController.exportUsers);
router.get('/babysJournal/:babyId', ExcelController.exportBabyJournal);
router.post('/importJournal/:babyId', upload.single('file'), ExcelController.importJournalEntriesFromExcel);
router.post('/importFakeData/:babyId', upload.single('file'), ExcelController.importFakeDataExcel);

module.exports = router;