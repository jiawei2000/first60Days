// screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'month_view.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Baby Chloe"),
        centerTitle: true,
      ),
      body: MonthView(
        selectedDate: _selectedDate,
        onDateSelected: _onDateChanged,
      ),
    );
  }
}
