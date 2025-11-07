const { Timestamp } = require("firebase-admin/firestore");
const dayjs = require("dayjs");

class EntryPlanner {
    constructor(id, {
        totalFeeds = 0,
        firstFeedTime = null, // e.g., "03:00"
        lastFeedTime = null,  // e.g., "00:00"
        MONInterval = null,
        feedTimings = [], // e.g., ["03:00", "06:00", ...]
        weekNo = 1,
        createdAt = new Date()
    }) {
        this.id = id;
        this.totalFeeds = totalFeeds;
        this.firstFeedTime = firstFeedTime; // store as string "HH:mm"
        this.lastFeedTime = lastFeedTime;   // store as string "HH:mm"
        this.MONInterval = MONInterval;
        this.feedTimings = feedTimings;
        this.weekNo = weekNo;
        this.createdAt = EntryPlanner.toTimestamp(createdAt);
    }

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

        // Convert time strings → Date objects
        const first = EntryPlanner.toDateFromTimeStr(this.firstFeedTime);
        const last = EntryPlanner.toDateFromTimeStr(this.lastFeedTime);

        // Handle wrap-around (e.g., 03:00 → 00:00 next day)
        let endMs = last.getTime();
        const startMs = first.getTime();
        if (endMs <= startMs) {
            endMs += 24 * 60 * 60 * 1000; // add 24 hours
        }

        // Total duration in hours
        const totalDuration = (endMs - startMs) / (1000 * 60 * 60);
        let intervalsNeeded = this.totalFeeds - 1;

        // Calculate mean interval
        let spacehours = totalDuration / intervalsNeeded;
        let feedChange = 0;

        // Adjust feed count if spacing is off
        while (spacehours < 2.5 || spacehours > 3) {
            if (spacehours > 3) {
                this.totalFeeds += 1;
                intervalsNeeded += 1;
                feedChange += 1;
            } else if (spacehours < 2.5) {
                this.totalFeeds -= 1;
                intervalsNeeded -= 1;
                feedChange -= 1;
            }
            spacehours = totalDuration / intervalsNeeded;
        }

        // Find optimal combination of intervals (2.5–3.0 hr)
        const allowed = [2.5, 2.75, 3];
        const findBestIntervals = (totalDuration, intervalsNeeded) => {
            let best = null, bestDiff = Infinity;

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
        };

        const bestIntervals = findBestIntervals(totalDuration, intervalsNeeded);

        // Generate feed timings (time-only strings)
        const timings = [];
        let current = first;

        //for the timings added can i have it am/pm instead of 24hr
        timings.push(EntryPlanner.toTimeStr(current)); // first feed

        for (let h of bestIntervals.slice(0, -1)) {
            current = new Date(current.getTime() + h * 60 * 60 * 1000);
            timings.push(EntryPlanner.toTimeStr(current));
        }

        // Final feed is exact last feed time
        timings.push(EntryPlanner.toTimeStr(last));

        this.feedTimings = timings;

        // Compute MONInterval
        const remainingHours = 24 - totalDuration;

        // Convert remainingHours → HH:mm (e.g., 2.5 → "02:30")
        const hours = Math.floor(remainingHours);
        const minutes = Math.round((remainingHours - hours) * 60);
        this.MONInterval = `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}`;

        // Message for total feed adjustments
        let message = "";
        if (feedChange > 0) message = `Total Feed increased by ${feedChange}`;
        else if (feedChange < 0) message = `Total Feed decreased by ${Math.abs(feedChange)}`;

        return message;
    }

    //Convert instance to Firestore object
    toFirestore() {
        return {
            id: this.id,
            totalFeeds: this.totalFeeds,
            firstFeedTime: this.firstFeedTime,
            lastFeedTime: this.lastFeedTime,
            MONInterval: this.MONInterval,
            feedTimings: this.feedTimings,
            weekNo: this.weekNo,
            createdAt: this.createdAt
        };
    }

    //Reconstruct EntryPlanner from Firestore snapshot  
    static fromFirestore(docSnap) {
        const data = docSnap.data();
        return new EntryPlanner(docSnap.id, data);
    }

    static toDateFromTimeStr(timeStr) {
        const [hours, minutes] = timeStr.split(":").map(Number);
        return new Date(1970, 0, 1, hours, minutes);
    }

    static toTimeStr(dateObj) {
        // return dayjs(dateObj).format("HH:mm");
        return dayjs(dateObj).format("hh:mm A"); // e.g., "3:00 AM"
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
