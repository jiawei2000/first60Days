// screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'month_view.dart';
import 'package:best_flutter_ui_templates/routes.dart';
import 'package:best_flutter_ui_templates/screens/providers/widget.dart';
import 'package:best_flutter_ui_templates/model/baby.dart';
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
        actions: [
          TextButton(onPressed: () => goToHomePage(), child: Text('Home')),
        ],
      ),
      body: MonthView(
        selectedDate: _selectedDate,
        onDateSelected: _onDateChanged,
      ),
    );
  }

  void goToHomePage() {
    Baby baby = Baby(id: "temp", name: "Baby Chloe");
    Navigator.pushReplacementNamed(
      context,
      Routes.landing,
      arguments: {'baby': baby, 'token': get_token(context)},
    );
  }
}
