import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  const EventTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Choose badge color based on status
    final bool isComplete = status.toLowerCase() == "complete";
    final badgeColor = isComplete ? Colors.green[100] : Colors.red[100];
    final badgeTextColor = isComplete ? Colors.green[800] : Colors.red[800];

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, size: 12, color: color),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: badgeTextColor,
          ),
        ),
      ),
    );
  }
}
