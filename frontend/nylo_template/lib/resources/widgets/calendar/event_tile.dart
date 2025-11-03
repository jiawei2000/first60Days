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
    final bool isPlanned = status.toLowerCase() == "planned";

    final Color? badgeColor;
    final Color? badgeTextColor;

    if (isComplete) {
      badgeColor = Colors.green[100];
      badgeTextColor = Colors.green[800];
    } else if (isPlanned) {
      badgeColor = Colors.grey[200];
      badgeTextColor = Colors.grey[800];
    } else {
      badgeColor = Colors.red[100];
      badgeTextColor = Colors.red[800];
    }

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, size: 12, color: color),
      title: Text(
        title,
        style: const TextStyle(
          // fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: badgeTextColor,
          ),
        ),
      ),
    );
  }
}
