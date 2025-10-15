import '/app/networking/journal_api_service.dart';
import '/app/networking/user_api_service.dart';
import '/app/models/journal_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/config/keys.dart';
import 'package:nylo_framework/nylo_framework.dart';


class CalendarController {
  final JournalApiService _journalApiService = JournalApiService();

  /// Fetch journal entries and group them by date
  Future<Map<DateTime, List<Map<String, dynamic>>>> getCalendarData() async {
    final babyId = await Keys.selectedBabyId.read();
    if (babyId == null) {
      debugPrint("❌ No baby selected");
      return {}; // or return null / throw depending on context
    }

    // Fetch raw data from API service
    final rawData = await _journalApiService.findAllforBabyId(query: babyId);

    // Convert to list of JournalEntry objects safely
    List<JournalEntry> entries = [];
    if (rawData != null) {
      entries = (rawData as List)
          .map((json) => JournalEntry.fromJson(json))
          .toList();
    }

    entries.sort((a, b) {
      final aWake =
          a.startWakeTime?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bWake =
          b.startWakeTime?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aWake.compareTo(bWake);
    });

    Map<DateTime, List<Map<String, dynamic>>> events = {};

    if (entries.isNotEmpty) {
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final wakeTime = entry.startWakeTime?.toUtc() ?? DateTime.now();
        final localDay = DateTime(wakeTime.year, wakeTime.month, wakeTime.day);
        final eventTime = DateFormat('hh:mm a').format(wakeTime);

        events.putIfAbsent(localDay, () => []).add({
          "title": "Feed ${i + 1}",
          "time": eventTime,
          "entryId": entry.id,
          "status": (entry.startFeedTime != null && entry.startSleepTime != null)
                  ? "Complete"
                  : "Incomplete",
        });
      }
    }

    return events;
  }

  Future<void> updateJournalEntry({
  required String entryId,
  required String babyId,
    required dynamic data,
}) async {
  try {
    await _journalApiService.updateJournalEntry(
      entryId: entryId,
      babyId: babyId,
      data: data,
    );
  } catch (e) {
    debugPrint("Update failed: $e");
  }
}

  /// Fetch a specific journal entry from the API by entry ID
  Future<JournalEntry?> getJournalEntryById(String entryId) async {
    final babyId = await Keys.selectedBabyId.read();
    debugPrint("👶 Selected Baby ID: $babyId");

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
