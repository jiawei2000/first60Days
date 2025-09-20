import 'package:best_flutter_ui_templates/model/journal_entry.dart';
import 'package:best_flutter_ui_templates/network/journal_api.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
class MonthView extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const MonthView({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _showWarning = true;

  List<JournalEntry> journalEntries = [];

  void _getJournalEntries() {
    debugPrint("Reach AAA");
    JournalAPI.getJournalEntries().then((response) {
      debugPrint("Response status: ${response.statusCode}");
      // debugPrint("Response body: ${response.body}");
      setState(() {
        Iterable list = json.decode(response.body);
        journalEntries = list
            .map((journalEntry) => JournalEntry.fromJson(journalEntry))
            .toList();
      });

      // For debugging
      for (var entry in journalEntries) {
        debugPrint("Journal entry: ${entry.id}");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
    _selectedDay = widget.selectedDate;
    _getJournalEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              if (_showWarning)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _warningBanner(
                    () => setState(() => _showWarning = false),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    widget.onDateSelected(selectedDay);
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronVisible: true,
                    rightChevronVisible: true,
                    titleTextStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (date.day % 3 == 0) {
                        return const Positioned(
                          bottom: 4,
                          child: Icon(Icons.circle, size: 6, color: Colors.red),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),

          // Draggable pull-up event details
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.2,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
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
                    _buildDaySectionHeader(_selectedDay),
                    const SizedBox(height: 8),
                    _eventListForDay(_selectedDay),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // ➕ Floating button
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventForm,
        backgroundColor: const Color(0xFF2F80ED),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEventForm() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Wrap(
            children: [
              const Text(
                "Add Event",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Time",
                  hintText: "e.g. 10:00 – 12:00",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Save logic
                  },
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDaySectionHeader(DateTime date) {
    final today = DateTime.now();
    final isToday = isSameDay(date, today);
    final isTomorrow = isSameDay(date, today.add(const Duration(days: 1)));

    String label;
    if (isToday) {
      label = "TODAY";
    } else if (isTomorrow) {
      label = "TOMORROW";
    } else {
      label = DateFormat.EEEE().format(date).toUpperCase();
    }

    return Row(
      children: [
        Text(
          "$label ${DateFormat.yMMMMd().format(date)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _eventListForDay(DateTime day) {
    if (day.day % 2 == 0) {
      return Column(
        children: const [
          _EventTile(
            time: "7:15 – 8:00 AM",
            title: "Prep and arrive",
            color: Colors.green,
          ),
          _EventTile(
            time: "8:00 – 9:30 AM",
            title: "Family time",
            color: Colors.orange,
          ),
          _EventTile(
            time: "9:30 AM – 12:30 PM",
            title: "Church",
            color: Colors.yellow,
          ),
          _EventTile(
            time: "1:00 – 3:30 PM",
            title: "Calendar app rewrite research",
            color: Colors.blue,
          ),
        ],
      );
    } else {
      return const Text("No events", style: TextStyle(color: Colors.grey));
    }
  }

  Widget _warningBanner(VoidCallback onClose) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Multiple cycles this month may overlap with feeding times. Tap on days to review.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final String time;
  final String title;
  final Color color;

  const _EventTile({
    required this.time,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, size: 12, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(time),
    );
  }
}
