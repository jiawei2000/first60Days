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
    let interval = {
      count: 0,
      cycleNo: [] // store cycle references
    };

    // Sort entries by timestamp for interval calculation
    //how does the sorting works?
    const sortedEntries = [...this.entries].sort(
      (a, b) => new Date(a.awakeTime) - new Date(b.awakeTime)
    );
    // console.log(sortedEntries);

    for (const entry of sortedEntries) {
      if (entry.urine === true) urineCount++;
      if (entry.stool === true) stoolCount++;
    }

    // Interval calculation:
    // difference in hours between consecutive entries
    for (let i = 1; i < sortedEntries.length; i++) {
      const prevTime = sortedEntries[i - 1].awakeTime.toDate();
      const currTime = sortedEntries[i].awakeTime.toDate();
      const diffHours = (currTime - prevTime) / (1000 * 60 * 60);
      // console.log("prev: " + prevTime);
      // console.log("curr: " + currTime);
      // console.log("Diff: " + diffHours);
      //if diffHours <= 2.5 hours, increase interval count and push Id
      if (diffHours < 2.5) {
        interval.count += 1
        interval.cycleNo.push(sortedEntries[i - 1].id); //push previous entryId into cycleNo 
      }
    }

    return { entryCount, urineCount, stoolCount, interval };
  }
}

module.exports = Check;
