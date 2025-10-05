import '/app/controllers/controller.dart';
import '/app/networking/journal_api_service.dart';
import 'package:flutter/material.dart';

class CalendarController extends Controller {
  final JournalApiService _journalApiService = JournalApiService();

  @override
  construct(BuildContext context) async {
    await super.construct(context);
    // Any additional init logic can go here
  }

  /// Returns a map of events per normalized date
  Future<Map<DateTime, List<Map<String, String>>>> getCalendarData() async {
    await Future.delayed(Duration(seconds: 1)); 

    // Normalize today
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return {
      // 🔹 Today - for immediate testing
      today: [
        {
          "title": "Today's Event",
          "time": "09:00 - 10:00",  
        },
        {
          "title": "Team Check-in",
          "time": "14:00 - 15:00",
        },
      ],

      // 🔹 Future date (for August 2, 2025)
      DateTime(2025, 8, 2): [
        {
          "title": "Cycle 1",
          "time": "10:00 - 13:00",
        },
        {
          "title": "Cycle 2",
          "time": "14:00 - 15:00",
        },
      ],

      // 🔹 Another future date
      DateTime(2025, 8, 3): [
        {
          "title": "Cycle 3",
          "time": "08:00 - 09:30",
        },
      ],
    };
  }
}
