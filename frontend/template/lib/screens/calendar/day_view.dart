// screens/calendar/day_view.dart
import 'package:flutter/material.dart';

class DayView extends StatelessWidget {
  final DateTime selectedDate;

  const DayView({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    // Mock schedule data
    final items = [
      {'time': '08:00', 'title': 'Cycle 1'},
      {'time': '12:00', 'title': 'Cycle 2'},
      {'time': '16:00', 'title': 'Cycle 3'},
      {'time': '20:00', 'title': 'Cycle 4'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2F80ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['time']!, style: const TextStyle(color: Colors.white)),
              Text(item['title']!,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}
