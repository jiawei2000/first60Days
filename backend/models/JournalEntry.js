class JournalEntry {
    constructor(id, { awakeTime, cycleNo, feedType, remarks, sleepDuration, startFeedTime, startPlayTime, startSleepTime, stool, urine }) {
        this.id = id;
        this.awakeTime = awakeTime; //date time stamp
        this.cycleNo = cycleNo;
        this.feedType = feedType;
        this.remarks = remarks;
        this.sleepDuration = sleepDuration;
        this.startFeedTime = startFeedTime; //date time stamp
        this.startPlayTime = startPlayTime;//date time stamp
        this.startSleepTime = startSleepTime;//date time stamp
        this.stool = stool;
        this.urine = urine;
    }
}
module.exports = JournalEntry;
