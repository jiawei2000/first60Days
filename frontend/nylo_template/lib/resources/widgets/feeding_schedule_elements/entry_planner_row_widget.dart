import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/feeding_schedule_controller.dart';
import 'package:flutter_app/app/models/entry_planner.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/bootstrap/extensions.dart';
import 'package:flutter/cupertino.dart';
import '/config/keys.dart';

class EntryPlannerRow extends StatefulWidget {
  const EntryPlannerRow({super.key, required this.entryPlanner});

  final EntryPlanner entryPlanner;

  @override
  createState() => _EntryPlannerRowState();
}

class _EntryPlannerRowState extends NyState<EntryPlannerRow> {
  @override
  get init => () {};

  TextEditingController _newTimeTextController = TextEditingController();
  FeedingScheduleController controller = FeedingScheduleController();
  late List<String> _feedTimings;

  @override
  Widget view(BuildContext context) {
    _feedTimings = widget.entryPlanner.feedTimings ?? const <String>[];

    if (_feedTimings.isEmpty) {
      return Container(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("No Feeding Times Added").bodyLarge(),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text('MON Interval: ${calculateMONInterval()}').displaySmall(
            color: context.color.content.withAlpha((255.0 * 0.6).round()),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _feedTimings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final time = _feedTimings[index];

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        context.color.content.withAlpha((255.0 * 0.3).round()),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Feeding ${index + 1}").bodySmall(
                            color: context.color.content
                                .withAlpha((255.0 * 0.8).round()),
                          ),
                          const SizedBox(height: 4),
                          Text(time).displaySmall(
                            color: context.color.content
                                .withAlpha((255.0 * 0.9).round()),
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        _showCupertinoTimePicker(index, time);
                      },
                      splashRadius: 20,
                      tooltip: "edit",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _feedTimings.removeAt(index);
                        });
                        _updateFeedTiming();
                      },
                      splashRadius: 20,
                      tooltip: "delete",
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCupertinoTimePicker(int feedTimeIndex, String initialTime) {
    final initialDateTime = _parseTimeString(initialTime);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 260,
          padding: const EdgeInsets.only(top: 12),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      setState(() {
                        _feedTimings[feedTimeIndex] =
                            _newTimeTextController.text;
                      });
                      await _updateFeedTiming();
                    },
                    child: const Text('Done'),
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false,
                    initialDateTime: initialDateTime,
                    onDateTimeChanged: (dateTime) {
                      setState(() {
                        _newTimeTextController.text =
                            _formatTimeString(dateTime);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateFeedTiming() async {
    // Sort _feedTimings by time
    _feedTimings.sort((a, b) {
      final timeA = _parseTimeString(a);
      final timeB = _parseTimeString(b);
      if (timeA == null || timeB == null) return 0;
      return timeA.compareTo(timeB);
    });
    final babyId = await Keys.selectedBabyId.read();
    if (babyId == null) {
      debugPrint("❌ No baby selected");
      return null; // or return null / throw depending on context
    }
    await controller.updateFeedTimingByPlannerId(
      babyId: babyId,
      plannerId: widget.entryPlanner.id!,
      data: {
        'feedTimings': _feedTimings,
      },
    );
  }

  String calculateMONInterval() {
    final firstTiming = _feedTimings.isNotEmpty ? _feedTimings.first : null;
    final lastTiming = _feedTimings.isNotEmpty ? _feedTimings.last : null;

    if (firstTiming == null || lastTiming == null) {
      return '0';
    }

    final parsedFirst = _parseTimeString(firstTiming);
    final parsedLast = _parseTimeString(lastTiming);

    final firstTime =
        TimeOfDay(hour: parsedFirst!.hour, minute: parsedFirst.minute);
    final lastTime =
        TimeOfDay(hour: parsedLast!.hour, minute: parsedLast.minute);

    final firstTotalMinutes = firstTime.hour * 60 + firstTime.minute;
    final lastTotalMinutes = lastTime.hour * 60 + lastTime.minute;

    final differenceMinutes = firstTotalMinutes - lastTotalMinutes + 24 * 60;

    // return difference in hours and minutes
    final hours = (differenceMinutes ~/ 60).abs();
    final minutes = (differenceMinutes % 60).abs();
    if (minutes == 0) {
      return '$hours h';
    }
    return '$hours h $minutes m';
  }

  String _formatTimeString(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am' : 'pm';
    if (hour == '00') {
      return "12:$minute $period";
    } else if (int.parse(hour) > 12) {
      final adjustedHour = (int.parse(hour) - 12).toString().padLeft(2, '0');
      return "$adjustedHour:$minute $period";
    }
    return "$hour:$minute $period";
  }

  DateTime? _parseTimeString(String value) {
    if (value.isEmpty) return null;
    final lower = value.trim().toLowerCase();
    final isPM = lower.contains('pm');
    final isAM = lower.contains('am');

    final clean = lower.replaceAll(RegExp(r'[^0-9:]'), '');
    final segments = clean.split(':');
    if (segments.length < 2) return null;

    var hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    if (hour == null || minute == null) return null;

    if (isPM && hour < 12) {
      hour += 12;
    }
    if (isAM && hour == 12) {
      hour = 0;
    }

    return DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      hour.clamp(0, 23),
      minute.clamp(0, 59),
    );
  }
}
