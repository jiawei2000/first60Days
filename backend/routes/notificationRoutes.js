const express = require('express')
const router = express.Router()
const notificationController = require('../controllers/notificationController')

router.get('/all/:userId', notificationController.getAllNotificationsForUser);
router.get('/unread/critical/:userId', notificationController.getUnreadCriticalNotifications);
router.get('/unread/important/:userId', notificationController.getUnreadImportantNotifications);
router.get('/unread/normal/:userId', notificationController.getUnreadNormalNotifications);
router.get('/unread/:userId', notificationController.getUnreadNotifications);

router.patch('/:notificationId', notificationController.markRead);
router.delete('/:notificationId', notificationController.softDelete);

module.exports = router