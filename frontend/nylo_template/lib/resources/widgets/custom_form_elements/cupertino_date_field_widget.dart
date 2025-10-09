import 'package:flutter/cupertino.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'labeled_field_widget.dart';
import 'readonly_text_field_widget.dart';

class CupertinoDateField extends StatefulWidget {
  final String label;
  final TextEditingController textController;

  const CupertinoDateField(
      {super.key, required this.label, required this.textController});

  @override
  createState() => _CupertinoDateFieldState();
}

class _CupertinoDateFieldState extends NyState<CupertinoDateField> {
  @override
  get init => () {};

  @override
  Widget view(BuildContext context) {
    return Container(
        child: LabeledField(
            label: widget.label,
            child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: ReadonlyTextField(textController: widget.textController),
                onPressed: () {
                  setState(() {
                    if (widget.textController.text == "") {
                      widget.textController.text =
                          _formatDateTime(DateTime.now());
                    }
                  });
                  _showCupertinoDialog();
                })));
  }

  void _showCupertinoDialog() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        // The Bottom margin is provided to align the popup above the system
        // navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime:
                parseDateTimeString(widget.textController.text),
            use24hFormat: true,
            onDateTimeChanged: (DateTime newDateTime) {
              widget.textController.text = _formatDateTime(newDateTime);
              setState(() {});
            },
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  DateTime? parseDateTimeString(String dateTimeString) {
    // 10/12/2023, 14:30 --> DateTime
    final parts = dateTimeString.split(", ");
    if (parts.length != 2) return null;

    final dateParts = parts[0].split("/");
    final timeParts = parts[1].split(":");
    if (dateParts.length != 3 || timeParts.length != 2) return null;

    final day = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final year = int.tryParse(dateParts[2]);
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (day == null ||
        month == null ||
        year == null ||
        hour == null ||
        minute == null) return null;

    return DateTime(year, month, day, hour, minute);
  }
}
