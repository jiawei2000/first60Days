import 'package:best_flutter_ui_templates/model/feed_type.dart';
import 'package:best_flutter_ui_templates/model/journal_entry.dart';
import 'package:best_flutter_ui_templates/network/journal_api.dart';
import 'package:best_flutter_ui_templates/screens/providers/widget.dart';
import 'package:best_flutter_ui_templates/routes.dart';
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
  bool _showWarning = false;

  late Map<DateTime, List<JournalEntry>> entriesByDate = {};

  void _getJournalEntries() {
    List<JournalEntry> journalEntries = [];

    debugPrint("Reach AAA");

    final token = get_token(context);
    final babyId = get_babyid(context);

    if (token == null) {
      debugPrint("No token found. User may not be logged in.");
      return;
    }

    debugPrint(" Selected baby ID: $babyId");
    if (babyId == null) {
      debugPrint("No baby ID found. Baby may not be selected.");
      return;
    }

    JournalAPI.getJournalEntries(babyId, token).then((response) {
      setState(() {
        Iterable list = json.decode(response.body);
        journalEntries = list
            .map((journalEntry) => JournalEntry.fromJson(journalEntry))
            .toList();

        // Group entries by startWakeTime date
        for (var entry in journalEntries) {
          if (entry.startWakeTime != null) {
            DateTime date = DateTime(
              entry.startWakeTime!.year,
              entry.startWakeTime!.month,
              entry.startWakeTime!.day,
            );
            entriesByDate.putIfAbsent(date, () => []).add(entry);
          }
          // Update isCompleted status if feedType is not empty only for now
          if (entry.feedTypes != null && entry.feedTypes!.isNotEmpty) {
            entry.isCompleted = true;
          } else {
            entry.isCompleted = false;
          }
        }
      });

      // Print by date for debugging
      for (var date in entriesByDate.keys) {
        debugPrint(
          " Date: $date, No. of entries: ${entriesByDate[date]?.length}",
        );
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
                      // if (date.day % 3 == 0) {
                      //   return const Positioned(
                      //     bottom: 4,
                      //     child: Icon(Icons.circle, size: 6, color: Colors.red),
                      //   );
                      // }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),

          // Draggable pull-up event details
          DraggableScrollableSheet(
            initialChildSize: 0.45,
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
        onPressed: onClickAdd,
        backgroundColor: const Color(0xFF2F80ED),
        child: const Icon(Icons.add),
      ),
    );
  }

  void onClickAdd() {
    // Go to Add Journal Entry page
    // ToDo update passing args
    Navigator.pushNamed(
      context,
      Routes.journal,
      arguments: {'babyId': "W6bOM4UJxxfbo0bktsmO"},
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

  String formatFeedType(List<FeedType> feedTypes) {
    if (feedTypes.isEmpty) {
      return "No feed types";
    } else {
      return feedTypes
          .map(
            (feedType) => "${feedType.type} ${feedType.value}${feedType.unit}",
          )
          .join(", ");
    }
  }

  Widget _eventListForDay(DateTime day) {
    // Convert day to UTC
    final utcDay = DateTime(day.year, day.month, day.day);

    final entriesForDay = entriesByDate[utcDay] ?? [];
    debugPrint("Entries for $utcDay: ${entriesForDay.length}");
    // Sort entries by startWakeTime
    entriesForDay.sort((a, b) {
      if (a.startWakeTime == null && b.startWakeTime == null) return 0;
      if (a.startWakeTime == null) return 1;
      if (b.startWakeTime == null) return -1;
      return a.startWakeTime!.compareTo(b.startWakeTime!);
    });

    if (entriesForDay.isNotEmpty) {
      return Column(
        children: [
          ...entriesForDay.map(
            (entry) => InkWell(
              onTap: () {
                // TODO: Go to Edit page
                Navigator.pushNamed(
                  context,
                  Routes.editJournal,
                  arguments: {
                    'babyId': "W6bOM4UJxxfbo0bktsmO",
                    'journalEntry': entry,
                  },
                );
                debugPrint("Clicked entry: ${entry.id}");
              },
              child: _EventTile(
                subtitle: formatFeedType(entry.feedTypes ?? []),
                title:
                    "Feed ${entriesForDay.indexOf(entry) + 1} - ${DateFormat.Hm().format(entry.startWakeTime!)}",
                color: entry.isCompleted == true ? Colors.green : Colors.amber,
              ),
            ),
          ),
        ],
      );
    } else {
      return const Text(
        "No feeds logged",
        style: TextStyle(color: Colors.grey),
      );
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
  final String subtitle;
  final String title;
  final Color color;

  const _EventTile({
    required this.subtitle,
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
      subtitle: Text(subtitle),
    );
  }
}
