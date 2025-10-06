import 'package:flutter/material.dart';
import 'package:flutter_app/resources/widgets/safearea_widget.dart';
import '/app/controllers/feeding_schedule_controller.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '../widgets/buttons/partials/primary_button_widget.dart';
import '../widgets/feeding_schedule_elements/entry_planner_row_widget.dart';
import '/bootstrap/extensions.dart';

class FeedingSchedulePage extends NyStatefulWidget<FeedingScheduleController> {
  static RouteView path = ("/feeding-schedule", (_) => FeedingSchedulePage());

  FeedingSchedulePage({super.key})
      : super(child: () => _FeedingSchedulePageState());
}

class _FeedingSchedulePageState extends NyPage<FeedingSchedulePage> {
  FeedingScheduleController get controller => widget.controller;

  int _weekNo = 3;

  // UI-only mock data (you can replace with real data later)
  final List<String> _feedTimings = [
    "06:00 AM",
    "09:00 AM",
    "12:00 PM",
    "03:00 PM",
    "06:00 PM",
    "09:00 PM",
    "12:00 AM",
    "03:00 AM",
  ];

  @override
  get init => () {};

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: Text("Feeding Schedule"), centerTitle: true),
      body: SafeAreaWidget(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Week header card
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.color.content.withAlpha((255.0 * 0.5).round()),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: "Back",
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: previousWeek,
                  ),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _weekNo,
                        items: List.generate(
                          10,
                          (index) => DropdownMenuItem<int>(
                            value: index + 1,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text('Week ${index + 1}').bodyLarge(),
                            ),
                          ),
                        ),
                        onChanged: (week) {
                          if (week == null) return;
                          setState(() => _weekNo = week);
                        },
                        isExpanded: true,
                        dropdownColor: theme.colorScheme.surface,
                        icon: const SizedBox.shrink(),
                        iconSize: 0,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "Forward",
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: nextWeek,
                  )
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: PrimaryButton(
                  text: "Generate New Schedule",
                  onPressed: () {
                    // createJournalEntry();
                  }),
            ),

            Expanded(
              child: EntryPlannerRow(times: _feedTimings),
            ),
          ],
        ),
      ),
    );
  }

  void nextWeek() {
    setState(() {
      _weekNo += 1;
    });
  }

  void previousWeek() {
    setState(() {
      if (_weekNo > 1) _weekNo -= 1;
    });
  }
}
