// screens/calendar/week_view.dart
import 'package:flutter/material.dart';

class WeekView extends StatelessWidget {
  final DateTime selectedDate;

  const WeekView({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final weekDays = List.generate(7, (i) {
      return selectedDate.subtract(Duration(days: selectedDate.weekday - 1 - i));
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weekDays.map((date) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  "${date.day}/${date.month}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._mockBlocksForDate(date),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _mockBlocksForDate(DateTime date) {
    if (date.day % 2 == 0) {
      return [
        _block("Cycle 1", 8),
        _block("Cycle 2", 14),
      ];
    } else {
      return [
        _block("Cycle 1", 10),
        _block("Cycle 2", 18),
      ];
    }
  }

  Widget _block(String title, int hour) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF2F80ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }
}
