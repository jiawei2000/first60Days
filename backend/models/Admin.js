class Admin {
    constructor(id, { username, email, password, name, address, createdAt, deletedAt = null, lastLoginAt = null }) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.password = password;
        this.name = name;
        this.address = address;
        this.createdAt = createdAt;
        this.deletedAt = deletedAt;
        this.lastLoginAt = lastLoginAt;
    }

    // convenience method to map Firestore doc -> User instance
    static fromFirestore(doc) {
        const data = doc.data();
        return new Admin(doc.id, data);
    }

    // convert to plain object (for saving)
    toFirestore() {
        return {
            username: this.username,
            email: this.email,
            password: this.password,
            name: this.name,
            address: this.address,
            createdAt: this.createdAt,
            deletedAt: this.deletedAt,
            lastLoginAt: this.lastLoginAt,
        };
    }
}
module.exports = Admin;