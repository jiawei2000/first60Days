// notificationService.js
const { getMessaging } = require('firebase-admin/messaging');

class NotificationService {
  // Send to topic (existing)
  static async sendDailyBabyJournalReminder() {
    const message = {
      notification: {
        title: 'Time to update your baby journal',
        body: 'Keep recording thanks',
      },
      topic: 'daily_baby_journal',
    };
    return await getMessaging().send(message);
  }

  // Send to one or more tokens
  static async sendToUser(tokens, title, body) {
    const message = {
      notification: { title, body },
      tokens, // can be array
    };

    try {
      const response = await getMessaging().sendEachForMulticast(message);

      // Cleanup invalid tokens
      response.responses.forEach((res, idx) => {
        if (!res.success) {
          console.error(`Token ${tokens[idx]} failed:`, res.error);
          if (
            res.error.code === 'messaging/invalid-argument' ||
            res.error.code === 'messaging/registration-token-not-registered'
          ) {
            // remove from DB
            this.removeInvalidToken(tokens[idx]);
          }
        }
      });

      return response;
    } catch (error) {
      console.error('Error sending personalized notification:', error);
      throw error;
    }
  }

  static async removeInvalidToken(token) {
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('fcmTokens', 'array-contains', token).get();

    snapshot.forEach(async (doc) => {
      await doc.ref.update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(token),
      });
      console.log(`Removed invalid token ${token} from user ${doc.id}`);
    });
  }
}

module.exports = NotificationService;
