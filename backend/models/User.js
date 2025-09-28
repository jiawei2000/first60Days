class User {
    constructor(id, { email, password, phoneNo, username, createdAt, lastLoginAt, deletedAt, permissionID, fcmTokens }) {
        this.id = id;
        this.email = email;
        this.password = password;
        this.phoneNo = phoneNo;
        this.username = username;
        this.createdAt = createdAt;
        this.lastLoginAt = lastLoginAt;
        this.deletedAt = deletedAt;
        this.permissionID = permissionID;
        this.fcmTokens = fcmTokens; // Array, multiple tokens for multiple devices
    }

    // convenience method to map Firestore doc -> User instance
    static fromFirestore(doc) {
        const data = doc.data();
        return new User(doc.id, data);
    }

    // convert to plain object (for saving)
    toFirestore() {
        return {
            email: this.email,
            password: this.password,
            phoneNo: this.phoneNo,
            username: this.username,
            createdAt: this.createdAt,
            lastLoginAt: this.lastLoginAt,
            deletedAt: this.deletedAt,
            permissionID: this.permissionID,
            fcmTokens: this.fcmTokens,
        };
    }
}

module.exports = User;
