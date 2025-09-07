// screens/calendar/month_view.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
    _selectedDay = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
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
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              // Show dots under certain dates
              if (date.day % 3 == 0) {
                return const Positioned(
                  bottom: 4,
                  child: Icon(Icons.circle, size: 6, color: Colors.purple),
                );
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        _eventListForDay(_selectedDay),
      ],
    );
  }

  Widget _eventListForDay(DateTime day) {
    // Mock example
    if (day.day % 2 == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🍼 10:00 - 13:00", style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text("Cycle 1", style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No events", style: TextStyle(color: Colors.grey)),
      );
    }
  }
}
