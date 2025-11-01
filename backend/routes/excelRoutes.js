const express = require('express');
const router = express.Router();
const excelController = require('../controllers/excelController');

router.get('/usersInfo', excelController.exportUsers);

router.get('/babysJournal/:babyId', excelController.exportBabyJournal);

module.exports = router;