const { Timestamp } = require('firebase-admin/firestore');

class Baby {
    constructor(id, { name, dob, createdAt, deletedAt, feedSchedule }) {
        this.id = id;
        this.name = name;
        this.dob = dob;
        this.createdAt = createdAt || Timestamp.now();
        this.deletedAt = deletedAt || null;
        this.feedSchedule = feedSchedule || null;
    }

    // Convert Firestore document to Baby instance
    static fromFirestore(doc) {
        const data = doc.data();
        return new Baby(doc.id, data);
    }

    // Convert Baby instance to Firestore object
    toFirestore() {
        return {
            name: this.name,
            dob: this.dob,
            createdAt: this.createdAt,
            deletedAt: this.deletedAt,
            feedSchedule: this.feedSchedule,
        };
    }
}

module.exports = Baby;
