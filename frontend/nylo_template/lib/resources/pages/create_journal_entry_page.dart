import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

import '../widgets/journal_entry_form_widget.dart';
import '../widgets/buttons/partials/primary_button_widget.dart';
import '../../app/networking/journal_api_service.dart';
import '../../app/models/journal_entry.dart';
import '../../app/models/feed_type.dart';
import '../../app/utils/sleep_duration_utils.dart';
import '/config/keys.dart';

class CreateJournalEntryPage extends NyStatefulWidget {
  static RouteView path =
      ("/create-journal-entry", (_) => CreateJournalEntryPage());

  CreateJournalEntryPage({super.key})
      : super(child: () => _CreateJournalEntryPageState());
}

class _CreateJournalEntryPageState extends NyPage<CreateJournalEntryPage> {
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
      };

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Journal Entry"), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: form),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: PrimaryButton(
                text: "Submit",
                onPressed: () {
                  createJournalEntry();
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void createJournalEntry() async {
    final newEntry = JournalEntry(
      startWakeTime: parseDateTimeString(wakeTimeController.text),
      startFeedTime: parseDateTimeString(feedTimeController.text),
      startSleepTime: parseDateTimeString(sleepTimeController.text),
      startPlayTime: parseDateTimeString(playTimeController.text),
      sleepDuration: parseSleepDuration(sleepDurationController.text),
      feedTypes: List.generate(feedTypeControllers.length, (index) {
        return FeedType(
          type: feedTypeControllers[index].text,
          value: int.tryParse(feedValueControllers[index].text),
          unit: feedUnitControllers[index].text,
        );
      }),
      remarks: remarksController.text,
      hasStool: false,
      hasUrine: false,
    );

    final babyId = await Keys.selectedBabyId.read();
    if (babyId == null) {
      debugPrint("❌ No baby selected");
      return null; // or return null / throw depending on context
    }

    try {
      await _journalApiService.create(id: babyId, data: newEntry);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Journal entry created successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to create journal entry."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
