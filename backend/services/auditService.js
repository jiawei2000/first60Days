// services/AuditService.js
const db = require('../config/database');
const Audit = require('../models/Audit'); // <- update path if different

class AuditService {
  static collection() {
    return db.collection('auditTrail');
  }

  static async log({ actor = 'system', action, target, status = 'SUCCESS', details = {} }) {
    try {
      const audit = new Audit(null, {
        actor,
        action, 
        target,
        status,
        details,
        doneAt: new Date(),
      });

      // Persist via model serialization
      const ref = await this.collection().add(audit.toFirestore());

      // Return a model instance with the generated id
      const saved = new Audit(ref.id, audit.toFirestore());
      console.log('[AUDIT]', saved);
      return saved;
    } catch (err) {
      console.error('[AUDIT ERROR]', err);
      throw err;
    }
  }
}

module.exports = AuditService;