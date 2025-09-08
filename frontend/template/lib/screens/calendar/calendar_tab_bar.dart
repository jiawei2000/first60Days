// screens/calendar_tab_bar.dart
import 'package:flutter/material.dart';
import 'calendar_screen.dart';

class CalendarTabBar extends StatelessWidget {
  final CalendarView selectedView;
  final ValueChanged<CalendarView> onViewChanged;

  const CalendarTabBar({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      borderRadius: BorderRadius.circular(8),
      isSelected: CalendarView.values.map((v) => v == selectedView).toList(),
      onPressed: (index) => onViewChanged(CalendarView.values[index]),
      selectedColor: Colors.white,
      fillColor: const Color(0xFF2F80ED),
      color: Colors.black,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Month"),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Week"),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Day"),
        ),
      ],
    );
  }
}
