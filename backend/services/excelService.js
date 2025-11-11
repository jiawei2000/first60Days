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

    const get = (row, header) => {
      const idx = headers[header];
      if (!idx) return null;
      const cell = row.getCell(idx);
      return cell?.value ?? null;
    };

    // Parse "MM/DD/YYYY" strictly -> Date at local midnight
    const parseMDY = (s) => {
      if (s instanceof Date) return new Date(s.getFullYear(), s.getMonth(), s.getDate(), 0, 0, 0, 0);
      if (typeof s === 'number') {
        // Excel serial date (>=1 means has a date component)
        const whole = Math.floor(s);
        const epoch = new Date(Date.UTC(1899, 11, 30)); // Excel 1900 epoch
        const d = new Date(epoch.getTime() + whole * 86400000);
        return new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0);
      }
      if (typeof s === 'string') {
        const m = s.trim().match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
        if (!m) return null;
        const mm = Number(m[1]);
        const dd = Number(m[2]);
        const yyyy = Number(m[3]);
        return new Date(yyyy, mm - 1, dd, 0, 0, 0, 0);
      }
      return null;
    };

    // Convert time cell to Date using a fallback date (local TZ).
    // Accepts: Date, "HH:mm[:ss]" string, Excel serial (fractional day).
    const toTimeOnDate = (v, fallbackDate) => {
      if (!fallbackDate) return null; // require date context for time-only
      let h = 0, m = 0, s = 0;

      if (v instanceof Date) {
        h = v.getHours(); m = v.getMinutes(); s = v.getSeconds();
      } else if (typeof v === 'number') {
        // Excel stores time as fraction of a day (0..1)
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
          if (!isNaN(d)) return d; // full datetime string
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
      if (rowNum === 1) return;

      const dateCell = get(row, 'Date');
      let dayDate = parseMDY(dateCell);

      // If Date cell is missing but one of the time cells is a full Date, use that date
      if (!dayDate) {
        const candidates = [
          get(row, 'Wake Up Time'),
          get(row, 'Start of Feed'),
          get(row, 'Start of Play'),
          get(row, 'Start of Sleep'),
        ];
        for (const c of candidates) {
          if (c instanceof Date && c.getFullYear() > 1900) {
            dayDate = new Date(c.getFullYear(), c.getMonth(), c.getDate());
            break;
          }
        }
      }
      if (!dayDate) return; // row unusable without a date context

      const awakeTime = toTimeOnDate(get(row, 'Wake Up Time'), dayDate);
      const startFeedTime = toTimeOnDate(get(row, 'Start of Feed'), dayDate);
      const startPlayTime = toTimeOnDate(get(row, 'Start of Play'), dayDate);
      const startSleepTime = toTimeOnDate(get(row, 'Start of Sleep'), dayDate);

      const hasUrine = toBool(get(row, 'Pee'));
      const hasStool = toBool(get(row, 'Poo'));
      const remarks = String(get(row, 'Remarks') ?? '').trim();

      // Sleep duration: minutes -> hours (number)
      let sleepHours;
      const sleepMinRaw = get(row, 'Sleep Duration (min)');
      if (sleepMinRaw === '' || sleepMinRaw == null || Number.isNaN(Number(sleepMinRaw))) {
        sleepHours = undefined; // compute later if possible
      } else {
        const mins = Number(sleepMinRaw);
        sleepHours = mins >= 0 ? +(mins / 60).toFixed(2) : undefined;
      }

      const n = (x) => Number(x ?? 0) || 0;
      const ebmMl = n(get(row, 'EBM (ml)'));
      const formulaMl = n(get(row, 'Formula (ml)'));
      const breastR = n(get(row, 'Feed Duration on R breast (min)'));
      const breastL = n(get(row, 'Feed Duration on L breast (min)'));

      const feedType = [];
      if (ebmMl > 0) feedType.push({ type: 'ebm', unit: 'ml', value: ebmMl });
      if (formulaMl > 0) feedType.push({ type: 'formula', unit: 'ml', value: formulaMl });
      if (breastR > 0) feedType.push({ type: 'breastfeed_right', unit: 'minutes', value: breastR });
      if (breastL > 0) feedType.push({ type: 'breastfeed_left', unit: 'minutes', value: breastL });

      const meaningful =
        awakeTime || startFeedTime || startPlayTime || startSleepTime ||
        feedType.length || remarks || hasUrine || hasStool || sleepHours != null;
      if (!meaningful) return;

      const key = `${dayDate.getMonth() + 1}/${dayDate.getDate()}/${dayDate.getFullYear()}`;

      raw.push({
        _dayKey: key,
        _dayDate: dayDate,
        _sort: startFeedTime ? startFeedTime.getTime() : (awakeTime ? awakeTime.getTime() : 0),
        awakeTime: awakeTime || undefined,
        startFeedTime: startFeedTime || undefined,
        startPlayTime: startPlayTime || undefined,
        startSleepTime: startSleepTime || undefined,
        hasUrine,
        hasStool,
        remarks,
        sleepDuration: sleepHours, // hours (number or undefined for now)
        feedType,
        // never set "status" here
      });
    });

    // ---- Group by day and cap to 8 per day
    const byDay = new Map();
    for (const r of raw) {
      if (!byDay.has(r._dayKey)) byDay.set(r._dayKey, []);
      byDay.get(r._dayKey).push(r);
    }
    const kept = [];
    for (const [, arr] of byDay) {
      arr.sort((a, b) => a._sort - b._sort);
      kept.push(...arr.slice(0, 8).map((e, i) => ({ ...e, cycleNo: i + 1 })));
    }

    // ---- Compute missing sleepDuration from Start of Sleep -> next Awake Time
    // Build a single chronological sequence across days
    const chron = kept.slice().sort((a, b) => a._sort - b._sort);

    for (let i = 0; i < chron.length; i++) {
      const cur = chron[i];

      if (cur.sleepDuration == null) {
        let hours = undefined;

        if (cur.startSleepTime) {
          // find next entry that has an awakeTime
          let end = null;
          for (let j = i + 1; j < chron.length; j++) {
            if (chron[j].awakeTime) { end = chron[j].awakeTime; break; }
          }
          if (end) {
            const diffMin = Math.max(0, Math.round((end - cur.startSleepTime) / 60000));
            hours = diffMin / 60;
          }
        }

        // sanitize: clamp to [0, 12], round to 2dp, guarantee a number
        if (hours == null || !isFinite(hours) || hours < 0) hours = 0;
        if (hours > 12) hours = 12;
        cur.sleepDuration = +hours.toFixed(2);
      }
    }

    // ---- Persist
    const created = [];
    for (const e of chron) {
      const { _dayKey, _dayDate, _sort, ...payload } = e; // strip helper fields
      const clean = Object.fromEntries(Object.entries(payload).filter(([, v]) => v !== undefined));
      const res = await JournalService.createEntry(babyId, clean);
      created.push(res);
    }

    return { count: chron.length };
  }


}

module.exports = ExcelService;