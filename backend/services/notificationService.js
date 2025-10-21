// ../services/notificationService.js
const db = require('../config/database');
const { getMessaging } = require('firebase-admin/messaging');
const { FieldValue } = require('firebase-admin/firestore');

const Notification = require('../models/Notification');

const notificationsRef = db.collection('notifications');
const usersRef = db.collection('users');

class NotificationService {
  // ----------------------- Internal helpers ---------------------------------

  static _ensureUserRef(userId) {
    if (!userId) return null;
    // Heuristic: DocumentReference has a get() function and a path
    if (typeof userId === 'object' && typeof userId.get === 'function' && userId.path) {
      return userId; // already a DocumentReference
    }
    return usersRef.doc(String(userId));
  }

  // Generate a new notification ID without creating the document
  static _newNotificationId() {
    return notificationsRef.doc().id;
  }

  static async _logNotification(notificationId, { userId, message, topic = null }) {
    const notificationRef = notificationsRef.doc(notificationId);
    const userRef = this._ensureUserRef(userId);

    const notification = new Notification(notificationRef.id, {
      userId: userRef,
      message,
      readAt: null,
      createdAt: FieldValue.serverTimestamp(),
      deletedAt: null,
      topic,
    });

    await notificationRef.set(notification.toFirestore());
    return notificationRef.id;
  }

  static async _getUserTokens(userId) {
    const userRef = this._ensureUserRef(userId);
    if (!userRef) return [];
    const snap = await userRef.get();
    if (!snap.exists) return [];
    const data = snap.data() || {};
    return Array.isArray(data.fcmTokens) ? data.fcmTokens : [];
  }

  static async _removeInvalidToken(token) {
    const snapshot = await usersRef.where('fcmTokens', 'array-contains', token).get();
    if (snapshot.empty) return;

    const batch = db.batch();
    snapshot.forEach((doc) => {
      batch.update(doc.ref, { fcmTokens: FieldValue.arrayRemove(token) });
    });
    await batch.commit();
    console.log(`Removed invalid token ${token} from ${snapshot.size} user(s).`);
  }

  static _handleSendEachResponse(tokens, response) {
    response.responses.forEach((res, idx) => {
      if (!res.success) {
        const err = res.error;
        console.error(`Token ${tokens[idx]} failed:`, err?.code, err?.message);
        if (
          err?.code === 'messaging/invalid-argument' ||
          err?.code === 'messaging/registration-token-not-registered'
        ) {
          this._removeInvalidToken(tokens[idx]).catch(console.error);
        }
      }
    });
  }

  // ----------------------------- Sends --------------------------------------
  // Send a daily reminder to the 'daily_baby_journal' topic
  static async sendDailyBabyJournalReminder() {
    const title = 'Time to update your baby journal';
    const body  = 'Keep recording thanks';
    const topic = 'daily_baby_journal';

    const notificationIdSeed = this._newNotificationId();

    const message = {
      notification: { title, body },
      topic,
      data: {
        notificationId: String(notificationIdSeed),
      },
    };

    let fcmId = null;
    let notificationId = null;

    try {
      fcmId = await getMessaging().send(message);

      // Log on successful send
      notificationId = await this._logNotification(notificationIdSeed, 
        { userId: null, 
          message: body, 
          topic 
        });
    } catch (err) {
      console.error('Topic send failed:', err?.code || err?.message || err);
    }

    return { fcmId, notificationId };
  }

  static async sendToUserId(userId, title, body, data = {}) {
    const userRef = this._ensureUserRef(userId);
    const tokens = await this._getUserTokens(userRef);

    if (!tokens.length) {
      return { notificationId: null, fcmResponse: null, info: 'No tokens for user; not sent, not logged.' };
    }

    const notificationIdSeed = this._newNotificationId();
    const normalizedData = Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, v == null ? '' : String(v)])
    );

    const message = {
      notification: { title, body },
      data: {
        ...normalizedData,
        notificationId: String(notificationIdSeed),
      },
      tokens,
    };

    let notificationId = null;
    let fcmResponse = null;

    try {
      fcmResponse = await getMessaging().sendEachForMulticast(message);
      this._handleSendEachResponse(tokens, fcmResponse);

      if (fcmResponse.successCount > 0) {
        // At least one success => log a single in-app notification
        notificationId = await this._logNotification(notificationIdSeed,
          { userId: userRef, 
            message: body 
          });
      }
    } catch (err) {
      console.error('Multicast send failed:', err?.code || err?.message || err);
    }

    return { notificationId, fcmResponse };
  }

  // ----------------------------- Updates ------------------------------------

  static async markRead(notificationId) {
    await notificationsRef.doc(notificationId).update({
      readAt: FieldValue.serverTimestamp(),
    });
    return {
            message: 'Notification marked as read',
            notificationId
          };
  }

  static async softDelete(notificationId) {
    await notificationsRef.doc(notificationId).update({
      deletedAt: FieldValue.serverTimestamp(),
    });
    return {
      message: 'Notification soft-deleted',
      notificationId
    };
  }
}

module.exports = NotificationService;