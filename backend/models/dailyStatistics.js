class DailyStatistics {
    // Define the schema for daily statistics
    constructor(id, {
        totalFeeds, totalUrineCount, totalStoolCount, totalSleepDuration, totalPlayDuration, totalCyclesBeyond3Hrs,
        monInterval,
        averageMilkIntake, averagePlayDuration, averageLapseDuration,
        day, createdAt, date, babyIDRef
    }) {
        this.id = id; // Document ID
        this.totalFeeds = totalFeeds;
        this.totalUrineCount = totalUrineCount;
        this.totalStoolCount = totalStoolCount;
        this.totalSleepDuration = totalSleepDuration;
        this.totalPlayDuration = totalPlayDuration;
        this.totalCyclesBeyond3Hrs = totalCyclesBeyond3Hrs;
        this.monInterval = monInterval;
        this.averageMilkIntake = averageMilkIntake;
        this.averagePlayDuration = averagePlayDuration;
        this.averageLapseDuration = averageLapseDuration;
        this.day = day; //
        this.createdAt = createdAt;
        this.date = date;
        this.babyIDRef = babyIDRef; // Reference to Baby document
    }
    
    static fromFirestore(doc) {
        const data = doc.data();
        return new DailyStatistics(doc.id, data);
    }

    toFirestore() {
        return {
            totalFeeds: this.totalFeeds,
            totalUrineCount: this.totalUrineCount,
            totalStoolCount: this.totalStoolCount,
            totalSleepDuration: this.totalSleepDuration,
            totalPlayDuration: this.totalPlayDuration,
            totalCyclesBeyond3Hrs: this.totalCyclesBeyond3Hrs,
            monInterval: this.monInterval,
            averageMilkIntake: this.averageMilkIntake,
            averagePlayDuration: this.averagePlayDuration,
            averageLapseDuration: this.averageLapseDuration,
            day: this.day,
            createdAt: this.createdAt,
            date: this.date,
            babyIDRef: this.babyIDRef
        };
    }
}

module.exports = DailyStatistics;