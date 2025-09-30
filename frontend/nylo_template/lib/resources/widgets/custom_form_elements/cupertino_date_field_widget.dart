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
            initialDateTime: DateTime.now(),
            use24hFormat: true,
            onDateTimeChanged: (DateTime newDateTime) {
              widget.textController.text =
                  newDateTime.toString();
              // "${newDateTime.day}/${newDateTime.month}/${newDateTime.year}, ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}";
              setState(() {});
            },
          ),
        ),
      ),
    );
  }
}
