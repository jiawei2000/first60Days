import 'package:flutter/material.dart';
import '/app/controllers/feeding_schedule_controller.dart';
import 'package:nylo_framework/nylo_framework.dart';

class FeedingSchedulePage extends NyStatefulWidget<FeedingScheduleController> {
  static RouteView path = ("/feeding-schedule", (_) => FeedingSchedulePage());

  FeedingSchedulePage({super.key}) : super(child: () => _FeedingSchedulePageState());
}

class _FeedingSchedulePageState extends NyPage<FeedingSchedulePage> {
  FeedingScheduleController get controller => widget.controller;

  bool _showBanner = true;
  int _weekNo = 3;

  // UI-only mock data (you can replace with real data later)
  final List<String> _feedTimings = [
    "06:00 AM",
    "09:00 AM",
    "12:00 PM",
    "03:00 PM",
    "06:00 PM",
    "09:00 PM",
  ];

  @override
  get init => () { /* UI only */ };

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => pop(),
        ),
        title: Text(
          "Baby Chloe",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewTime,
        icon: const Icon(Icons.add),
        label: const Text("Add time"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // “Overall Planned Schedule” link
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    // routeTo(OverallPlannedSchedulePage.path);
                  },
                  child: Text(
                    "Overall Planned Schedule",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),

            if (_showBanner)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                      child: Icon(Icons.info_outline,
                          color: theme.colorScheme.primary, size: 18),
                    ),
                    title: const Text(
                      "This is your planned feeding schedule for this week",
                    ),
                    trailing: IconButton(
                      splashRadius: 20,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _showBanner = false),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Week header card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Week $_weekNo",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: "Change week",
                      icon: const Icon(Icons.edit_calendar_outlined),
                      onPressed: _pickWeek,
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Times list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                itemCount: _feedTimings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _FeedingTimeTile(
                  label: "Feeding Time",
                  timeText: _feedTimings[i],
                  onMenuTap: () => _showTileMenu(i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickWeek() async {
    // light UI stub – change week quickly
    final selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(10, (idx) => idx + 1).map((w) {
              return ListTile(
                title: Text("Week $w"),
                onTap: () => Navigator.pop(ctx, w),
              );
            }).toList(),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() => _weekNo = selected);
    }
  }

  Future<void> _addNewTime() async {
    final picked = await _pickTime();
    if (picked == null) return;
    setState(() => _feedTimings.add(_formatTimeOfDay(picked)));
  }

  Future<void> _showTileMenu(int index) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text("Edit time"),
                onTap: () => Navigator.pop(ctx, "edit"),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text("Remove"),
                onTap: () => Navigator.pop(ctx, "remove"),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (result == "remove") {
      setState(() => _feedTimings.removeAt(index));
    } else if (result == "edit") {
      final picked = await _pickTime();
      if (picked != null) {
        setState(() => _feedTimings[index] = _formatTimeOfDay(picked));
      }
    }
  }

  Future<TimeOfDay?> _pickTime() async {
    final now = TimeOfDay.now();
    return await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: 0),
      helpText: "Select feeding time",
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $suffix";
  }
}

class _FeedingTimeTile extends StatelessWidget {
  const _FeedingTimeTile({
    required this.label,
    required this.timeText,
    this.onMenuTap,
  });

  final String label;
  final String timeText;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      letterSpacing: .2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: onMenuTap,
              splashRadius: 20,
              tooltip: "Options",
            ),
          ],
        ),
      ),
    );
  }
}
