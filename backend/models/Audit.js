class Audit {
    constructor(id, { actor, action, target, status, details, doneAt }) {
        this.id = id;
        this.actor = actor;
        this.action = action;                      // Example: CREATE_JOURNAL, LOGIN, SEND_NOTIFICATION
        this.target = target;                      // Example: userId, babyId, notificationId
        this.status = status;                      // SUCCESS / FAILURE
        this.details = details;                    // IP, request body, etc.
        this.doneAt = doneAt;
    }

    static fromFirestore(doc) {
        const data = doc.data();
        return new Audit(doc.id, data);
    }

    toFirestore() {
        return {
            actor: this.actor,
            action: this.action,
            target: this.target,
            status: this.status,
            details: this.details,
            doneAt: this.doneAt
        };
    }
}

module.exports = Audit;