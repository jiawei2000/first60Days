import 'package:flutter/material.dart';
import 'package:flutter_app/resources/widgets/custom_form_elements/labeled_field_widget.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'custom_form_elements/labeled_text_field_widget.dart';
import 'custom_form_elements/cupertino_date_field_widget.dart';
import 'journal_entry_elements/feed_group_row_widget.dart';
import 'buttons/partials/text_only_button_widget.dart';

class JournalEntryForm extends StatefulWidget {
  final TextEditingController wakeTimeController;
  final TextEditingController feedTimeController;
  final TextEditingController sleepTimeController;
  final TextEditingController playTimeController;
  final List<TextEditingController> feedTypeControllers;
  final List<TextEditingController> feedValueControllers;
  final List<TextEditingController> feedUnitControllers;
  final TextEditingController remarksController;

  const JournalEntryForm({
    super.key,
    required this.wakeTimeController,
    required this.feedTimeController,
    required this.sleepTimeController,
    required this.playTimeController,
    required this.feedTypeControllers,
    required this.feedValueControllers,
    required this.feedUnitControllers,
    required this.remarksController,
  });

  @override
  createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends NyState<JournalEntryForm> {
  @override
  get init => () {
        // At least 1 feed field
        if (widget.feedTypeControllers.isEmpty) {
          addFeedRow();
        }
      };

  @override
  Widget view(BuildContext context) {
    return Container(
      child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          children: [
            CupertinoDateField(
                label: 'Awake Time', textController: widget.wakeTimeController),
            const SizedBox(height: 12),
            CupertinoDateField(
                label: 'Feed Time', textController: widget.feedTimeController),
            LabeledField(label: "Feed Type", child: Container()),
            for (int i = 0; i < widget.feedTypeControllers.length; i++) ...[
              FeedGroupRow(
                typeController: widget.feedTypeControllers[i],
                valueController: widget.feedValueControllers[i],
                unitController: widget.feedUnitControllers[i],
              ),
              const SizedBox(height: 4),
            ],
            TextOnlyButton(
              text: "Add Feed",
              textColor: const Color(0xFFD61C1C),
              onPressed: () {
                addFeedRow();
              },
            ),
            CupertinoDateField(
                label: 'Sleep Time',
                textController: widget.sleepTimeController),
            const SizedBox(height: 12),
            CupertinoDateField(
                label: 'Play Time', textController: widget.playTimeController),
            LabeledTextField(
                label: 'Remarks',
                textController: widget.remarksController,
                hintText: "Enter remarks"),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(value: false, onChanged: (value) {}),
                const Text('Poo', style: TextStyle(fontSize: 20)),
                Checkbox(value: false, onChanged: (value) {}),
                const Text('Pee', style: TextStyle(fontSize: 20)),
              ],
            ),
          ]),
    );
  }

  addFeedRow() {
    setState(() {
      widget.feedTypeControllers.add(TextEditingController());
      widget.feedValueControllers.add(TextEditingController());
      widget.feedUnitControllers.add(TextEditingController());
    });
  }
}
