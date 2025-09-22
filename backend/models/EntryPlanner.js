const { Timestamp } = require('firebase-admin/firestore');

class EntryPlanner {
    constructor(id, {
        totalFeeds = 0,
        firstFeedTime = null,
        lastFeedTime = null,
        MONInterval = null,
        feedTimings = [],
        weekNo = 1,
        createdAt = null
    }) {
        this.id = id; // Firestore document ID
        this.totalFeeds = totalFeeds;
        // this.firstFeedTime = firstFeedTime ? new Date(firstFeedTime) : null;
        this.firstFeedTime = firstFeedTime ? EntryPlanner.toTimestamp(firstFeedTime) : null;
        this.lastFeedTime = lastFeedTime ? EntryPlanner.toTimestamp(lastFeedTime) : null;
        this.MONInterval = MONInterval; // display value in hours
        this.feedTimings = feedTimings;
        this.weekNo = weekNo;
        this.createdAt = createdAt ? new Date(createdAt) : new Date(); // default to now
    }

    // Generates feed timings of the day 
    //each interval should be 2.5hr - 3hr apart. 
    //e.g. if 1st feed 3am, last feed 12am, 
    //feed interval would be [3, 6, 9, 12 15 18 21 24]
    //minimally 8 feeds from week 1-5, 7 feeds for week 6-10
    // Generates feed timings for the day
    generateFeedTimings() {
        if (!this.firstFeedTime || !this.lastFeedTime) {
            throw new Error("firstFeedTime and lastFeedTime are required to generate feed timings.");
        }

        // Step 1: set totalFeeds if not provided
        if (!this.totalFeeds) {
            if (this.weekNo >= 1 && this.weekNo <= 5) this.totalFeeds = 8;
            else if (this.weekNo >= 6 && this.weekNo <= 10) this.totalFeeds = 7;
            else this.totalFeeds = 7;
        }

        // Step 2: calculate MONInterval (display only)
        const first = this.firstFeedTime.toDate ? this.firstFeedTime.toDate() : new Date(this.firstFeedTime);
        const last = this.lastFeedTime.toDate ? this.lastFeedTime.toDate() : new Date(this.lastFeedTime);

        const startMs = first.getTime();
        const endMs = last.getTime();
        this.MONInterval = (endMs - startMs) / (1000 * 60 * 60); // in hours

        // Step 3: generate feed timings between 2.5–3 hours apart
        let spacingHours = (endMs - startMs) / (this.totalFeeds - 1) / (1000 * 60 * 60);

        if (spacingHours < 2.5) spacingHours = 2.5;
        if (spacingHours > 3) spacingHours = 3;

        this.feedTimings = [];
        let currentTime = new Date(startMs);
        this.feedTimings.push(new Date(currentTime)); // first feed

        for (let i = 1; i < this.totalFeeds - 1; i++) {
            currentTime = new Date(currentTime.getTime() + spacingHours * 60 * 60 * 1000);
            this.feedTimings.push(new Date(currentTime));
        }

        this.feedTimings.push(new Date(endMs)); // last feed

        // Ensure feed timings are sorted ascending
        this.feedTimings.sort((a, b) => a.getTime() - b.getTime());

        return this.feedTimings;
    }

    // Convert instance to Firestore-friendly format
    toFirestore() {
        return {
            totalFeeds: this.totalFeeds,
            firstFeedTime: this.firstFeedTime,
            lastFeedTime: this.lastFeedTime,
            MONInterval: this.MONInterval,
            feedTimings: this.feedTimings,
            weekNo: this.weekNo,
            createdAt: this.createdAt
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

}

module.exports = EntryPlanner;
