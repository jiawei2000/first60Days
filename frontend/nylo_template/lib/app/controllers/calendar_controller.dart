import '/app/networking/journal_api_service.dart';
import '/app/networking/user_api_service.dart';
import '/app/models/journal_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarController {
  final JournalApiService _journalApiService = JournalApiService();

  /// Fetch journal entries and group them by date
  Future<Map<DateTime, List<Map<String, dynamic>>>> getCalendarData() async {
    const babyId = "W6bOM4UJxxfbo0bktsmO";

    // Fetch raw data from API service
    final rawData = await _journalApiService.findAllforBabyId(query: babyId);

    // Convert to list of JournalEntry objects safely
    List<JournalEntry> entries = [];
    if (rawData != null) {
      entries = (rawData as List)
          .map((json) => JournalEntry.fromJson(json))
          .toList();
    }

    Map<DateTime, List<Map<String, dynamic>>> events = {};

    if (entries.isNotEmpty) {
      for (var entry in entries) {
        final wakeTime = entry.startWakeTime?.toLocal() ?? DateTime.now();
        final localDay = DateTime(wakeTime.year, wakeTime.month, wakeTime.day);

        final feedTime = entry.startFeedTime?.toLocal();
        final eventTime = wakeTime != null
            ? DateFormat('hh:mm a').format(wakeTime)
            : "No time";

        events.putIfAbsent(localDay, () => []).add({
          "title": "Cycle",
          "time": eventTime,
          "entryId": entry.id, 
        });
      }
    }

    return events;
  }

  /// Fetch a specific journal entry from the API by entry ID
  Future<JournalEntry?> getJournalEntryById(String entryId) async {
    const babyId = "W6bOM4UJxxfbo0bktsmO";

    try {
      final response = await _journalApiService.findJournalEntryById(
        babyId: babyId,
        entryId: entryId,
      );

      if (response != null) {
        return JournalEntry.fromJson(response);
      }
    } catch (e) {
      debugPrint("❌ Error fetching journal entry: $e");
    }

    return null;
  }

  /// Manual test login for debugging
  void testLogin() async {
    final apiService = UserApiService();
    final response = await apiService.login(
      username: "user123",
      password: "password456",
    );

    if (response != null && response.containsKey("token")) {
      debugPrint("✅ Token: ${response['token']}");
    } else {
      debugPrint("❌ Login failed or token missing.");
    }
  }
}
