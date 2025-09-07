class Baby {
    constructor(id, { name, dob, createdAt, deletedAt, feedSchedule }) {
        this.id = id;
        this.name = name;
        this.dob = dob;
        this.createdAt = createdAt;
        this.deletedAt = deletedAt;
        this.feedSchedule = feedSchedule;
    }
}
module.exports = Baby;
