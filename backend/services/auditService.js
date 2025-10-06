// services/AuditService.js
const { getFirestore } = require("firebase-admin/firestore");
const db = getFirestore();

class AuditService {
  static async log({ actor, action, target, status = "SUCCESS", details = {} }) {
    try {
      const record = {
        actor: actor || "system",
        action,                      // Example: CREATE_JOURNAL, LOGIN, SEND_NOTIFICATION
        target,                      // Example: userId, babyId, notificationId
        status,                      // SUCCESS / FAILURE
        timestamp: new Date(),
        details                      // IP, request body, etc.
      };

      await db.collection("auditTrail").add(record);
      console.log("[AUDIT]", record);
    } catch (err) {
      console.error("[AUDIT ERROR]", err);
    }
  }
}

module.exports = AuditService;
