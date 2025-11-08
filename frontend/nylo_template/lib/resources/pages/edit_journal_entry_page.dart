import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

import '../widgets/journal_entry_form_widget.dart';
import '../widgets/buttons/partials/primary_button_widget.dart';
import '../../app/networking/journal_api_service.dart';
import '../../app/models/journal_entry.dart';
import '../../app/utils/sleep_duration_utils.dart';

class EditJournalEntryPage extends NyStatefulWidget {
  static RouteView path =
      ("/edit-journal-entry", (_) => EditJournalEntryPage());

  EditJournalEntryPage({super.key})
      : super(child: () => _EditJournalEntryPageState());
}

class _EditJournalEntryPageState extends NyPage<EditJournalEntryPage> {
  final TextEditingController wakeTimeController = TextEditingController();
  final TextEditingController sleepDurationController = TextEditingController();
  final TextEditingController feedTimeController = TextEditingController();
  final TextEditingController sleepTimeController = TextEditingController();
  final TextEditingController playTimeController = TextEditingController();
  final List<TextEditingController> feedTypeControllers = [];
  final List<TextEditingController> feedValueControllers = [];
  final List<TextEditingController> feedUnitControllers = [];
  final TextEditingController remarksController = TextEditingController();

  late JournalEntryForm form;
  JournalApiService _journalApiService = JournalApiService();
  //temp entryid 0uylgiwzLaLoybeIiTws
  final entryId = "1bVzLRQG6mmb0oC4h84B";
  final babyId =
      "W6bOM4UJxxfbo0bktsmO"; //keeping this since unused for now, as in this page
  @override
  get init => () {
        //Initialize form
        form = JournalEntryForm(
          wakeTimeController: wakeTimeController,
          sleepDurationController: sleepDurationController,
          feedTimeController: feedTimeController,
          sleepTimeController: sleepTimeController,
          playTimeController: playTimeController,
          feedTypeControllers: feedTypeControllers,
          feedValueControllers: feedValueControllers,
          feedUnitControllers: feedUnitControllers,
          remarksController: remarksController,
        );
        getEntryById();
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

  void getEntryById() async {
    final result = await _journalApiService.findJournalEntryById(
      babyId: babyId,
      entryId: entryId,
    );

    JournalEntry entry = JournalEntry();
    if (result != null) {
      entry = JournalEntry.fromJson(result);
    }

    //Populate fields
    wakeTimeController.text = entry.startWakeTime?.toString() ?? '';
    feedTimeController.text = entry.startFeedTime?.toString() ?? '';
    // Clear old controllers
    feedTypeControllers.clear();
    feedValueControllers.clear();
    feedUnitControllers.clear();

    if (entry.feedTypes != null) {
      for (var feed in entry.feedTypes!) {
        feedTypeControllers.add(TextEditingController(text: feed.type ?? ''));
        feedValueControllers
            .add(TextEditingController(text: feed.value?.toString() ?? ''));
        feedUnitControllers.add(TextEditingController(text: feed.unit ?? ''));
      }
    }
    playTimeController.text = entry.startPlayTime?.toString() ?? '';
    sleepTimeController.text = entry.startSleepTime?.toString() ?? '';
    sleepDurationController.text = formatSleepDuration(entry.sleepDuration);
    remarksController.text = entry.remarks ?? '';
    if (mounted) {
      setState(() {
        form = JournalEntryForm(
          wakeTimeController: wakeTimeController,
          sleepDurationController: sleepDurationController,
          feedTimeController: feedTimeController,
          sleepTimeController: sleepTimeController,
          playTimeController: playTimeController,
          feedTypeControllers: feedTypeControllers,
          feedValueControllers: feedValueControllers,
          feedUnitControllers: feedUnitControllers,
          remarksController: remarksController,
        );
      });
    }
  }

  void editJournalEntry() async {
    debugPrint("Edit Journal Entry - to be implemented");
  }
}
