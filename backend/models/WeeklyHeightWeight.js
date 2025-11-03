class WeeklyHeightWeight {
  constructor(id, { height, weight, babyIDRef, createdAt }) {
    this.id = id;

    this.height = height;
    this.weight = weight;
    this.babyIDRef = babyIDRef;

    this.createdAt = createdAt;
  }

  toFirestore() {
    return {
      height: this.height,
      weight: this.weight,
      babyIDRef: this.babyIDRef,
      createdAt: this.createdAt,
    };
  }

  static fromFirestore(doc) {
    const data = doc.data();
    return new WeeklyHeightWeight(doc.id, data);
  }
}

module.exports = WeeklyHeightWeight;