import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekView extends StatefulWidget {
  final DateTime selectedDate;

  const WeekView({super.key, required this.selectedDate});

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  bool _showWarning = true;

  @override
  Widget build(BuildContext context) {
    final startOfWeek =
        widget.selectedDate.subtract(Duration(days: widget.selectedDate.weekday - 1));
    final days = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Column(
      children: [
        if (_showWarning)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _warningBanner(() => setState(() => _showWarning = false)),
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Column (08:00 - 24:00)
              Column(
                children: List.generate(17, (i) {
                  final hour = 8 + i;
                  return SizedBox(
                    height: 60,
                    child: Text(
                      "${hour.toString().padLeft(2, '0')}:00",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }),
              ),

              // Scrollable Week View
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: 1020, // 17 slots * 60px
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: days.map((date) {
                        return _DayColumn(
                          date: date,
                          isSelected: _isSameDay(date, widget.selectedDate),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
              "Some cycles this week may conflict with feeding time. Please review the schedule.",
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

class _DayColumn extends StatelessWidget {
  final DateTime date;
  final bool isSelected;

  const _DayColumn({
    required this.date,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final String weekday = DateFormat.E().format(date);
    final String day = DateFormat.d().format(date);

    final mockEvents = _getMockEvents(date);

    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(weekday, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),

          // Event Stack
          Expanded(
            child: Stack(
              children: [
                Container(width: double.infinity), // fill space
                ...mockEvents.map((event) {
                  final topOffset = (event['startHour'] - 8) * 60.0;
                  final height = (event['endHour'] - event['startHour']) * 60.0;

                  return Positioned(
                    top: topOffset,
                    left: 8,
                    right: 8,
                    height: height,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F80ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Center(
                        child: Text(
                          event['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockEvents(DateTime date) {
    if (date.day % 2 == 0) {
      return [
        {'title': 'Cycle 1', 'startHour': 9, 'endHour': 11},
        {'title': 'Cycle 2', 'startHour': 14, 'endHour': 16},
      ];
    } else if (date.day % 3 == 0) {
      return [
        {'title': 'Cycle 1', 'startHour': 10, 'endHour': 13},
      ];
    } else {
      return [
        {'title': 'Cycle 1', 'startHour': 8, 'endHour': 10},
        {'title': 'Cycle 2', 'startHour': 16, 'endHour': 18},
      ];
    }
  }
}
