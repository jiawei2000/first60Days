// notifications.js
const cron = require('node-cron');
const NotificationService = require('../services/notificationService');

// Schedule notification reminder at 0000 every day
cron.schedule('*/10 * * * * *', async () => {
// cron.schedule('0 0 * * *', async () => {
  console.log('[Reminder] Sending baby journal reminder at 12:00 AM');
  await NotificationService.sendDailyBabyJournalReminder();
}, {
  timezone: 'Asia/Singapore',
});

// 🔔 Test personalized notification every 10 seconds
// Replace with a real FCM token from a device/app instance
const TEST_TOKENS = [
  "dOHJjOjYTQOJj0CpTy1E2L:APA91bGlFx-1PLZ1LFn3jV266PPapCAkTeyPqIq_1pkMmHGY8Q6JnabC5iSOYEfBQDhNRwcJXUdVN4aY84hkXpeDmpYfSWkOPDA9SwHIWKwPE4Gdi0Z4j9U"
];

cron.schedule('*/10 * * * * *', async () => {
  console.log('[Test] Sending personalized notification...');
  if (TEST_TOKENS.length > 0) {
    await NotificationService.sendToUser(
      TEST_TOKENS,
      "Test Personalized Notification",
      "This is a test message sent at " + new Date().toLocaleTimeString()
    );
  } else {
    console.log('[Test] No tokens available for personalized notification');
  }
});