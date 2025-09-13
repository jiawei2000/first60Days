// services/checkService.js

class Check {
  constructor(babyId, entries) {
    this.babyId = babyId;
    this.entries = entries || [];
  }

  /**
   * Calculates daily stats from journal entries
   * Returns { entryCount, urineCount, stoolCount, intervalCount }
   */
  calculateStats() {
    let entryCount = this.entries.length;
    let urineCount = 0;
    let stoolCount = 0;
    let intervalCount = 0;

    // Sort entries by timestamp for interval calculation
    const sortedEntries = [...this.entries].sort(
      (a, b) => new Date(a.timestamp) - new Date(b.timestamp)
    );

    for (const entry of sortedEntries) {
      if (entry.type === "urine") urineCount++;
      if (entry.type === "stool") stoolCount++;
    }

    // Example interval calculation:
    // difference in hours between consecutive entries
    for (let i = 1; i < sortedEntries.length; i++) {
      const prevTime = new Date(sortedEntries[i - 1].timestamp);
      const currTime = new Date(sortedEntries[i].timestamp);
      const diffHours = (currTime - prevTime) / (1000 * 60 * 60);

      if (diffHours >= 2) { // to be updated 
        intervalCount++;
      }
    }

    return { entryCount, urineCount, stoolCount, intervalCount };
  }
}

module.exports = Check;
