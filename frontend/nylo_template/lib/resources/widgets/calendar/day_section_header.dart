import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DaySectionHeader extends StatelessWidget {
  final DateTime date;
  final int weekNo;

  const DaySectionHeader({Key? key, required this.date, required this.weekNo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = _isSameDay(date, today);
    final isTomorrow = _isSameDay(date, today.add(const Duration(days: 1)));

    String label;
    if (isToday) {
      label = "Today";
    } else if (isTomorrow) {
      label = "Tomorrow";
    } else {
      label = DateFormat.EEEE().format(date);
    }

    final weekLabel = weekNo > 0 ? " [Week $weekNo]" : "";

    return Row(
      children: [
        Text("$weekLabel  $label - ${DateFormat('d MMMM yyyy').format(date)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
