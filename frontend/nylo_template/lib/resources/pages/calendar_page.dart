import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:table_calendar/table_calendar.dart';
import '/app/controllers/calendar_controller.dart';
import '/resources/pages/create_journal_entry_page.dart';

class CalendarPage extends NyStatefulWidget {
  static RouteView path = ("/calendar", (_) => CalendarPage());

  CalendarPage({Key? key}) : super(child: () => _CalendarPageState());
}

class _CalendarPageState extends NyPage<CalendarPage> {
  final CalendarController _controller = CalendarController(); 

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  Map<DateTime, List<Map<String, String>>> _eventData = {};

  @override
  get init => () async {
        _eventData = await _controller.getCalendarData(); 
        setState(() {});
      };

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    return _eventData[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Baby Chloe"),
        actions: [
          TextButton(
            onPressed: () {
              routeTo(CreateJournalEntryPage.path);
            },
            child: Text(
              "Create New Entry",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: _eventData.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Info banner
                  Container(
                    color: Colors.purple.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.purple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "This week your baby will learn to…..",
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Dismiss logic
                          },
                          child: Icon(Icons.close),
                        )
                      ],
                    ),
                  ),

                  // Calendar widget
                  TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    eventLoader: _getEventsForDay,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                    ),
                  ),

                  // Selected day label
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "Week 3 Day 1", // Still hardcoded
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Events list
                  Expanded(
                    child: ListView(
                      children: _getEventsForDay(_selectedDay ?? _focusedDay)
                          .map((event) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                                child: Card(
                                  child: ListTile(
                                    leading: Icon(Icons.brightness_1,
                                        size: 12, color: Colors.purple),
                                    title: Text(event['title'] ?? ''),
                                    subtitle: Text(event['time'] ?? ''),
                                    trailing: Icon(Icons.more_vert),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
