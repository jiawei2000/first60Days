import 'package:best_flutter_ui_templates/model/feed_type.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../../model/journal_entry.dart';

final baseUrl = dotenv.env['BASE_URL'];

class JournalAPI {
  // Hardcoded token for testing
  static final token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IlZERjc1WEdqdG45UTBzaUdyYlZlIiwiZW1haWwiOiJob25nd2VpQGdtYWlsLmNvbSIsImlhdCI6MTc1ODM4OTAyNSwiZXhwIjoxNzU4NDc1NDI1fQ.BzN2jq_glQ4xNSXuxwtp3LSzw2VzwLim5S0E1PBilqo";
  static Future getJournalEntries(String babyId) async {
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

  static Future createJournalEntry(String babyId, JournalEntry entry) async {
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
        "stool": entry.hasStool,
        "urine": entry.hasUrine,
        "awakeTime": entry.startWakeTime?.toIso8601String(),
        "feedType": entry.feedTypes,
        "startFeedTime": entry.startFeedTime?.toIso8601String(),
        "startPlayTime": entry.startPlayTime?.toIso8601String(),
        "startSleepTime": entry.startSleepTime?.toIso8601String(),
      }),
    );
  }
}
