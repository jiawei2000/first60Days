import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
// Import label text field widget
import 'custom_form_elements/labeled_text_field_widget.dart';
import 'custom_form_elements/cupertino_date_field_widget.dart';

class JournalEntryForm extends StatefulWidget {
  const JournalEntryForm({super.key});

  @override
  createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends NyState<JournalEntryForm> {
  final TextEditingController wakeTimeController = TextEditingController();
  final TextEditingController feedTimeController = TextEditingController();
  final TextEditingController sleepTimeController = TextEditingController();
  final TextEditingController playTimeController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  @override
  get init => () {};

  @override
  Widget view(BuildContext context) {
    return Container(
        child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            children: [
          ElevatedButton(
            onPressed: () {
              debugPrint(remarksController.text);
              remarksController.text = "Button Pressed";
            },
            child: const Text("Testing"),
          ),
          CupertinoDateField(
              label: 'Awake Time', textController: wakeTimeController),
          const SizedBox(height: 12),
          CupertinoDateField(
              label: 'Feed Time', textController: feedTimeController),
          const SizedBox(height: 12),
          CupertinoDateField(
              label: 'Sleep Time', textController: sleepTimeController),
          const SizedBox(height: 12),
          CupertinoDateField(
              label: 'Play Time', textController: playTimeController),
          LabeledTextField(
              label: 'Remarks',
              textController: remarksController,
              hintText: "Enter remarks"),
        ]));
  }
}
