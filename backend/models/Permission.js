class Permission {
    constructor(id, { userID, babyIDArr = [], permissionType, createdAt, deletedAt, subAccArr = [] }) {
        this.id = id;
        // this.userID = userID; Firestore ref 
        this.babyIDArr = babyIDArr;
        this.permissionType = permissionType;
        this.createdAt = createdAt;
        this.deletedAt = deletedAt;
        this.subAccArr = subAccArr;
    }

    static fromFirestore(doc) {
        const data = doc.data();
        return new Permission(doc.id, data);
    }

    toFirestore() {
        return {
            userID: this.userID,
            babyIDArr: this.babyIDArr,
            permissionType: this.permissionType,
            createdAt: this.createdAt,
            deletedAt: this.deletedAt,
            subAccArr: this.subAccArr
        };
    }
}

module.exports = Permission;
