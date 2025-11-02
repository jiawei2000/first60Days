// services/ExcelService.js
const UserService = require('./userService.js');
const ExcelBuilder = require('../utils/excelBuilder.js');

const BabyService = require('./babyService.js');
const JournalService = require('./journalService.js');

function tsToISO(value) {
  if (!value) return '';
  // Firestore Timestamp
  if (value.seconds != null && value.nanoseconds != null && typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }
  // Date
  if (value instanceof Date) return value.toISOString();
  // number (ms)
  if (typeof value === 'number') return new Date(value).toISOString();
  // string
  if (typeof value === 'string') {
    const d = new Date(value);
    return isNaN(d) ? '' : d.toISOString();
  }
  return '';
}

function safeName(name = 'baby') {
  return String(name).replace(/[^\w\-]+/g, '_').slice(0, 60);
}

class ExcelService {
  static async exportUsersToExcel() {
    // 1. Fetch domain objects
    const users = await UserService.getAllUsers();

    // 2. Convert models -> plain rows that ExcelBuilder understands
    const rows = users.map(u => ({
      Name: u.name ?? u.fullName ?? '',
      Email: u.email ?? '',
      PhoneNo: u.phoneNo ?? '',
      Relation: u.relation ?? '',
    }));

    // 3. Build workbook
    const buffer = await ExcelBuilder.buildWorkbookBuffer({
      sheetName: 'Users',
      rows,
      columnsConfig: {
        Name: { width: 25 },
        Email: { width: 30 },
        PhoneNo: { width: 15 },
        Relation: { width: 25 },
      },
    });

    return {
      filename: `userData_${new Date()
        .toISOString()
        .split('T')[0]}.xlsx`,
      mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      buffer,
    };
  }

  static async exportJournalEntriesToExcel(babyId) {
    if (!babyId) throw new Error('babyId is required');

    const baby = await BabyService.getProfileById(babyId);
    if (!baby) throw new Error('Baby not found');

    // Always fetch from subcollection
    const entries = await JournalService.getEntries(babyId);

    // Build rows
    const rows = (entries || []).map(e => ({
      'Cycle #': e.cycleNo ?? '',
      'Start Feed Time': tsToISO(e.startFeedTime),
      'Start Sleep Time': tsToISO(e.startSleepTime),
      'Start Play Time': tsToISO(e.startPlayTime),
      'Awake Time': tsToISO(e.awakeTime),
      'Sleep Duration (min)': e.sleepDuration ?? '',
      'Feed Types': Array.isArray(e.feedType)
        ? e.feedType.map(ft =>
            typeof ft === 'string' ? ft : (ft?.type ?? ft?.name ?? '')
          ).filter(Boolean).join(', ')
        : '',
      'Has Stool': e.hasStool ? 'Yes' : 'No',
      'Has Urine': e.hasUrine ? 'Yes' : 'No',
      Remarks: e.remarks ?? '',
    }));

    // Optional: if truly no entries, you can either throw or include a single row
    // if (rows.length === 0) throw new Error('No journal entries found for this baby');

    const buffer = await ExcelBuilder.buildWorkbookBuffer({
      sheetName: 'Journal Entries',
      rows,
      columnsConfig: {
        'Cycle #': { width: 10 },
        'Start Feed Time': { width: 22 },
        'Start Sleep Time': { width: 22 },
        'Start Play Time': { width: 22 },
        'Awake Time': { width: 22 },
        'Sleep Duration (min)': { width: 20 },
        'Feed Types': { width: 28 },
        'Has Stool': { width: 12 },
        'Has Urine': { width: 12 },
        'Baby Name': { width: 22 },
        'Baby DOB': { width: 22 },
        Remarks: { width: 40 },
      },
    });

    const filename = `Baby Journal - ${safeName(baby.name)}_${new Date()
      .toISOString()
      .split('T')[0]}.xlsx`;

    return {
      filename,
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      buffer,
    };
  }

}

module.exports = ExcelService;