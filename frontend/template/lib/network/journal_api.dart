import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../../model/journal_entry.dart';

final baseUrl = dotenv.env['BASE_URL'];

class JournalAPI {
  /// Get journal entries for a specific baby
  static Future<http.Response> getJournalEntries(
    String babyId,
    String token,
  ) async {
    final getJournalEntriesURL = Uri.parse(
      '$baseUrl/journalEntries/getEntries',
    );

    return http.post(
      getJournalEntriesURL,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({"babyId": babyId}),
    );
  }

  /// Create a new journal entry
  static Future<http.Response> createJournalEntry(
    String babyId,
    JournalEntry entry,
    String token,
  ) async {
    final createJournalEntryURL = Uri.parse(
      '$baseUrl/journalEntries/createEntry',
    );

    return http.post(
      createJournalEntryURL,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        "babyId": babyId,
        "cycleNo": entry.cycleNo,
        "remarks": entry.remarks,
        "hasStool": entry.hasStool,
        "hasUrine": entry.hasUrine,
        "awakeTime": entry.startWakeTime?.toIso8601String(),
        "feedType": entry.feedTypes,
        "startFeedTime": entry.startFeedTime?.toIso8601String(),
        "startPlayTime": entry.startPlayTime?.toIso8601String(),
        "startSleepTime": entry.startSleepTime?.toIso8601String(),
      }),
    );
  }

  // Get a journal entry by ID
  static Future<http.Response> getJournalEntryById(
    String entryId,
    String babyId,
    String token,
  ) async {
    final getJournalEntryURL = Uri.parse(
      '$baseUrl/journalEntries/getEntryById',
    );

    return http.post(
      getJournalEntryURL,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({"entryId": entryId, "babyId": babyId}),
    );
  }

  // Update a journal entry
  static Future<http.Response> updateJournalEntry(
    String entryId,
    String babyId,
    JournalEntry entry,
    String token,
  ) async {
    final updateJournalEntryURL = Uri.parse(
      '$baseUrl/journalEntries/editEntry',
    );
    return http.put(
      updateJournalEntryURL,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        "entryId": entryId,
        "babyId": babyId,
        "updateData": {
          "remarks": entry.remarks,
          "hasStool": entry.hasStool,
          "hasUrine": entry.hasUrine,
          "awakeTime": entry.startWakeTime?.toIso8601String(),
          "feedType": entry.feedTypes,
          "startFeedTime": entry.startFeedTime?.toIso8601String(),
          "startPlayTime": entry.startPlayTime?.toIso8601String(),
          "startSleepTime": entry.startSleepTime?.toIso8601String(),
        },
      }),
    );
  }
}
