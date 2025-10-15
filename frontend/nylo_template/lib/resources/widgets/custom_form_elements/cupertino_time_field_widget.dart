import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

import 'labeled_field_widget.dart';
import 'readonly_text_field_widget.dart';

class CupertinoTimeField extends StatefulWidget {
  const CupertinoTimeField({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  createState() => _CupertinoTimeFieldState();
}

class _CupertinoTimeFieldState extends NyState<CupertinoTimeField> {
  late TimeOfDay _selectedTime;
  late final TextEditingController _controller;

  @override
  get init => () {
        _controller = widget.controller;
        _selectedTime = _initialTimeFromField();
        _controller.text = _formatTimeString(_selectedTime);
      };

  @override
  Widget view(BuildContext context) {
    return LabeledField(
      label: widget.label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showCupertinoTimePicker,
        child: ReadonlyTextField(textController: _controller),
      ),
    );
  }

  TimeOfDay _initialTimeFromField() {
    return _parseTimeString(widget.controller.text) ??
        const TimeOfDay(hour: 8, minute: 0);
  }

  void _showCupertinoTimePicker() {
    DateTime now = DateTime.now();
    final initialDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 260,
          padding: const EdgeInsets.only(top: 12),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false,
                    initialDateTime: initialDateTime,
                    onDateTimeChanged: (dateTime) {
                      final newTime = TimeOfDay(
                        hour: dateTime.hour,
                        minute: dateTime.minute,
                      );
                      setState(() {
                        _selectedTime = newTime;
                        _controller.text = _formatTimeString(newTime);
                      });
                      widget.onChanged?.call(_controller.text);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimeString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am' : 'pm';
    if (hour == '00') {
      return "12:$minute $period";
    } else if (int.parse(hour) > 12) {
      final adjustedHour = (int.parse(hour) - 12).toString().padLeft(2, '0');
      return "$adjustedHour:$minute $period";
    }
    return "$hour:$minute $period";
  }

  TimeOfDay? _parseTimeString(String value) {
    if (value.isEmpty) return null;
    final lower = value.trim().toLowerCase();
    final isPM = lower.contains('pm');
    final isAM = lower.contains('am');

    final clean = lower.replaceAll(RegExp(r'[^0-9:]'), '');
    final segments = clean.split(':');
    if (segments.length < 2) return null;

    var hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    if (hour == null || minute == null) return null;

    if (isPM && hour < 12) {
      hour += 12;
    }
    if (isAM && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }
}
