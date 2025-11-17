class Notification {
  constructor(id, {userId, message, readAt, createdAt, deletedAt, topic = null, level = "normal",}) {
    this.id = id;
    this.userId = userId;
    this.message = message;
    this.readAt = readAt;
    this.createdAt = createdAt;
    this.deletedAt = deletedAt;
    this.topic = topic;
    this.level = level;
  }

  static fromFirestore(doc) {
    const data = doc.data();
    return new Notification(doc.id, data);
  }

  toFirestore() {
    return {
      userId: this.userId,
      message: this.message,
      readAt: this.readAt,
      createdAt: this.createdAt,
      deletedAt: this.deletedAt,
      topic: this.topic,
      level: this.level,
    };
  }
}

module.exports = Notification;