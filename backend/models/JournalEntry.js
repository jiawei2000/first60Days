class JournalEntry {
    constructor(id, { awakeTime, cycleNo, feedType, remarks, sleepDuration, startFeedTime, startPlayTime, startSleepTime, stool, urine }) {
        this.id = id;
        this.awakeTime = awakeTime;
        this.cycleNo = cycleNo;
        this.feedType = feedType;
        this.remarks = remarks;
        this.sleepDuration = sleepDuration;
        this.startFeedTime = startFeedTime;
        this.startPlayTime = startPlayTime;
        this.startSleepTime = startSleepTime;
        this.stool = stool;
        this.urine = urine;
    }
}
module.exports = JournalEntry;
