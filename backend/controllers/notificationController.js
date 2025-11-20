const NotificationService = require('../services/notificationService');


const NotificationController = {
    async markRead(req, res) {
        try {
            const { notificationId } = req.params;
            const result = await NotificationService.markRead(notificationId);
            res.status(200).json(result);

        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async softDelete(req, res) {
        try {
            const { notificationId } = req.params;
            const result = await NotificationService.softDelete(notificationId);
            res.status(200).json(result);

        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getAllNotificationsForUser(req, res) {
        try {
            const { userId } = req.params;
            const notifications = await NotificationService.getAllNotificationsForUser(userId);
            res.status(200).json(notifications);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getUnreadNotifications(req, res) {
        try {
            const { userId } = req.params;
            const notifications = await NotificationService.getUnreadNotifications(userId);
            res.status(200).json(notifications);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getUnreadCriticalNotifications(req, res) {
        try {
            const { userId } = req.params;
            const notifications = await NotificationService.getUnreadCriticalNotifications(userId);
            res.status(200).json(notifications);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getUnreadImportantNotifications(req, res) {
        try {
            const { userId } = req.params;
            const notifications = await NotificationService.getUnreadImportantNotifications(userId);
            res.status(200).json(notifications);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },

    async getUnreadNormalNotifications(req, res) {
        try {
            const { userId } = req.params;
            const notifications = await NotificationService.getUnreadNormalNotifications(userId);
            res.status(200).json(notifications);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    },
};

module.exports = NotificationController;