import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/entry_planner.dart';
import 'package:flutter_app/resources/widgets/feeding_schedule_elements/generate_schedule_form_widget.dart';
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

  int _weekNo = 1;
  List<EntryPlanner> _entryPlanners = [];

  @override
  get init => () {
        _getEntryPlanners();
      };

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
                onPressed: () => _showGenerateScheduleDialog(),
              ),
            ),

            Expanded(
              child: EntryPlannerRow(
                  entryPlanner: _getFeedTimingsForWeek(_weekNo)),
            ),
          ],
        ),
      ),
    );
  }

  void nextWeek() {
    setState(() {
      if (_weekNo < 10) _weekNo += 1;
    });
  }

  void previousWeek() {
    setState(() {
      if (_weekNo > 1) _weekNo -= 1;
    });
  }

  Future<void> _getEntryPlanners() async {
    final response =
        // await controller.fetchPlannerByBabyId("YubfhQ3OBeECH6AuYPVK");
        await controller.fetchPlannerByBabyId("zuCu842rURSUnCHKC56R");

    final plannersData = response?['planner'] as List?;
    final planners = plannersData
            ?.whereType<Map<String, dynamic>>()
            .map(EntryPlanner.fromJson)
            .toList() ??
        [];
    _reloadEntryPlanners(planners);
  }

  void _reloadEntryPlanners(List<EntryPlanner> planners) {
    // Reset before repopulating
    _entryPlanners = planners;

    // Ensure there is a planner for each week 1 to 10
    final existingWeeks = _entryPlanners
        .where((planner) => planner.weekNo != null)
        .map((planner) => planner.weekNo!)
        .toSet();

    for (int week = 1; week <= 10; week++) {
      if (!existingWeeks.contains(week)) {
        _entryPlanners.add(EntryPlanner(weekNo: week, feedTimings: []));
      }
    }

    // Sort planners by week number to maintain order
    _entryPlanners.sort((a, b) => (a.weekNo ?? 0).compareTo(b.weekNo ?? 0));

    setState(() {});
  }

  EntryPlanner _getFeedTimingsForWeek(int week) {
    return _entryPlanners.firstWhere(
      (planner) => planner.weekNo == week,
      orElse: () => EntryPlanner(feedTimings: []),
    );
  }

  void _showGenerateScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: GenerateScheduleForm(weekNo: _weekNo),
        );
      },
    ).then((_) async {
      await _getEntryPlanners();
    });
  }
}
