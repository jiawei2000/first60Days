const { Timestamp } = require('firebase-admin/firestore');

class EntryPlanner {
    constructor(id, {
        totalFeeds = 0,
        firstFeedTime = null, //Only time is needed, not date. 
        lastFeedTime = null, //Only time is needed, not date. 
        MONInterval = null,
        feedTimings = [], //Only time is needed, not date. 
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
        this.createdAt = createdAt ? EntryPlanner.toTimestamp(new Date(createdAt)) : EntryPlanner.toTimestamp(new Date());
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

        // Step 1: set totalFeeds if not provided (kinda useless IF block)
        if (!this.totalFeeds) {
            if (this.weekNo >= 1 && this.weekNo <= 5) this.totalFeeds = 8;
            else if (this.weekNo >= 6 && this.weekNo <= 10) this.totalFeeds = 7;
            else this.totalFeeds = 7;
        }

        //converts timestamp to date obj
        const first = this.firstFeedTime.toDate ? this.firstFeedTime.toDate() : new Date(this.firstFeedTime); //date obj
        const last = this.lastFeedTime.toDate ? this.lastFeedTime.toDate() : new Date(this.lastFeedTime); //date obj
        // Step 2: calculate MONInterval (display only)
        const startMs = first.getTime();
        const endMs = last.getTime();
        this.MONInterval = 24 - ((endMs - startMs) / (1000 * 60 * 60)); // in hours

        let intervalsNeeded = this.totalFeeds - 1;
        const allowed = [2.5, 2.75, 3]; //can include 3.25 and 2.25
        const totalDuration = ((endMs - startMs) / (1000 * 60 * 60));

        let spacehours = totalDuration / intervalsNeeded;

        //keeping interval between 2.5-3hrs. tbc
        while (spacehours < 2.5 || spacehours > 3) {
            if (spacehours > 3) {
                console.log(`${spacehours} hr interval, more feed needed. Incrementing total Feed by 1`)
                this.totalFeeds += 1;
                intervalsNeeded += 1;
                spacehours = totalDuration / intervalsNeeded;
            }
            else if (spacehours < 2) {
                console.log(`${spacehours} hr interval, less feed needed. Reducing total Feed by 1`)
                this.totalFeeds -= 1;
                intervalsNeeded -= 1;
                spacehours = totalDuration / intervalsNeeded;
            }
        }

        //calibrate spacehours/interval 
        //if spacing hours > 3: totalFeeds too little 
        function findBestIntervals(totalDuration, intervalsNeeded) {
            let best = null;
            let bestDiff = Infinity;

            function backtrack(current, depth, sum) {
                if (depth === intervalsNeeded) {
                    const diff = Math.abs(sum - totalDuration);
                    if (diff < bestDiff) {
                        bestDiff = diff;
                        best = [...current];
                    }
                    return;
                }
                for (let a of allowed) {
                    current.push(a);
                    backtrack(current, depth + 1, sum + a);
                    current.pop();
                }
            }

            backtrack([], 0, 0);
            return best;
        }


        const bestIntervals = findBestIntervals(totalDuration, intervalsNeeded);
        let current = this.firstFeedTime.toDate(); //this.firstFeedTime is firestore timestamp 
        this.feedTimings.push(new Date(current).toLocaleString("en-SG", {
            timeZone: "Asia/Singapore",
            hour: "2-digit",
            minute: "2-digit",
            hour12: true
        })); // first feed

        for (let h of bestIntervals.slice(0, -1)) {
            current = new Date(current.getTime() + h * 60 * 60 * 1000);
            this.feedTimings.push(new Date(current).toLocaleString("en-SG", {
                timeZone: "Asia/Singapore",
                hour: "2-digit",
                minute: "2-digit",
                hour12: true
            }));
        }

        // Step 5: force last feed to be exactly lastFeedTime
        this.feedTimings.push(this.lastFeedTime.toDate().toLocaleString("en-SG", {
            timeZone: "Asia/Singapore",
            hour: "2-digit",
            minute: "2-digit",
            hour12: true
        }));

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
        //convert date object to timestamp
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
