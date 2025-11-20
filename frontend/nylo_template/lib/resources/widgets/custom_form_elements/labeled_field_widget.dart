import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

class LabeledField extends StatefulWidget {
  final String label;
  final Widget child;
  final IconData? icon;

  const LabeledField(
      {super.key, required this.label, required this.child, this.icon});

  @override
  createState() => _LabeledFieldState();
}

class _LabeledFieldState extends NyState<LabeledField> {
  @override
  get init => () {};

  @override
  Widget view(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: const Color(0xFF1565C0), size: 20),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
