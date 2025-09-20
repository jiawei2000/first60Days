import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

final baseUrl = dotenv.env['BASE_URL'];

class JournalAPI {
  static Future getJournalEntries() async {
    final getJournalEntriesURL = Uri.parse(
      '$baseUrl/journalEntries/getEntries',
    );

    // Hardcoded token for testing
    final token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IlZERjc1WEdqdG45UTBzaUdyYlZlIiwiZW1haWwiOiJob25nd2VpQGdtYWlsLmNvbSIsImlhdCI6MTc1ODMwMTQ0MSwiZXhwIjoxNzU4Mzg3ODQxfQ.iTlcRICBF1iARkYXy2LndSQYqHJ-2c0zzrmeJJizVAE";

    return http.post(
      getJournalEntriesURL,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({"babyId": "W6bOM4UJxxfbo0bktsmO"}),
    );
  }
}
