// personalNotifications.js 
const cron = require("node-cron");
const NotificationService = require("../services/notificationService");
const UserService = require("../services/userService");
const BabyService = require("../services/babyService");
const JournalService = require("../services/journalService");

cron.schedule("*/30 * * * *", async () => {
  console.log("Journal Update Reminder Job Running");

  try {
    // Get all users
    const users = await UserService.getAllUsers();

    for (const user of users) {
      const userId = user.id;

      // Skip deleted users
      if (user.deletedAt) continue;

      // Get baby profiles for user
      const babies = await BabyService.getProfiles(userId);

      for (const baby of babies) {
        // Get latest journal entry
        const entries = await JournalService.getEntries(baby.id);
        if (!entries.length) continue;

        const latestEntry = entries.sort(
          (a, b) => new Date(b.awakeTime) - new Date(a.awakeTime)
        )[0];

        const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);

        if (latestEntry.awakeTime.toDate() <= threeHoursAgo) {
          // Send notification to all user's devices
          if (user.fcmTokens && user.fcmTokens.length > 0) {
            await NotificationService.sendToUser(
              user.fcmTokens,
              "Reminder",
              `It’s been 3 hours since your last journal entry for ${baby.name}. Want to log one now?`
            );
            console.log(`Journal Update Reminder: Sent to user ${user.username}`);
          }
        }
      }
    }
  } catch (err) {
    console.error("Journal Update Reminder Job Running Error:", err);
  }
}, {
  timezone: "Asia/Singapore",
});
