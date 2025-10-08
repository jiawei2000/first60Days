import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/feeding_schedule_controller.dart';
import 'package:flutter_app/resources/widgets/buttons/partials/primary_button_widget.dart';
import 'package:flutter_app/resources/widgets/custom_form_elements/cupertino_time_field_widget.dart';
import 'package:flutter_app/resources/widgets/custom_form_elements/labeled_text_field_widget.dart';
import 'package:nylo_framework/nylo_framework.dart';

class GenerateScheduleForm extends StatefulWidget {
  const GenerateScheduleForm({
    super.key,
    required this.weekNo,
  });

  final int weekNo;

  @override
  createState() => _GenerateScheduleFormState();
}

class _GenerateScheduleFormState extends NyState<GenerateScheduleForm> {
  final TextEditingController _totalFeedsController =
      TextEditingController(text: '9');
  final TextEditingController _firstFeedTimeController =
      TextEditingController(text: '3:00 AM');
  final TextEditingController _lastFeedTimeController =
      TextEditingController(text: '11:00 PM');

  FeedingScheduleController controller = FeedingScheduleController();

  @override
  get init => () {};

  @override
  void dispose() {
    _totalFeedsController.dispose();
    _firstFeedTimeController.dispose();
    _lastFeedTimeController.dispose();
    super.dispose();
  }

  @override
  Widget view(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            CupertinoTimeField(
              label: 'First Feed Time',
              controller: _firstFeedTimeController,
              onChanged: (value) {
                setState(() => {});
              },
            ),
            CupertinoTimeField(
              label: 'Last Feed Time',
              controller: _lastFeedTimeController,
              onChanged: (value) {
                setState(() => {});
              },
            ),
            const SizedBox(height: 12),
            LabeledTextField(
              label: 'Desired Number of Feeds',
              textController: _totalFeedsController,
              hintText: "Recommended: 8-10",
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Generate Schedule",
              onPressed: () async {
                await _generateNewSchedule(widget.weekNo);
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      ),
    );
  }

  Future<void> _generateNewSchedule(int weekNo) async {
    final controller = FeedingScheduleController();

    String babyId = "zuCu842rURSUnCHKC56R";

    DateTime now = DateTime.now();
    DateTime firstFeedTime =
        _parseStringtoDateTime(_firstFeedTimeController.text) ??
            DateTime(now.year, now.month, now.day, 8, 0);
    DateTime lastFeedTime =
        _parseStringtoDateTime(_lastFeedTimeController.text) ??
            DateTime(now.year, now.month, now.day, 22, 0);
    // Parse to int
    final totalFeeds = int.tryParse(_totalFeedsController.text) ?? 8;

    final response = await controller.createPlanner(
        babyId: babyId,
        weekNo: weekNo,
        firstFeedTime: firstFeedTime,
        lastFeedTime: lastFeedTime,
        totalFeeds: totalFeeds);

    // Do Error Handling another time
    final message = response?['message'];
    // final newPlannerData = response?['planner'];
  }

  DateTime? _parseStringtoDateTime(String value) {
    if (value.isEmpty) return null;
    final lower = value.trim().toLowerCase();
    final isPM = lower.contains('pm');
    final isAM = lower.contains('am');

    final clean = lower.replaceAll(RegExp(r'[^0-9:]'), '');
    final segments = clean.split(':');
    if (segments.length < 2) return null;

    int? hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    if (hour == null || minute == null) return null;

    if (isPM && hour < 12) {
      hour += 12;
    }
    if (isAM && hour == 12) {
      hour = 0;
    }

    final now = DateTime.now();
    return DateTime(
        now.year, now.month, now.day, hour.clamp(0, 23), minute.clamp(0, 59));
  }
}
