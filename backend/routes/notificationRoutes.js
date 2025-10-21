const express = require('express')
const router = express.Router()
const notificationController = require('../controllers/notificationController')

router.patch('/:notificationId', notificationController.markRead);
router.delete('/:notificationId', notificationController.softDelete);

module.exports = router