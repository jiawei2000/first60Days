import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/home_controller.dart';
import 'package:flutter_app/app/controllers/feeding_schedule_controller.dart';
import 'package:flutter_app/app/models/feed_type.dart';
import 'package:flutter_app/app/models/journal_entry.dart';
import 'package:flutter_app/app/models/entry_planner.dart';
import 'package:flutter_app/app/networking/journal_api_service.dart';
import 'package:flutter_app/resources/widgets/buttons/partials/primary_button_widget.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nylo_framework/nylo_framework.dart';

import '/app/controllers/calendar_controller.dart';
import '/resources/pages/create_journal_entry_page.dart';

import '/resources/widgets/calendar/info_banner.dart';
import '/resources/widgets/calendar/event_tile.dart';
import '/resources/widgets/calendar/day_section_header.dart';
import '/resources/widgets/journal_entry_form_widget.dart';
import '/config/keys.dart';

class CalendarPage extends StatefulWidget {
  static RouteView path = ("/calendar", (context) => const CalendarPage());

  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarController _controller = CalendarController();
  final HomeController _homeController = HomeController();
  final FeedingScheduleController _feedingScheduleController =
      FeedingScheduleController();

  JournalApiService _journalApiService = JournalApiService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  DateTime _babyDOB = DateTime.now();
  List<EntryPlanner> _feedingPlanners = [];
  Map<DateTime, List<Map<String, dynamic>>> _eventData = {};
  bool _showBanner = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadBabyDOB();
    _loadFeedingPlanners();
  }

  void _loadEvents() async {
    setState(() => _loading = true);
    final events = await _controller.getCalendarData();
    setState(() {
      _eventData = events ?? {};
      _loading = false;
    });
  }

  void _loadBabyDOB() async {
    final babyId = await Keys.selectedBabyId.read();
    final baby = await _homeController.fetchBabyById(babyId);
    if (!mounted || baby?.dob == null) return;
    setState(() {
      _babyDOB = baby!.dob!;
    });
  }

  void _loadFeedingPlanners() async {
    final babyId = await Keys.selectedBabyId.read();
    final response =
        await _feedingScheduleController.fetchPlannerByBabyId(babyId);
    final plannersData = response?['planner'] as List?;
    setState(() {
      _feedingPlanners = plannersData
              ?.whereType<Map<String, dynamic>>()
              .map(EntryPlanner.fromJson)
              .toList() ??
          [];
    });
  }

  EntryPlanner _getEntryPlannerForWeekNo(int weekNo) {
    final matchingPlans =
        _feedingPlanners.where((planner) => planner.weekNo == weekNo);
    if (matchingPlans.isEmpty) {
      debugPrint("No feeding plan found for Week $weekNo");
      return new EntryPlanner();
    }

    EntryPlanner currentPlan = matchingPlans.first;
    return currentPlan;
  }

  int _calculateBabyWeek() {
    final difference = _selectedDay.difference(_babyDOB);
    final weekNo = (difference.inDays / 7).floor() + 1;
    return weekNo;
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final localDay = DateTime(day.year, day.month, day.day);
    final selectedDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    if (localDay != selectedDay) {
      return [];
    }

    final dayEvents =
        (_eventData[localDay] ?? []).whereType<Map<String, dynamic>>().toList();

    EntryPlanner entryPlanner = _getEntryPlannerForWeekNo(_calculateBabyWeek());
    debugPrint("Entry Planner: " + entryPlanner.toJson().toString());
    // Add Planned Feedings
    // If number of feeds in Entry planner is more than Day Events skip
    // If entry planner feedTiming is null or empty, skip
    if (entryPlanner.feedTimings != null &&
        entryPlanner.feedTimings!.isNotEmpty &&
        entryPlanner.feedTimings!.length > dayEvents.length) {
      for (var index =
              dayEvents.length; // skip existing events from journal entries
          index < entryPlanner.feedTimings!.length;
          index++) {
        String currentFeedTimeString = entryPlanner.feedTimings![index];
        DateTime currentFeedTime =
            _parseStringtoDateTime(currentFeedTimeString) ?? DateTime.now();
        String lastFeedTimeString = "00:00 AM";

        if (index > 0 && dayEvents.length > index - 1) {
          lastFeedTimeString = dayEvents[index - 1]['time'] ?? "00:00 AM";
        } else if (index > 0 &&
            entryPlanner.feedTimings!.length > index - 1 &&
            entryPlanner.feedTimings![index - 1].isNotEmpty) {
          lastFeedTimeString = entryPlanner.feedTimings![index - 1];
        }

        DateTime lastFeedDateTime =
            _parseStringtoDateTime(lastFeedTimeString) ?? DateTime.now();
        // if currentFeedTime is less than 2 hours from lastFeedTime, adjust to 2 hours after
        if (currentFeedTime.difference(lastFeedDateTime).inMinutes < 120) {
          currentFeedTime = lastFeedDateTime.add(const Duration(hours: 2));
          currentFeedTimeString = _formatTimeOnly(currentFeedTime);
          // if currentFeedTime is more than 3 hours from lastFeedTime, adjust to 3 hours after
        } else if (currentFeedTime.difference(lastFeedDateTime).inMinutes >
            180) {
          currentFeedTime = lastFeedDateTime.add(const Duration(hours: 3));
          currentFeedTimeString = _formatTimeOnly(currentFeedTime);
        } else {
          currentFeedTimeString = entryPlanner.feedTimings![index];
        }

        dayEvents.add({
          'title': "Feed ${index + 1}",
          'time': currentFeedTimeString,
          'entryId': null,
          'status': "Planned",
        });
      }
    }

    // Force rename title to "Feed index" for all feed events
    int feedCount = 1;
    for (var event in dayEvents) {
      event['title'] = "Feed $feedCount";
      feedCount++;
    }

    debugPrint("Day Events: " + dayEvents.toString());
    return dayEvents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Baby Journal"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await routeTo(CreateJournalEntryPage.path);
              _loadEvents();
            },
            child: Text(
              "New Entry",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (_showBanner)
                        InfoBanner(
                          onClose: () => setState(() => _showBanner = false),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TableCalendar(
                          firstDay: DateTime(2020),
                          lastDay: DateTime(2030),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarFormat: CalendarFormat.month,
                          //   eventLoader: _getEventsForDay,
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: Colors.purpleAccent,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: const HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            titleTextStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isNotEmpty) {
                                return const Positioned(
                                  bottom: 4,
                                  child: Icon(Icons.circle,
                                      size: 6, color: Colors.purple),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: 0.45,
                    minChildSize: 0.2,
                    maxChildSize: 0.75,
                    builder: (context, scrollController) {
                      final events = _getEventsForDay(_selectedDay);

                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            DaySectionHeader(
                                date: _selectedDay,
                                weekNo: _calculateBabyWeek()),
                            const SizedBox(height: 8),
                            if (events.isEmpty)
                              const Text("No entries to display",
                                  style: TextStyle(color: Colors.grey))
                            else
                              ...events.map((event) {
                                return InkWell(
                                  onTap: () async {
                                    final entryId = event['entryId'];
                                    // add a boolean check for null entry
                                    bool isPlannedEntry = entryId == null;
                                    JournalEntry? entry = null;

                                    if (isPlannedEntry) {
                                      final feedTime = event['time'];
                                      DateTime feedDateTime =
                                          _parseStringtoDateTime(feedTime) ??
                                              DateTime.now();
                                      entry = JournalEntry(
                                          startFeedTime: feedDateTime);
                                    } else {
                                      entry = await _controller
                                          .getJournalEntryById(entryId);
                                    }

                                    if (entry == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Failed to load journal entry")));
                                      return;
                                    }

                                    // Prepare controllers
                                    final feedTypeControllers =
                                        <TextEditingController>[];
                                    final feedValueControllers =
                                        <TextEditingController>[];
                                    final feedUnitControllers =
                                        <TextEditingController>[];

                                    if (entry.feedTypes != null) {
                                      for (final feed in entry.feedTypes!) {
                                        feedTypeControllers.add(
                                            TextEditingController(
                                                text: feed.type ?? ''));
                                        feedValueControllers.add(
                                            TextEditingController(
                                                text: feed.value?.toString() ??
                                                    ''));
                                        feedUnitControllers.add(
                                            TextEditingController(
                                                text: feed.unit ?? ''));
                                      }
                                    }

                                    final wakeTimeController =
                                        TextEditingController(
                                            text: entry.startWakeTime != null
                                                ? _formatDateTime(
                                                    entry.startWakeTime!)
                                                : "");
                                    final feedTimeController =
                                        TextEditingController(
                                            text: entry.startFeedTime != null
                                                ? _formatDateTime(
                                                    entry.startFeedTime!)
                                                : "");
                                    final sleepTimeController =
                                        TextEditingController(
                                            text: entry.startSleepTime != null
                                                ? _formatDateTime(
                                                    entry.startSleepTime!)
                                                : "");
                                    final playTimeController =
                                        TextEditingController(
                                            text: entry.startPlayTime != null
                                                ? _formatDateTime(
                                                    entry.startPlayTime!)
                                                : "");

                                    final remarksController =
                                        TextEditingController(
                                            text: entry.remarks ?? '');

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        return GestureDetector(
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          child: Container(
                                            color: Colors.transparent,
                                            child: GestureDetector(
                                              onTap: () {},
                                              child: Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.5,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                          top: Radius.circular(
                                                              16)),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 20),
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                      child: JournalEntryForm(
                                                        wakeTimeController:
                                                            wakeTimeController,
                                                        feedTimeController:
                                                            feedTimeController,
                                                        sleepTimeController:
                                                            sleepTimeController,
                                                        playTimeController:
                                                            playTimeController,
                                                        remarksController:
                                                            remarksController,
                                                        feedTypeControllers:
                                                            feedTypeControllers,
                                                        feedValueControllers:
                                                            feedValueControllers,
                                                        feedUnitControllers:
                                                            feedUnitControllers,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    PrimaryButton(
                                                      onPressed: () async {
                                                        final updatedData =
                                                            JournalEntry(
                                                          startWakeTime:
                                                              parseDateTimeString(
                                                                  wakeTimeController
                                                                      .text),
                                                          startFeedTime:
                                                              parseDateTimeString(
                                                                  feedTimeController
                                                                      .text),
                                                          startPlayTime:
                                                              parseDateTimeString(
                                                                  playTimeController
                                                                      .text),
                                                          startSleepTime:
                                                              parseDateTimeString(
                                                                  sleepTimeController
                                                                      .text),
                                                          remarks:
                                                              remarksController
                                                                  .text,
                                                          feedTypes: List.generate(
                                                              feedTypeControllers
                                                                  .length,
                                                              (index) {
                                                            return FeedType(
                                                              type:
                                                                  feedTypeControllers[
                                                                          index]
                                                                      .text,
                                                              value: int.tryParse(
                                                                  feedValueControllers[
                                                                          index]
                                                                      .text),
                                                              unit:
                                                                  feedUnitControllers[
                                                                          index]
                                                                      .text,
                                                            );
                                                          }),
                                                        );
                                                        if (isPlannedEntry) {
                                                          // use create entry method
                                                          await _journalApiService
                                                              .create(
                                                            id: await Keys
                                                                .selectedBabyId
                                                                .read(),
                                                            data: updatedData,
                                                          );
                                                        } else {
                                                          await _controller
                                                              .updateJournalEntry(
                                                            entryId:
                                                                entry!.id ?? '',
                                                            babyId: await Keys
                                                                .selectedBabyId
                                                                .read(),
                                                            data: updatedData,
                                                          );
                                                        } 
                                                        Navigator.pop(context);
                                                        _loadEvents();
                                                      },
                                                      text: "Save Changes",
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: EventTile(
                                    title: event['title'] ?? 'Feed',
                                    subtitle: event['time'] ?? '',
                                    color: Colors.green,
                                    status: event['status'] ?? 'Incomplete',
                                  ),
                                );
                              }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String _formatTimeOnly(DateTime dateTime) {
    // Format the time as HH:mm AM/PM
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
      now.year,
      now.month,
      now.day,
      hour.clamp(0, 23),
      minute.clamp(0, 59),
    );
  }

  String convertTo24HourString(String timeString) {
    DateTime? dateTime = _parseStringtoDateTime(timeString);
    if (dateTime == null) {
      return '';
    }
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
