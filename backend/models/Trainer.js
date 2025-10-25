class Trainer {
    constructor(id, { username, email, password, name, createdAt, deletedAt, lastLoginAt, createdByAdminID }) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.password = password;
        this.name = name;
        this.createdAt = createdAt;
        this.deletedAt = deletedAt;
        this.lastLoginAt = lastLoginAt;
        this.createdByAdminID = createdByAdminID;
    }

    // convenience method to map Firestore doc -> User instance
    static fromFirestore(doc) {
        const data = doc.data();
        return new Trainer(doc.id, data);
    }

    // convert to plain object (for saving)
    toFirestore() {
        return {
            username: this.username,
            email: this.email,
            password: this.password,
            name: this.name,
            createdAt: this.createdAt,
            deletedAt: this.deletedAt,
            lastLoginAt: this.lastLoginAt,
            createdByAdminID: this.createdByAdminID,
        };
    }
}
module.exports = Trainer;