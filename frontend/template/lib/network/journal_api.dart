import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../../model/journal_entry.dart';

final baseUrl = dotenv.env['BASE_URL'];

class JournalAPI {
  // Hardcoded token for testing
  static final token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IlZERjc1WEdqdG45UTBzaUdyYlZlIiwiZW1haWwiOiJob25nd2VpQGdtYWlsLmNvbSIsImlhdCI6MTc1ODMwMTQ0MSwiZXhwIjoxNzU4Mzg3ODQxfQ.iTlcRICBF1iARkYXy2LndSQYqHJ-2c0zzrmeJJizVAE";

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
      }),
    );
  }
}
