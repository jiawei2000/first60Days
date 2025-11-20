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

  // static async importJournalEntriesFromExcel(babyId, fileBufferOrPath) {
  //   if (!babyId) throw new Error('babyId is required');

  //   const ExcelJS = require('exceljs');

  //   // ---- Load workbook
  //   const workbook = new ExcelJS.Workbook();
  //   if (Buffer.isBuffer(fileBufferOrPath)) {
  //     await workbook.xlsx.load(fileBufferOrPath);
  //   } else if (typeof fileBufferOrPath === 'string') {
  //     await workbook.xlsx.readFile(fileBufferOrPath);
  //   } else {
  //     throw new Error('fileBufferOrPath must be a Buffer or a file path string');
  //   }

  //   console.log(
  //     '[importJournalEntriesFromExcel] Sheets:',
  //     workbook.worksheets.map(ws => ({
  //       name: ws.name,
  //       rowCount: ws.rowCount
  //     }))
  //   );

  //   const ws = workbook.worksheets[0];
  //   if (!ws) throw new Error('No worksheets found in Excel');

  //   // ---- Header map (normalize spaces/newlines)
  //   const headers = {};
  //   ws.getRow(1).eachCell((cell, colNumber) => {
  //     const name = String(cell.value || '')
  //       .replace(/\r/g, '')
  //       .replace(/\s+/g, ' ')
  //       .trim();
  //     headers[name] = colNumber;
  //   });

  //   const getValue = (row, header) => {
  //     const idx = headers[header];
  //     if (!idx) return null;
  //     const cell = row.getCell(idx);
  //     return cell?.value ?? null;
  //   };

  //   const getDateCell = (row) => {
  //     const idx = headers['Date'];
  //     if (!idx) return null;
  //     const cell = row.getCell(idx);
  //     if (!cell) return null;
  //     return cell;
  //   };

  //   // Desired allowed date range (inclusive) based on what you *see* in Excel
  //   const MIN_ALLOWED = new Date(2021, 5, 29); // 2021-06-29 (month 0-based)
  //   const MAX_ALLOWED = new Date(2021, 9, 8);  // 2021-10-08

  //   // Parse a "date-like" value to a Date at local midnight.
  //   // Priority: Date / number from cell.value. String only as fallback.
  //   const parseToDate = (value) => {
  //     if (value == null) return null;

  //     // Already a JS Date (from ExcelJS)
  //     if (value instanceof Date) {
  //       const yyyy = value.getFullYear();
  //       const mm = value.getMonth();
  //       const dd = value.getDate();
  //       if (yyyy < 1900 || yyyy > 2100) {
  //         console.warn('[importJournalEntriesFromExcel] Date out of range (Date):', value);
  //         return null;
  //       }
  //       return new Date(yyyy, mm, dd, 0, 0, 0, 0);
  //     }

  //     // Excel serial number
  //     if (typeof value === 'number') {
  //       if (value < 1) {
  //         console.warn('[importJournalEntriesFromExcel] Numeric < 1 in Date column, skipping:', value);
  //         return null;
  //       }
  //       let whole = Math.floor(value);

  //       // Excel's fake 1900 leap year (serial >= 60)
  //       if (whole > 59) whole -= 1;

  //       const epoch = new Date(1899, 11, 30, 0, 0, 0, 0); // 1899-12-30
  //       const d = new Date(epoch.getTime() + whole * 86400000);

  //       const yyyy = d.getFullYear();
  //       if (yyyy < 1900 || yyyy > 2100) {
  //         console.warn('[importJournalEntriesFromExcel] Serial produced weird date:', value, d);
  //         return null;
  //       }
  //       return new Date(yyyy, d.getMonth(), d.getDate(), 0, 0, 0, 0);
  //     }

  //     // Rich text / formula objects
  //     if (typeof value === 'object') {
  //       if (value.text)           return parseToDate(value.text);
  //       if (value.result != null) return parseToDate(value.result);
  //       console.warn('[importJournalEntriesFromExcel] Unknown object in Date column:', value);
  //       return null;
  //     }

  //     if (typeof value === 'string') {
  //       const s = value.trim();

  //       // 1) Try MM/DD/YYYY strictly
  //       const m = s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  //       if (m) {
  //         const mm = Number(m[1]); // 1..12
  //         const dd = Number(m[2]); // 1..31
  //         const yyyy = Number(m[3]);

  //         if (mm < 1 || mm > 12 || dd < 1 || dd > 31 || yyyy < 1900 || yyyy > 2100) {
  //           console.warn('[importJournalEntriesFromExcel] Date out of plausible range (string):', s);
  //           return null;
  //         }
  //         return new Date(yyyy, mm - 1, dd, 0, 0, 0, 0);
  //       }

  //       // 2) Fallback: generic JS parser (for those JS-style strings if they ever show up here)
  //       const d = new Date(s);
  //       if (!isNaN(d)) {
  //         const yyyy = d.getFullYear();
  //         const mm = d.getMonth();
  //         const dd = d.getDate();
  //         if (yyyy < 1900 || yyyy > 2100) {
  //           console.warn('[importJournalEntriesFromExcel] Parsed Date out of range (fallback string):', s, d);
  //           return null;
  //         }
  //         return new Date(yyyy, mm, dd, 0, 0, 0, 0);
  //       }

  //       console.warn('[importJournalEntriesFromExcel] Unparsable Date string:', s);
  //       return null;
  //     }

  //     console.warn('[importJournalEntriesFromExcel] Unsupported type in Date column:', value);
  //     return null;
  //   };

  //   // Attempt to correct MM/DD vs DD/MM for ambiguous dates using the known allowed range
  //   const fixAmbiguousDateIfNeeded = (d) => {
  //     if (!d) return d;

  //     const yyyy = d.getFullYear();
  //     let mm = d.getMonth() + 1; // 1..12
  //     let dd = d.getDate();      // 1..31

  //     const inRange =
  //       d.getTime() >= MIN_ALLOWED.getTime() &&
  //       d.getTime() <= MAX_ALLOWED.getTime();

  //     // Only try to "fix" if it's currently out of range
  //     if (inRange) return d;

  //     // Only consider swapping when both month and day are <= 12 (ambiguous dates)
  //     if (mm <= 12 && dd <= 12) {
  //       const swapped = new Date(yyyy, dd - 1, mm, 0, 0, 0, 0);
  //       const swappedInRange =
  //         swapped.getTime() >= MIN_ALLOWED.getTime() &&
  //         swapped.getTime() <= MAX_ALLOWED.getTime();

  //       if (swappedInRange) {
  //         console.log('[importJournalEntriesFromExcel] Swapping ambiguous date (MM/DD <-> DD/MM):', {
  //           original: `${yyyy}-${String(mm).padStart(2, '0')}-${String(dd).padStart(2, '0')}`,
  //           fixed: `${swapped.getFullYear()}-${String(swapped.getMonth() + 1).padStart(2, '0')}-${String(swapped.getDate()).padStart(2, '0')}`
  //         });
  //         return swapped;
  //       }
  //     }

  //     return d;
  //   };

  //   // Convert time cell to Date using a fallback date (local TZ).
  //   const toTimeOnDate = (v, fallbackDate) => {
  //     if (!fallbackDate) return null;
  //     let h = 0, m = 0, s = 0;

  //     if (v instanceof Date) {
  //       h = v.getHours(); m = v.getMinutes(); s = v.getSeconds();
  //     } else if (typeof v === 'number') {
  //       const totalSeconds = Math.round((v % 1) * 86400);
  //       h = Math.floor(totalSeconds / 3600);
  //       m = Math.floor((totalSeconds % 3600) / 60);
  //       s = totalSeconds % 60;
  //     } else if (typeof v === 'string') {
  //       const t = v.trim();
  //       const tm = t.match(/^(\d{1,2}):(\d{2})(?::(\d{2}))?$/);
  //       if (tm) {
  //         h = Number(tm[1]); m = Number(tm[2]); s = Number(tm[3] || 0);
  //       } else {
  //         const d = new Date(t);
  //         if (!isNaN(d)) return d;
  //         return null;
  //       }
  //     } else {
  //       return null;
  //     }

  //     const d = new Date(fallbackDate);
  //     d.setHours(h, m, s, 0);
  //     return d;
  //   };

  //   const toBool = (v) => {
  //     const s = String(v ?? '').trim().toLowerCase();
  //     if (['yes', 'true', 'y', '1'].includes(s)) return true;
  //     if (['no', 'false', 'n', '0'].includes(s)) return false;
  //     if (typeof v === 'number') return v !== 0;
  //     return false;
  //   };

  //   // ---- Build raw rows
  //   const raw = [];
  //   const outOfRangeExamples = {};

  //   ws.eachRow((row, rowNum) => {
  //     if (rowNum === 1) return; // skip header

  //     const dateCell = getDateCell(row);
  //     const rawVal   = dateCell ? dateCell.value : null;
  //     const textVal  = dateCell ? dateCell.text  : null;

  //     // Debug first / last few
  //     if (rowNum <= 5 || rowNum >= ws.rowCount - 5) {
  //       console.log(
  //         `[Row ${rowNum}] Date cell:`,
  //         {
  //           value: rawVal,
  //           typeofValue: typeof rawVal,
  //           text: textVal
  //         }
  //       );
  //     }

  //     // Prefer the true cell.value (Date/number). Fallback to text only if needed.
  //     let dayDate = parseToDate(
  //       rawVal != null && rawVal !== ''
  //         ? rawVal
  //         : (textVal != null && textVal !== '' ? textVal : null)
  //     );

  //     if (!dayDate) {
  //       console.warn(`Skipping row ${rowNum} — invalid Date cell:`, { value: rawVal, text: textVal });
  //       return;
  //     }

  //     // Fix ambiguous MM/DD vs DD/MM if needed
  //     dayDate = fixAmbiguousDateIfNeeded(dayDate);

  //     // Hard date range filter 2021-06-29..2021-10-08
  //     if (dayDate < MIN_ALLOWED || dayDate > MAX_ALLOWED) {
  //       const monthKey = `${dayDate.getFullYear()}-${String(dayDate.getMonth() + 1).padStart(2, '0')}`;
  //       if (!outOfRangeExamples[monthKey]) {
  //         outOfRangeExamples[monthKey] = {
  //           row: rowNum,
  //           rawValue: rawVal,
  //           rawText: textVal,
  //           parsed: [
  //             dayDate.getFullYear(),
  //             String(dayDate.getMonth() + 1).padStart(2, '0'),
  //             String(dayDate.getDate()).padStart(2, '0')
  //           ].join('-')
  //         };
  //       }
  //       return;
  //     }

  //     const awakeTime      = toTimeOnDate(getValue(row, 'Wake Up Time'), dayDate);
  //     const startFeedTime  = toTimeOnDate(getValue(row, 'Start of Feed'), dayDate);
  //     const startPlayTime  = toTimeOnDate(getValue(row, 'Start of Play'), dayDate);
  //     const startSleepTime = toTimeOnDate(getValue(row, 'Start of Sleep'), dayDate);

  //     const hasUrine = toBool(getValue(row, 'Pee'));
  //     const hasStool = toBool(getValue(row, 'Poo'));
  //     const remarks  = String(getValue(row, 'Remarks') ?? '').trim();

  //     // Sleep duration: minutes -> hours (number)
  //     let sleepHours;
  //     const sleepMinRaw = getValue(row, 'Sleep Duration (min)');
  //     if (sleepMinRaw === '' || sleepMinRaw == null || Number.isNaN(Number(sleepMinRaw))) {
  //       sleepHours = undefined;
  //     } else {
  //       const mins = Number(sleepMinRaw);
  //       sleepHours = mins >= 0 ? +(mins / 60).toFixed(2) : undefined;
  //     }

  //     const n = (x) => Number(x ?? 0) || 0;
  //     const ebmMl     = n(getValue(row, 'EBM (ml)'));
  //     const formulaMl = n(getValue(row, 'Formula (ml)'));
  //     const breastR   = n(getValue(row, 'Feed Duration on R breast (min)'));
  //     const breastL   = n(getValue(row, 'Feed Duration on L breast (min)'));

  //     const feedType = [];
  //     if (ebmMl > 0)     feedType.push({ type: 'ebm',              unit: 'ml',      value: ebmMl });
  //     if (formulaMl > 0) feedType.push({ type: 'formula',          unit: 'ml',      value: formulaMl });
  //     if (breastR > 0)   feedType.push({ type: 'breastfeed_right', unit: 'minutes', value: breastR });
  //     if (breastL > 0)   feedType.push({ type: 'breastfeed_left',  unit: 'minutes', value: breastL });

  //     const meaningful =
  //       awakeTime || startFeedTime || startPlayTime || startSleepTime ||
  //       feedType.length || remarks || hasUrine || hasStool || sleepHours != null;

  //     if (!meaningful) return;

  //     const dayKey = [
  //       dayDate.getFullYear(),
  //       String(dayDate.getMonth() + 1).padStart(2, '0'),
  //       String(dayDate.getDate()).padStart(2, '0')
  //     ].join('-');

  //     const sortTime =
  //       (startFeedTime ? startFeedTime.getTime() :
  //       (awakeTime ? awakeTime.getTime() : 0));

  //     raw.push({
  //       _dayKey: dayKey,
  //       _dayDate: dayDate,
  //       _sort: sortTime,
  //       awakeTime: awakeTime || undefined,
  //       startFeedTime: startFeedTime || undefined,
  //       startPlayTime: startPlayTime || undefined,
  //       startSleepTime: startSleepTime || undefined,
  //       hasUrine,
  //       hasStool,
  //       remarks,
  //       sleepDuration: sleepHours,
  //       feedType
  //     });
  //   });

  //   console.log('[importJournalEntriesFromExcel] Out-of-range month examples:', outOfRangeExamples);

  //   if (raw.length > 0) {
  //     const sortedByDate = raw
  //       .slice()
  //       .sort((a, b) => a._dayDate.getTime() - b._dayDate.getTime());

  //     const minDate = sortedByDate[0]._dayDate;
  //     const maxDate = sortedByDate[sortedByDate.length - 1]._dayDate;

  //     const formatDateKey = (d) => [
  //       d.getFullYear(),
  //       String(d.getMonth() + 1).padStart(2, '0'),
  //       String(d.getDate()).padStart(2, '0')
  //     ].join('-');

  //     console.log(
  //       '[importJournalEntriesFromExcel] Imported date range (by calendar day AFTER filter):',
  //       formatDateKey(minDate),
  //       '→',
  //       formatDateKey(maxDate)
  //     );

  //     const perMonth = new Map();
  //     for (const r of raw) {
  //       const key = `${r._dayDate.getFullYear()}-${String(r._dayDate.getMonth() + 1).padStart(2, '0')}`;
  //       perMonth.set(key, (perMonth.get(key) || 0) + 1);
  //     }
  //     console.log(
  //       '[importJournalEntriesFromExcel] Entries per month from Excel AFTER filter:',
  //       Object.fromEntries(perMonth)
  //     );
  //   } else {
  //     console.warn('[importJournalEntriesFromExcel] No meaningful rows found in allowed date range.');
  //   }

  //   // ---- Group by day and assign cycleNo
  //   const byDay = new Map();
  //   for (const r of raw) {
  //     if (!byDay.has(r._dayKey)) byDay.set(r._dayKey, []);
  //     byDay.get(r._dayKey).push(r);
  //   }

  //   const kept = [];
  //   for (const [, arr] of byDay) {
  //     arr.sort((a, b) => a._sort - b._sort);
  //     kept.push(...arr.map((e, i) => ({ ...e, cycleNo: i + 1 })));
  //   }

  //   // ---- Compute missing sleepDuration from Start of Sleep -> next Awake Time
  //   const chron = kept.slice().sort((a, b) => {
  //     const da = a._dayDate.getTime() - b._dayDate.getTime();
  //     if (da !== 0) return da;
  //     return a._sort - b._sort;
  //   });

  //   for (let i = 0; i < chron.length; i++) {
  //     const cur = chron[i];

  //     if (cur.sleepDuration == null) {
  //       let hours = undefined;

  //       if (cur.startSleepTime) {
  //         let end = null;
  //         for (let j = i + 1; j < chron.length; j++) {
  //           if (chron[j].awakeTime) { end = chron[j].awakeTime; break; }
  //         }
  //         if (end) {
  //           const diffMin = Math.max(0, Math.round((end - cur.startSleepTime) / 60000));
  //           hours = diffMin / 60;
  //         }
  //       }

  //       if (hours == null || !isFinite(hours) || hours < 0) hours = 0;
  //       if (hours > 12) hours = 12;
  //       cur.sleepDuration = +hours.toFixed(2);
  //     }
  //   }

  //   // ---- Persist
  //   const created = [];
  //   for (const e of chron) {
  //     const { _dayKey, _dayDate, _sort, ...payload } = e;
  //     const clean = Object.fromEntries(
  //       Object.entries(payload).filter(([, v]) => v !== undefined)
  //     );
  //     const res = await JournalService.createEntry(babyId, clean);
  //     created.push(res);
  //   }

  //   console.log(
  //     `[importJournalEntriesFromExcel] Created ${created.length} entries from Excel (rows in allowed range)`
  //   );

  //   return { count: chron.length };
  // }

  static async importJournalEntriesFromExcel(babyId, fileBufferOrPath) {
    if (!babyId) throw new Error('babyId is required');

    const ExcelJS = require('exceljs');

    // ---- Load workbook
    const workbook = new ExcelJS.Workbook();
    if (Buffer.isBuffer(fileBufferOrPath)) {
      await workbook.xlsx.load(fileBufferOrPath);
    } else if (typeof fileBufferOrPath === 'string') {
      await workbook.xlsx.readFile(fileBufferOrPath);
    } else {
      throw new Error('fileBufferOrPath must be a Buffer or a file path string');
    }

    const ws = workbook.worksheets[0];
    if (!ws) throw new Error('No worksheets found in Excel');

    // ---- Header map (normalize spaces/newlines)
    const headers = {};
    ws.getRow(1).eachCell((cell, colNumber) => {
      const name = String(cell.value || '')
        .replace(/\r/g, '')
        .replace(/\s+/g, ' ')
        .trim();
      headers[name] = colNumber;
    });

    const getValue = (row, header) => {
      const idx = headers[header];
      if (!idx) return null;
      const cell = row.getCell(idx);
      return cell?.value ?? null;
    };

    const getDateCell = (row) => {
      const idx = headers['Date'];
      if (!idx) return null;
      const cell = row.getCell(idx);
      if (!cell) return null;
      return cell;
    };

    const MMDD_RE = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/;

    const formatYmd = (d) =>
      `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

    const formatDateKey = (d) => [
      d.getFullYear(),
      String(d.getMonth() + 1).padStart(2, '0'),
      String(d.getDate()).padStart(2, '0')
    ].join('-');

    // ---- Core parser (hoisted so we can reuse it)
    function parseToDate(value) {
      if (value == null) return null;

      // Already a JS Date (from ExcelJS)
      if (value instanceof Date) {
        const yyyy = value.getFullYear();
        const mm = value.getMonth();
        const dd = value.getDate();
        if (yyyy < 1900 || yyyy > 2100) {
          return null;
        }
        return new Date(yyyy, mm, dd, 0, 0, 0, 0);
      }

      // Excel serial number
      if (typeof value === 'number') {
        if (value < 1) {
          return null;
        }
        let whole = Math.floor(value);

        // Excel's fake 1900 leap year (serial >= 60)
        if (whole > 59) whole -= 1;

        const epoch = new Date(1899, 11, 30, 0, 0, 0, 0); // 1899-12-30
        const d = new Date(epoch.getTime() + whole * 86400000);

        const yyyy = d.getFullYear();
        if (yyyy < 1900 || yyyy > 2100) {
          return null;
        }
        return new Date(yyyy, d.getMonth(), d.getDate(), 0, 0, 0, 0);
      }

      // Rich text / formula objects
      if (typeof value === 'object') {
        if (value.text)           return parseToDate(value.text);
        if (value.result != null) return parseToDate(value.result);
        return null;
      }

      if (typeof value === 'string') {
        const s = value.trim();

        // 1) Try MM/DD/YYYY strictly
        const m = s.match(MMDD_RE);
        if (m) {
          const mm = Number(m[1]); // 1..12
          const dd = Number(m[2]); // 1..31
          const yyyy = Number(m[3]);

          if (mm < 1 || mm > 12 || dd < 1 || dd > 31 || yyyy < 1900 || yyyy > 2100) {
            return null;
          }
          return new Date(yyyy, mm - 1, dd, 0, 0, 0, 0);
        }

        // 2) Fallback: generic JS parser
        const d = new Date(s);
        if (!isNaN(d)) {
          const yyyy = d.getFullYear();
          const mm = d.getMonth();
          const dd = d.getDate();
          if (yyyy < 1900 || yyyy > 2100) {
            return null;
          }
          return new Date(yyyy, mm, dd, 0, 0, 0, 0);
        }

        return null;
      }

      return null;
    }

    // ---- FIRST PASS: derive allowed range from candidates
    // Candidates include:
    //   - All MM/DD/YYYY text dates (what the user *sees*),
    //   - PLUS the "swapped" version of ambiguous Date/number rows.
    const rangeCandidates = [];

    ws.eachRow((row, rowNum) => {
      if (rowNum === 1) return; // skip header

      const dateCell = getDateCell(row);
      if (!dateCell) return;

      const rawVal  = dateCell.value;
      const textVal = dateCell.text != null ? String(dateCell.text).trim() : '';

      let parseSource = null;
      let fromMmddText = false;

      if (typeof textVal === 'string') {
        const s = textVal.trim();
        if (MMDD_RE.test(s)) {
          parseSource = s;
          fromMmddText = true;
        }
      }

      if (parseSource == null && rawVal != null && rawVal !== '') {
        parseSource = rawVal;
      }

      if (parseSource == null && textVal) {
        parseSource = textVal;
      }

      const d = parseToDate(parseSource);
      if (!d) return;

      const yyyy = d.getFullYear();
      const mm   = d.getMonth() + 1; // 1..12
      const dd   = d.getDate();      // 1..31

      if (fromMmddText) {
        // Visible MM/DD/YYYY dates are *definitely* part of the intended range
        rangeCandidates.push(d);
      } else {
        // Ambiguous numeric/Date cells: both month and day <= 12
        if (mm <= 12 && dd <= 12) {
          const swapped = new Date(yyyy, dd - 1, mm, 0, 0, 0, 0);
          rangeCandidates.push(swapped);
        } else {
          // Otherwise, just use d as-is as a candidate (not ambiguous)
          rangeCandidates.push(d);
        }
      }
    });

    let MIN_ALLOWED = null;
    let MAX_ALLOWED = null;

    if (rangeCandidates.length > 0) {
      rangeCandidates.sort((a, b) => a.getTime() - b.getTime());
      MIN_ALLOWED = rangeCandidates[0];
      MAX_ALLOWED = rangeCandidates[rangeCandidates.length - 1];
    }

    // ---- Ambiguity fixer now uses the derived MIN_ALLOWED / MAX_ALLOWED
    const fixAmbiguousDateIfNeeded = (d) => {
      if (!d) return d;
      if (!MIN_ALLOWED || !MAX_ALLOWED) return d;

      const yyyy = d.getFullYear();
      let mm = d.getMonth() + 1; // 1..12
      let dd = d.getDate();      // 1..31

      const inRange =
        d.getTime() >= MIN_ALLOWED.getTime() &&
        d.getTime() <= MAX_ALLOWED.getTime();

      if (inRange) return d;

      // Only consider swapping when both month and day are <= 12 (ambiguous dates)
      if (mm <= 12 && dd <= 12) {
        const swapped = new Date(yyyy, dd - 1, mm, 0, 0, 0, 0);
        const swappedInRange =
          swapped.getTime() >= MIN_ALLOWED.getTime() &&
          swapped.getTime() <= MAX_ALLOWED.getTime();

        if (swappedInRange) {
          return swapped;
        }
      }

      return d;
    };

    // ---- Time, bool, etc helpers (unchanged)
    const toTimeOnDate = (v, fallbackDate) => {
      if (!fallbackDate) return null;
      let h = 0, m = 0, s = 0;

      if (v instanceof Date) {
        h = v.getHours(); m = v.getMinutes(); s = v.getSeconds();
      } else if (typeof v === 'number') {
        const totalSeconds = Math.round((v % 1) * 86400);
        h = Math.floor(totalSeconds / 3600);
        m = Math.floor((totalSeconds % 3600) / 60);
        s = totalSeconds % 60;
      } else if (typeof v === 'string') {
        const t = v.trim();
        const tm = t.match(/^(\d{1,2}):(\d{2})(?::(\d{2}))?$/);
        if (tm) {
          h = Number(tm[1]); m = Number(tm[2]); s = Number(tm[3] || 0);
        } else {
          const d = new Date(t);
          if (!isNaN(d)) return d;
          return null;
        }
      } else {
        return null;
      }

      const d = new Date(fallbackDate);
      d.setHours(h, m, s, 0);
      return d;
    };

    const toBool = (v) => {
      const s = String(v ?? '').trim().toLowerCase();
      if (['yes', 'true', 'y', '1'].includes(s)) return true;
      if (['no', 'false', 'n', '0'].includes(s)) return false;
      if (typeof v === 'number') return v !== 0;
      return false;
    };

    // ---- Build raw rows
    const raw = [];

    ws.eachRow((row, rowNum) => {
      if (rowNum === 1) return; // skip header

      const dateCell = getDateCell(row);
      const rawVal   = dateCell ? dateCell.value : null;
      const textVal  = dateCell ? dateCell.text  : null;

      // Prefer the visible MM/DD/YYYY text (what user sees), so we don't get
      // bitten by ExcelJS / locale quirks on Date/number.
      let parseSource = null;

      if (typeof textVal === 'string') {
        const s = textVal.trim();
        if (MMDD_RE.test(s)) {
          parseSource = s;
        }
      }

      if (parseSource == null && rawVal != null && rawVal !== '') {
        parseSource = rawVal;
      }

      if (parseSource == null && typeof textVal === 'string' && textVal.trim() !== '') {
        parseSource = textVal.trim();
      }

      let dayDate = parseToDate(parseSource);

      if (!dayDate) {
        return;
      }

      // Fix ambiguous MM/DD vs DD/MM if needed using derived allowed range
      dayDate = fixAmbiguousDateIfNeeded(dayDate);

      // Hard date range filter based on derived MIN_ALLOWED / MAX_ALLOWED,
      // matching the behaviour of the original hard-coded version.
      if (MIN_ALLOWED && MAX_ALLOWED && (dayDate < MIN_ALLOWED || dayDate > MAX_ALLOWED)) {
        return;
      }

      const awakeTime      = toTimeOnDate(getValue(row, 'Wake Up Time'), dayDate);
      const startFeedTime  = toTimeOnDate(getValue(row, 'Start of Feed'), dayDate);
      const startPlayTime  = toTimeOnDate(getValue(row, 'Start of Play'), dayDate);
      const startSleepTime = toTimeOnDate(getValue(row, 'Start of Sleep'), dayDate);

      const hasUrine = toBool(getValue(row, 'Pee'));
      const hasStool = toBool(getValue(row, 'Poo'));
      const remarks  = String(getValue(row, 'Remarks') ?? '').trim();

      // Sleep duration: minutes -> hours (number)
      let sleepHours;
      const sleepMinRaw = getValue(row, 'Sleep Duration (min)');
      if (sleepMinRaw === '' || sleepMinRaw == null || Number.isNaN(Number(sleepMinRaw))) {
        sleepHours = undefined;
      } else {
        const mins = Number(sleepMinRaw);
        sleepHours = mins >= 0 ? +(mins / 60).toFixed(2) : undefined;
      }

      const n = (x) => Number(x ?? 0) || 0;
      const ebmMl     = n(getValue(row, 'EBM (ml)'));
      const formulaMl = n(getValue(row, 'Formula (ml)'));
      const breastR   = n(getValue(row, 'Feed Duration on R breast (min)'));
      const breastL   = n(getValue(row, 'Feed Duration on L breast (min)'));

      const feedType = [];
      if (ebmMl > 0)     feedType.push({ type: 'ebm',              unit: 'ml',      value: ebmMl });
      if (formulaMl > 0) feedType.push({ type: 'formula',          unit: 'ml',      value: formulaMl });
      if (breastR > 0)   feedType.push({ type: 'breastfeed_right', unit: 'minutes', value: breastR });
      if (breastL > 0)   feedType.push({ type: 'breastfeed_left',  unit: 'minutes', value: breastL });

      const meaningful =
        awakeTime || startFeedTime || startPlayTime || startSleepTime ||
        feedType.length || remarks || hasUrine || hasStool || sleepHours != null;

      if (!meaningful) return;

      const dayKey = [
        dayDate.getFullYear(),
        String(dayDate.getMonth() + 1).padStart(2, '0'),
        String(dayDate.getDate()).padStart(2, '0')
      ].join('-');

      const sortTime =
        (startFeedTime ? startFeedTime.getTime() :
        (awakeTime ? awakeTime.getTime() : 0));

      raw.push({
        _dayKey: dayKey,
        _dayDate: dayDate,
        _sort: sortTime,
        awakeTime: awakeTime || undefined,
        startFeedTime: startFeedTime || undefined,
        startPlayTime: startPlayTime || undefined,
        startSleepTime: startSleepTime || undefined,
        hasUrine,
        hasStool,
        remarks,
        sleepDuration: sleepHours,
        feedType
      });
    });

    // ---- Group by day and assign cycleNo
    const byDay = new Map();
    for (const r of raw) {
      if (!byDay.has(r._dayKey)) byDay.set(r._dayKey, []);
      byDay.get(r._dayKey).push(r);
    }

    const kept = [];
    for (const [, arr] of byDay) {
      arr.sort((a, b) => a._sort - b._sort);
      kept.push(...arr.map((e, i) => ({ ...e, cycleNo: i + 1 })));
    }

    // ---- Compute missing sleepDuration from Start of Sleep -> next Awake Time
    const chron = kept.slice().sort((a, b) => {
      const da = a._dayDate.getTime() - b._dayDate.getTime();
      if (da !== 0) return da;
      return a._sort - b._sort;
    });

    for (let i = 0; i < chron.length; i++) {
      const cur = chron[i];

      if (cur.sleepDuration == null) {
        let hours = undefined;

        if (cur.startSleepTime) {
          let end = null;
          for (let j = i + 1; j < chron.length; j++) {
            if (chron[j].awakeTime) { end = chron[j].awakeTime; break; }
          }
          if (end) {
            const diffMin = Math.max(0, Math.round((end - cur.startSleepTime) / 60000));
            hours = diffMin / 60;
          }
        }

        if (hours == null || !isFinite(hours) || hours < 0) hours = 0;
        if (hours > 12) hours = 12;
        cur.sleepDuration = +hours.toFixed(2);
      }
    }

    // ---- Persist
    const created = [];
    for (const e of chron) {
      const { _dayKey, _dayDate, _sort, ...payload } = e;
      const clean = Object.fromEntries(
        Object.entries(payload).filter(([, v]) => v !== undefined)
      );
      const res = await JournalService.createEntry(babyId, clean);
      created.push(res);
    }

    return { count: chron.length };
  }

  static async importFakeDataExcel(babyId, fileBufferOrPath) {
    if (!babyId) throw new Error('babyId is required');

    const ExcelJS = require('exceljs');

    // ---- Load workbook
    const workbook = new ExcelJS.Workbook();
    if (Buffer.isBuffer(fileBufferOrPath)) {
      await workbook.xlsx.load(fileBufferOrPath);
    } else if (typeof fileBufferOrPath === 'string') {
      await workbook.xlsx.readFile(fileBufferOrPath);
    } else {
      throw new Error('fileBufferOrPath must be a Buffer or a file path string');
    }

    const ws = workbook.worksheets[0];
    if (!ws) throw new Error('No worksheets found in Excel');

    // ---- Header map (normalize spaces/newlines)
    const headers = {};
    ws.getRow(1).eachCell((cell, colNumber) => {
      const name = String(cell.value || '')
        .replace(/\r/g, '')
        .replace(/\s+/g, ' ')
        .trim();
      headers[name] = colNumber;
    });

    const getValue = (row, header) => {
      const idx = headers[header];
      if (!idx) return null;
      const cell = row.getCell(idx);
      return cell?.value ?? null;
    };

    const getDateCell = (row) => {
      const idx = headers['Date'];
      if (!idx) return null;
      const cell = row.getCell(idx);
      if (!cell) return null;
      return cell;
    };

    const MMDD_RE = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/;

    const formatYmd = (d) =>
      `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

    const formatDateKey = (d) => [
      d.getFullYear(),
      String(d.getMonth() + 1).padStart(2, '0'),
      String(d.getDate()).padStart(2, '0')
    ].join('-');

    // ---- Core parser (hoisted so we can reuse it)
    function parseToDate(value) {
      if (value == null) return null;

      // Already a JS Date (from ExcelJS)
      if (value instanceof Date) {
        const yyyy = value.getFullYear();
        const mm = value.getMonth();
        const dd = value.getDate();
        if (yyyy < 1900 || yyyy > 2100) {
          return null;
        }
        return new Date(yyyy, mm, dd, 0, 0, 0, 0);
      }

      // Excel serial number
      if (typeof value === 'number') {
        if (value < 1) {
          return null;
        }
        let whole = Math.floor(value);

        // Excel's fake 1900 leap year (serial >= 60)
        if (whole > 59) whole -= 1;

        const epoch = new Date(1899, 11, 30, 0, 0, 0, 0); // 1899-12-30
        const d = new Date(epoch.getTime() + whole * 86400000);

        const yyyy = d.getFullYear();
        if (yyyy < 1900 || yyyy > 2100) {
          return null;
        }
        return new Date(yyyy, d.getMonth(), d.getDate(), 0, 0, 0, 0);
      }

      // Rich text / formula objects
      if (typeof value === 'object') {
        if (value.text)           return parseToDate(value.text);
        if (value.result != null) return parseToDate(value.result);
        return null;
      }

      if (typeof value === 'string') {
        const s = value.trim();

        // 1) Try MM/DD/YYYY strictly
        const m = s.match(MMDD_RE);
        if (m) {
          const mm = Number(m[1]); // 1..12
          const dd = Number(m[2]); // 1..31
          const yyyy = Number(m[3]);

          if (mm < 1 || mm > 12 || dd < 1 || dd > 31 || yyyy < 1900 || yyyy > 2100) {
            return null;
          }
          return new Date(yyyy, mm - 1, dd, 0, 0, 0, 0);
        }

        // 2) Fallback: generic JS parser
        const d = new Date(s);
        if (!isNaN(d)) {
          const yyyy = d.getFullYear();
          const mm = d.getMonth();
          const dd = d.getDate();
          if (yyyy < 1900 || yyyy > 2100) {
            return null;
          }
          return new Date(yyyy, mm, dd, 0, 0, 0, 0);
        }

        return null;
      }

      return null;
    }

    // ---- FIRST PASS: derive allowed range from candidates
    const rangeCandidates = [];

    ws.eachRow((row, rowNum) => {
      if (rowNum === 1) return; // skip header

      const dateCell = getDateCell(row);
      if (!dateCell) return;

      const rawVal  = dateCell.value;
      const textVal = dateCell.text != null ? String(dateCell.text).trim() : '';

      let parseSource = null;
      let fromMmddText = false;

      if (typeof textVal === 'string') {
        const s = textVal.trim();
        if (MMDD_RE.test(s)) {
          parseSource = s;
          fromMmddText = true;
        }
      }

      if (parseSource == null && rawVal != null && rawVal !== '') {
        parseSource = rawVal;
      }

      if (parseSource == null && textVal) {
        parseSource = textVal;
      }

      const d = parseToDate(parseSource);
      if (!d) return;

      const yyyy = d.getFullYear();
      const mm   = d.getMonth() + 1; // 1..12
      const dd   = d.getDate();      // 1..31

      if (fromMmddText) {
        rangeCandidates.push(d);
      } else {
        if (mm <= 12 && dd <= 12) {
          const swapped = new Date(yyyy, dd - 1, mm, 0, 0, 0, 0);
          rangeCandidates.push(swapped);
        } else {
          rangeCandidates.push(d);
        }
      }
    });

    let MIN_ALLOWED = null;
    let MAX_ALLOWED = null;

    if (rangeCandidates.length > 0) {
      rangeCandidates.sort((a, b) => a.getTime() - b.getTime());
      MIN_ALLOWED = rangeCandidates[0];
      MAX_ALLOWED = rangeCandidates[rangeCandidates.length - 1];
    }

    // ---- Ambiguity fixer now uses the derived MIN_ALLOWED / MAX_ALLOWED
    const fixAmbiguousDateIfNeeded = (d) => {
      if (!d) return d;
      if (!MIN_ALLOWED || !MAX_ALLOWED) return d;

      const yyyy = d.getFullYear();
      let mm = d.getMonth() + 1; // 1..12
      let dd = d.getDate();      // 1..31

      const inRange =
        d.getTime() >= MIN_ALLOWED.getTime() &&
        d.getTime() <= MAX_ALLOWED.getTime();

      if (inRange) return d;

      if (mm <= 12 && dd <= 12) {
        const swapped = new Date(yyyy, dd - 1, mm, 0, 0, 0, 0);
        const swappedInRange =
          swapped.getTime() >= MIN_ALLOWED.getTime() &&
          swapped.getTime() <= MAX_ALLOWED.getTime();

        if (swappedInRange) {
          return swapped;
        }
      }

      return d;
    };

    // ---- Time, bool, etc helpers (unchanged)
    const toTimeOnDate = (v, fallbackDate) => {
      if (!fallbackDate) return null;
      let h = 0, m = 0, s = 0;

      if (v instanceof Date) {
        h = v.getHours(); m = v.getMinutes(); s = v.getSeconds();
      } else if (typeof v === 'number') {
        const totalSeconds = Math.round((v % 1) * 86400);
        h = Math.floor(totalSeconds / 3600);
        m = Math.floor((totalSeconds % 3600) / 60);
        s = totalSeconds % 60;
      } else if (typeof v === 'string') {
        const t = v.trim();
        const tm = t.match(/^(\d{1,2}):(\d{2})(?::(\d{2}))?$/);
        if (tm) {
          h = Number(tm[1]); m = Number(tm[2]); s = Number(tm[3] || 0);
        } else {
          const d = new Date(t);
          if (!isNaN(d)) return d;
          return null;
        }
      } else {
        return null;
      }

      const d = new Date(fallbackDate);
      d.setHours(h, m, s, 0);
      return d;
    };

    const toBool = (v) => {
      const s = String(v ?? '').trim().toLowerCase();
      if (['yes', 'true', 'y', '1'].includes(s)) return true;
      if (['no', 'false', 'n', '0'].includes(s)) return false;
      if (typeof v === 'number') return v !== 0;
      return false;
    };

    const adjustTimeForDate = (time, newBaseDate) => {
      if (!time) return time;
      const d = new Date(newBaseDate);
      d.setHours(time.getHours(), time.getMinutes(), time.getSeconds(), 0);
      return d;
    };

    // ---- Build raw rows
    const raw = [];

    ws.eachRow((row, rowNum) => {
      if (rowNum === 1) return; // skip header

      const dateCell = getDateCell(row);
      const rawVal   = dateCell ? dateCell.value : null;
      const textVal  = dateCell ? dateCell.text  : null;

      let parseSource = null;

      if (typeof textVal === 'string') {
        const s = textVal.trim();
        if (MMDD_RE.test(s)) {
          parseSource = s;
        }
      }

      if (parseSource == null && rawVal != null && rawVal !== '') {
        parseSource = rawVal;
      }

      if (parseSource == null && typeof textVal === 'string' && textVal.trim() !== '') {
        parseSource = textVal.trim();
      }

      let dayDate = parseToDate(parseSource);
      if (!dayDate) return;

      dayDate = fixAmbiguousDateIfNeeded(dayDate);

      if (MIN_ALLOWED && MAX_ALLOWED && (dayDate < MIN_ALLOWED || dayDate > MAX_ALLOWED)) {
        return;
      }

      const awakeTime      = toTimeOnDate(getValue(row, 'Wake Up Time'), dayDate);
      const startFeedTime  = toTimeOnDate(getValue(row, 'Start of Feed'), dayDate);
      const startPlayTime  = toTimeOnDate(getValue(row, 'Start of Play'), dayDate);
      const startSleepTime = toTimeOnDate(getValue(row, 'Start of Sleep'), dayDate);

      const hasUrine = toBool(getValue(row, 'Pee'));
      const hasStool = toBool(getValue(row, 'Poo'));
      const remarks  = String(getValue(row, 'Remarks') ?? '').trim();

      let sleepHours;
      const sleepMinRaw = getValue(row, 'Sleep Duration (min)');
      if (sleepMinRaw === '' || sleepMinRaw == null || Number.isNaN(Number(sleepMinRaw))) {
        sleepHours = undefined;
      } else {
        const mins = Number(sleepMinRaw);
        sleepHours = mins >= 0 ? +(mins / 60).toFixed(2) : undefined;
      }

      const n = (x) => Number(x ?? 0) || 0;
      const ebmMl     = n(getValue(row, 'EBM (ml)'));
      const formulaMl = n(getValue(row, 'Formula (ml)'));
      const breastR   = n(getValue(row, 'Feed Duration on R breast (min)'));
      const breastL   = n(getValue(row, 'Feed Duration on L breast (min)'));

      const feedType = [];
      if (ebmMl > 0)     feedType.push({ type: 'ebm',              unit: 'ml',      value: ebmMl });
      if (formulaMl > 0) feedType.push({ type: 'formula',          unit: 'ml',      value: formulaMl });
      if (breastR > 0)   feedType.push({ type: 'breastfeed_right', unit: 'minutes', value: breastR });
      if (breastL > 0)   feedType.push({ type: 'breastfeed_left',  unit: 'minutes', value: breastL });

      const meaningful =
        awakeTime || startFeedTime || startPlayTime || startSleepTime ||
        feedType.length || remarks || hasUrine || hasStool || sleepHours != null;

      if (!meaningful) return;

      const dayKey = formatDateKey(dayDate);

      const sortTime =
        (startFeedTime ? startFeedTime.getTime() :
        (awakeTime ? awakeTime.getTime() : 0));

      raw.push({
        _dayKey: dayKey,
        _dayDate: dayDate,
        _sort: sortTime,
        awakeTime: awakeTime || undefined,
        startFeedTime: startFeedTime || undefined,
        startPlayTime: startPlayTime || undefined,
        startSleepTime: startSleepTime || undefined,
        hasUrine,
        hasStool,
        remarks,
        sleepDuration: sleepHours,
        feedType
      });
    });

    // ---- REMAP DATES TO FAKE YEAR/MONTHS
    // Year: 2025
    // First source month -> September (8)
    // Max fake date: 21 November 2025
    const BASE_YEAR = 2025;
    const BASE_MONTH_INDEX = 8; // September (0-based)
    const MAX_FAKE_DATE = new Date(BASE_YEAR, 10, 21, 23, 59, 59, 999); // 2025-11-21

    const bySourceChron = raw
      .slice()
      .sort((a, b) => {
        const da = a._dayDate.getTime() - b._dayDate.getTime();
        if (da !== 0) return da;
        return a._sort - b._sort;
      });

    let lastSourceMonth = null;
    let monthOffset = 0;

    for (const r of bySourceChron) {
      const srcMonth = r._dayDate.getMonth(); // 0..11
      const srcDay   = r._dayDate.getDate();

      if (lastSourceMonth === null) {
        lastSourceMonth = srcMonth;
      } else if (srcMonth !== lastSourceMonth) {
        lastSourceMonth = srcMonth;
        monthOffset++;
      }

      // Target month: starting from September, increasing with each new source month.
      let targetMonthIndex = BASE_MONTH_INDEX + monthOffset;
      if (targetMonthIndex > 11) {
        // Clamp at December to keep everything in 2025
        targetMonthIndex = 11;
      }

      const fakeDate = new Date(BASE_YEAR, targetMonthIndex, srcDay, 0, 0, 0, 0);

      // --- NEW: skip any rows that would fall after 21 November 2025
      if (fakeDate.getTime() > MAX_FAKE_DATE.getTime()) {
        r._skip = true;
        continue;
      }

      r._dayDate = fakeDate;
      r._dayKey = formatDateKey(fakeDate);
      r.awakeTime      = adjustTimeForDate(r.awakeTime,      fakeDate);
      r.startFeedTime  = adjustTimeForDate(r.startFeedTime,  fakeDate);
      r.startPlayTime  = adjustTimeForDate(r.startPlayTime,  fakeDate);
      r.startSleepTime = adjustTimeForDate(r.startSleepTime, fakeDate);
      r._sort =
        (r.startFeedTime ? r.startFeedTime.getTime() :
        (r.awakeTime ? r.awakeTime.getTime() : 0));
    }

    // ---- Group by day and assign cycleNo (using remapped dates)
    const byDay = new Map();
    for (const r of raw) {
      if (r._skip) continue;              // <-- ignore skipped rows
      if (!byDay.has(r._dayKey)) byDay.set(r._dayKey, []);
      byDay.get(r._dayKey).push(r);
    }

    const kept = [];
    for (const [, arr] of byDay) {
      arr.sort((a, b) => a._sort - b._sort);
      kept.push(...arr.map((e, i) => ({ ...e, cycleNo: i + 1 })));
    }

    // ---- Compute missing sleepDuration from Start of Sleep -> next Awake Time
    const chron = kept.slice().sort((a, b) => {
      const da = a._dayDate.getTime() - b._dayDate.getTime();
      if (da !== 0) return da;
      return a._sort - b._sort;
    });

    for (let i = 0; i < chron.length; i++) {
      const cur = chron[i];

      if (cur.sleepDuration == null) {
        let hours = undefined;

        if (cur.startSleepTime) {
          let end = null;
          for (let j = i + 1; j < chron.length; j++) {
            if (chron[j].awakeTime) { end = chron[j].awakeTime; break; }
          }
          if (end) {
            const diffMin = Math.max(0, Math.round((end - cur.startSleepTime) / 60000));
            hours = diffMin / 60;
          }
        }

        if (hours == null || !isFinite(hours) || hours < 0) hours = 0;
        if (hours > 12) hours = 12;
        cur.sleepDuration = +hours.toFixed(2);
      }
    }

    // ---- Persist
    const created = [];
    for (const e of chron) {
      const { _dayKey, _dayDate, _sort, ...payload } = e;
      const clean = Object.fromEntries(
        Object.entries(payload).filter(([, v]) => v !== undefined)
      );
      const res = await JournalService.createEntry(babyId, clean);
      created.push(res);
    }

    return { count: chron.length };
  }

}

module.exports = ExcelService;