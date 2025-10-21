const express = require('express')
const router = express.Router()
const notificationController = require('../controllers/notificationController')


router.put('/:notificationId', notificationController.markRead);
router.delete('/:notificationId', notificationController.softDelete);

module.exports = router