const express = require('express');
const router = express.Router();
const { handleQuery } = require('../controllers/assistantController');

router.post('/query', handleQuery);

module.exports = router;
