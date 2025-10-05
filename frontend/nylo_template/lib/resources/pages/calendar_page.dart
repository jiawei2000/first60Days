import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '/app/controllers/calendar_controller.dart';
import '/resources/pages/create_journal_entry_page.dart';
import 'package:nylo_framework/nylo_framework.dart'; // ✅ add this

class CalendarPage extends StatefulWidget {
  static RouteView path = ("/calendar", (context) => const CalendarPage());

  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarController _controller = CalendarController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, String>>> _eventData = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    final events = await _controller.getCalendarData();
    setState(() {
      _eventData = events;
    });
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    return _eventData[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Baby Chloe"),
        actions: [
          TextButton(
            onPressed: () {
              /// ✅ Use Nylo's `routeTo` to navigate to CreateJournalEntryPage
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
                            // dismiss banner
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
                      "Events", // later you can show week/day text here
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
