class Trainer {
    constructor(id, { username, email, password }) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.password = password;
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
        };
    }
}
module.exports = Trainer;