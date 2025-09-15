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
    //{
    //  count: 3,  
    //  cycle: 1,3,4
    // }
    let interval = {
      count: 0,
      cycleNo: [] // store cycle references
    };

    // Sort entries by timestamp for interval calculation
    //how does the sorting works?
    const sortedEntries = [...this.entries].sort(
      (a, b) => new Date(a.awakeTime) - new Date(b.awakeTime)
    );

    for (const entry of sortedEntries) {
      if (entry.type === "urine") urineCount++;
      if (entry.type === "stool") stoolCount++;
    }

    // Interval calculation:
    // difference in hours between consecutive entries
    for (let i = 1; i < sortedEntries.length; i++) {
      const prevTime = new Date(sortedEntries[i - 1].timestamp);
      const currTime = new Date(sortedEntries[i].timestamp);
      const diffHours = (currTime - prevTime) / (1000 * 60 * 60);

      //if diffHours <= 2.5 hours, increase interval count and 
      if (diffHours <= 2.5) { // to be updated 
        interval.count += 1
        interval.cycleNo.push(sortedEntries[i - 1].id); //push previous entryId into cycleNo 
      }
    }

    return { entryCount, urineCount, stoolCount, interval };
  }
}

module.exports = Check;
