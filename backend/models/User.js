class User {
    constructor(id, { email, password, phoneNo, username, createdAt, lastLoginAt, deletedAt, permissionID, fcmTokens}) {
        this.id = id;
        //Inputed by user, requires data validation 
        this.email = email; //string 
        this.password = password;//string 
        this.phoneNo = phoneNo;//string 
        this.username = username; //string 
        
        //managed by server
        this.createdAt = createdAt; //timestamp 
        this.lastLoginAt = lastLoginAt; //timestamp 
        this.deletedAt = deletedAt; //timestamp updated by the system 
        this.permissionID = permissionID; //permission document reference created and assigned by the system  

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
            fcmTokens: this.fcmTokens
        };
    }
}

module.exports = User;
