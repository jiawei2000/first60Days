import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:nylo_framework/nylo_framework.dart';

import '/app/controllers/calendar_controller.dart';
import '/resources/pages/create_journal_entry_page.dart';

import '/resources/widgets/calendar/info_banner.dart';
import '/resources/widgets/calendar/event_tile.dart';
import '/resources/widgets/calendar/day_section_header.dart';

class CalendarPage extends StatefulWidget {
  static RouteView path = ("/calendar", (context) => const CalendarPage());

  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarController _controller = CalendarController();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, String>>> _eventData = {};
  bool _showBanner = true;

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
    final localDay = DateTime(day.year, day.month, day.day);
    return _eventData[localDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Baby Chloe"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              routeTo(CreateJournalEntryPage.path);
            },
            child: Text(
              "New Entry",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          )
        ],
      ),
      body: _eventData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (_showBanner)
                        InfoBanner(
                          onClose: () => setState(() => _showBanner = false),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TableCalendar(
                          firstDay: DateTime(2020),
                          lastDay: DateTime(2030),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
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
                          headerStyle: const HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            titleTextStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isNotEmpty) {
                                return const Positioned(
                                  bottom: 4,
                                  child:
                                      Icon(Icons.circle, size: 6, color: Colors.purple),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  DraggableScrollableSheet(
                    initialChildSize: 0.45,
                    minChildSize: 0.2,
                    maxChildSize: 0.75,
                    builder: (context, scrollController) {
                      final events = _getEventsForDay(_selectedDay);

                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            DaySectionHeader(date: _selectedDay),
                            const SizedBox(height: 8),
                            if (events.isEmpty)
                              const Text("No events found",
                                  style: TextStyle(color: Colors.grey))
                            else
                              ...events.map((event) => EventTile(
                                    title: event['title'] ?? 'No Title',
                                    subtitle: event['time'] ?? '',
                                    color: Colors.purple,
                                  )),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
