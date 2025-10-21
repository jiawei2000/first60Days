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
    }
}

module.exports = NotificationController;