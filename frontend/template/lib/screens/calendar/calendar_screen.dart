// screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'calendar_tab_bar.dart';
import 'day_view.dart';
import 'week_view.dart';
import 'month_view.dart';

enum CalendarView { month, week, day }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarView _selectedView = CalendarView.day;
  DateTime _selectedDate = DateTime.now();

  void _onViewChanged(CalendarView view) {
    setState(() => _selectedView = view);
  }

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
  }

  Widget _buildView() {
    switch (_selectedView) {
      case CalendarView.month:
        return MonthView(
          selectedDate: _selectedDate,
          onDateSelected: _onDateChanged,
        );
      case CalendarView.week:
        return WeekView(selectedDate: _selectedDate);
      case CalendarView.day:
        return DayView(selectedDate: _selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Baby Chloe")),
      body: Column(
        children: [
          CalendarTabBar(
            selectedView: _selectedView,
            onViewChanged: _onViewChanged,
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              _selectedDate.toIso8601String().split("T").first,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: _buildView()),
        ],
      ),
    );
  }
}
