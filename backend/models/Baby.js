const { Timestamp } = require('firebase-admin/firestore');

class Baby {
    constructor(id, { name, dob, createdAt, deletedAt, expectedDueDate, term, weight, healthConditions, gender, height }) {
        this.id = id;
        // optional fields
        this.gender = gender ? String(gender) : null;
        this.height = height ? Number(height) : null;

        // Required string
        this.name = name ? String(name) : null;

        // Required dates
        this.dob = Baby.toTimestamp(dob);
        this.expectedDueDate = Baby.toTimestamp(expectedDueDate)

        // Required details
        this.term = term ? Number(term) : null;
        this.weight = weight ? Number(weight) : null;
        this.healthConditions = healthConditions ? String(healthConditions) : null;

        // System fields
        this.createdAt = Baby.toTimestamp(createdAt) || Timestamp.now();
        this.deletedAt = Baby.toTimestamp(deletedAt); // null if not delet
    }

    toFirestore() {
        return {
            name: this.name,
            dob: this.dob,
            createdAt: this.createdAt,
            deletedAt: this.deletedAt,
            expectedDueDate: this.expectedDueDate,
            term: this.term,
            weight: this.weight,
            healthConditions: this.healthConditions,
            height: this.height,
            gender: this.gender
        };
    }

    static fromFirestore(doc) {
        const data = doc.data();
        return new Baby(doc.id, data);
    }

    static toTimestamp(value) {
        if (!value) return null;

        if (value instanceof Timestamp) return value;
        if (value instanceof Date) return Timestamp.fromDate(value);

        if (typeof value === 'string') {
            const parsed = new Date(value);
            if (!isNaN(parsed)) return Timestamp.fromDate(parsed);
            throw new Error(`Invalid date string: ${value}`);
        }

        if (typeof value === 'number') {
            return Timestamp.fromMillis(value);
        }

        throw new Error(`Unsupported date value: ${value}`);
    }

    static validateData(data, { partial = false } = {}) {
        const formatted = {};

        // Define fields
        const requiredFields = ['name', 'dob', 'expectedDueDate', 'term', 'weight', 'healthConditions'];
        const dateFields = ['dob', 'createdAt', 'deletedAt'];

        for (const [key, value] of Object.entries(data)) {
            if (value === undefined || value === null) {
                if (!partial && requiredFields.includes(key)) {
                    throw new Error(`Missing required field: ${key}`);
                }
                formatted[key] = null;
                continue;
            }

            if (dateFields.includes(key)) {
                formatted[key] = Baby.toTimestamp(value);
            } else if (key === 'name') {
                if (typeof value !== 'string' || !value.trim()) {
                    throw new Error(`Invalid name: must be non-empty string`);
                }
                formatted[key] = value.trim();
            } else {
                formatted[key] = value;
            }
        }

        // Auto-set createdAt if new record
        if (!partial && !formatted.createdAt) {
            formatted.createdAt = Timestamp.now();
        }

        return formatted;
    }
}

module.exports = Baby;
