import '/app/networking/journal_api_service.dart';
import '/app/networking/user_api_service.dart';
import '/app/models/journal_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarController {
  final JournalApiService _journalApiService = JournalApiService();

  /// Fetch calendar events from backend and convert to Map<DateTime, List<Map<String,String>>>
  Future<Map<DateTime, List<Map<String, String>>>> getCalendarData() async {
    // Hardcoded baby ID for now
    const babyId = "W6bOM4UJxxfbo0bktsmO";

    List<JournalEntry>? entries =
        await _journalApiService.findAllforBabyId(query: babyId);

    Map<DateTime, List<Map<String, String>>> events = {};

    if (entries != null) {
      for (var entry in entries) {
        final awakeDate = entry.startWakeTime ?? DateTime.now();
        final dayKey = DateTime(awakeDate.year, awakeDate.month, awakeDate.day);

        if (!events.containsKey(dayKey)) {
          events[dayKey] = [];
        }

        String eventTime = entry.startFeedTime != null
            ? DateFormat('hh:mm a').format(entry.startFeedTime!.toLocal())
            : "No time";

        events[dayKey]!.add({
          "title": "Cycle", // You can add entry.cycleNo if needed
          "time": eventTime,
        });
      }
    }

    return events;
  }

  /// 🔐 Manual login test function to verify token retrieval
  void testLogin() async {
    UserApiService apiService = UserApiService();
    final response = await apiService.login(
      username: "user123",
      password: "password456",
    );

    if (response != null && response.containsKey("token")) {
      print("✅ Token: ${response['token']}");
    } else {
      print("❌ Login failed or token missing.");
    }
  }
}
