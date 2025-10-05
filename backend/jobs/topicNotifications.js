// topicNotifications.js
const cron = require('node-cron');
const NotificationService = require('../services/notificationService');

// Schedule notification reminder at 0000 every day
// cron.schedule('*/10 * * * * *', async () => {
cron.schedule('0 0 * * *', async () => {
  console.log('[Topic] Sending baby journal reminder at 12:00 AM');
  await NotificationService.sendDailyBabyJournalReminder();
}, {
  timezone: 'Asia/Singapore',
});