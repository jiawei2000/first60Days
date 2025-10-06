import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DaySectionHeader extends StatelessWidget {
  final DateTime date;

  const DaySectionHeader({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = _isSameDay(date, today);
    final isTomorrow = _isSameDay(date, today.add(const Duration(days: 1)));

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
          "$label - ${DateFormat.yMMMMd().format(date)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
