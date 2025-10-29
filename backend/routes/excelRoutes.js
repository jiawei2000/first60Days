const express = require('express');
const router = express.Router();
const excelController = require('../controllers/excelController');

router.get('/users.xlsx', excelController.exportUsers);

module.exports = router;