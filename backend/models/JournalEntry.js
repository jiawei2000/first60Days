const { Timestamp } = require('firebase-admin/firestore');

class JournalEntry {
    constructor(id, {
        awakeTime = null,
        feedType = [],
        remarks = "",
        sleepDuration = null,
        startFeedTime = null,
        startPlayTime = null,
        startSleepTime = null,
        hasStool = false,
        hasUrine = false,

        cycleNo = null,
        status //either "COMPLETE" or "INCOMPLETE"
    }) {
        this.id = id;

        // normalize dates → always Firestore Timestamp
        //if null/undefined, set to null
        this.awakeTime = JournalEntry.toTimestamp(awakeTime);
        this.startFeedTime = JournalEntry.toTimestamp(startFeedTime);
        this.startPlayTime = JournalEntry.toTimestamp(startPlayTime);
        this.startSleepTime = JournalEntry.toTimestamp(startSleepTime);

        // ensure numbers
        this.cycleNo = Number.isInteger(cycleNo) ? cycleNo : null;
        this.sleepDuration = typeof sleepDuration === "number" ? sleepDuration : null;

        // feedType should be array of objects
        this.feedType = Array.isArray(feedType) ? feedType : [];

        // ensure strings
        this.remarks = remarks ? String(remarks) : "";

        // ensure booleans
        this.hasStool = Boolean(hasStool);
        this.hasUrine = Boolean(hasUrine);

        this.status = status === "COMPLETE" ? "COMPLETE" : "INCOMPLETE"; //default to INCOMPLETE
    }

    toFirestore() {
        return {
            awakeTime: this.awakeTime,
            cycleNo: this.cycleNo,
            feedType: this.feedType,
            remarks: this.remarks,
            sleepDuration: this.sleepDuration,
            startFeedTime: this.startFeedTime,
            startPlayTime: this.startPlayTime,
            startSleepTime: this.startSleepTime,
            hasStool: this.hasStool,
            hasUrine: this.hasUrine,
            status: this.status
        };
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

        const dateFields = ['awakeTime', 'startPlayTime', 'startFeedTime', 'startSleepTime'];
        const booleanFields = ['hasStool', 'hasUrine'];
        const intFields = ['cycleNo', 'sleepDuration'];

        for (const [key, value] of Object.entries(data)) {
            if (value === undefined || value === null) {
                if (!partial) throw new Error(`Missing required field: ${key}`);
                continue;
            }

            if (dateFields.includes(key)) {
                formatted[key] = JournalEntry.toTimestamp(value);
            }
            else if (booleanFields.includes(key)) {
                formatted[key] = Boolean(value);
            }
            else if (intFields.includes(key)) {
                const parsed = parseInt(value, 10);
                if (isNaN(parsed)) throw new Error(`Invalid int for ${key}`);
                formatted[key] = parsed;
            }
            else {
                formatted[key] = value;
            }
        }

        return formatted;
    }

    static checkStatus(entryData) {
        const requiredFields = [
            "awakeTime",
            "startFeedTime",
            "startSleepTime",
            "feedType",
            "sleepDuration",
            "hasStool",
            "hasUrine",
        ];

        // If *any* required field is missing or null → INCOMPLETE
        for (const field of requiredFields) {
            const value = entryData[field];
            if (value === null || value === undefined) return "INCOMPLETE";
        }

        if (Array.isArray(entryData.feedType) && entryData.feedType.length === 0) {
            return "INCOMPLETE";
        }

        // Special rule: startPlayTime can be null → still COMPLETE
        return "COMPLETE";
    }

}

module.exports = JournalEntry;
