import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

import '../widgets/journal_entry_form_widget.dart';
import '../widgets/buttons/partials/primary_button_widget.dart';
import '../../app/networking/journal_api_service.dart';
import '../../app/models/journal_entry.dart';
import '../../app/models/feed_type.dart';

class EditJournalEntryPage extends NyStatefulWidget {
  static RouteView path =
      ("/edit-journal-entry", (_) => EditJournalEntryPage());

  EditJournalEntryPage({super.key})
      : super(child: () => _EditJournalEntryPageState());
}

class _EditJournalEntryPageState extends NyPage<EditJournalEntryPage> {
  final TextEditingController wakeTimeController = TextEditingController();
  final TextEditingController feedTimeController = TextEditingController();
  final TextEditingController sleepTimeController = TextEditingController();
  final TextEditingController playTimeController = TextEditingController();
  final List<TextEditingController> feedTypeControllers = [];
  final List<TextEditingController> feedValueControllers = [];
  final List<TextEditingController> feedUnitControllers = [];
  final TextEditingController remarksController = TextEditingController();

  late JournalEntryForm form;

  @override
  get init => () {
        //Initialize form
        form = JournalEntryForm(
          wakeTimeController: wakeTimeController,
          feedTimeController: feedTimeController,
          sleepTimeController: sleepTimeController,
          playTimeController: playTimeController,
          feedTypeControllers: feedTypeControllers,
          feedValueControllers: feedValueControllers,
          feedUnitControllers: feedUnitControllers,
          remarksController: remarksController,
        );
      };

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Journal Entry")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: form),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: PrimaryButton(
                  text: "Save",
                  onPressed: () {
                    editJournalEntry();
                  }),
            )
          ],
        ),
      ),
    );
  }

  void editJournalEntry() async {
    debugPrint("Edit Journal Entry - to be implemented");
  }
}
