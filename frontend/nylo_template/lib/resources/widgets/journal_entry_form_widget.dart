import 'package:flutter/material.dart';
import 'package:flutter_app/resources/widgets/custom_form_elements/labeled_field_widget.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'custom_form_elements/labeled_text_field_widget.dart';
import 'custom_form_elements/cupertino_date_field_widget.dart';
import 'journal_entry_elements/feed_group_row_widget.dart';
import 'buttons/partials/text_only_button_widget.dart';

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

  int noFeedFields = 1;

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
          LabeledField(label: "Feed Type", child: Container()),
          for (int i = 0; i < noFeedFields; i++) ...[
            FeedGroupRow(),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          TextOnlyButton(
            text: "Add Feed",
            textColor: const Color(0xFFD61C1C),
            onPressed: () {
              setState(() {
                noFeedFields++;
              });
            },
          ),
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
