import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/feed_type.dart';
import 'package:flutter_app/app/models/journal_entry.dart';
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
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _eventData = {};
  bool _showBanner = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    setState(() => _loading = true);
    final events = await _controller.getCalendarData();
    setState(() {
      _eventData = events ?? {};
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final localDay = DateTime(day.year, day.month, day.day);
    return _eventData[localDay] ?? [];
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
                          eventLoader: _getEventsForDay,
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
                            DaySectionHeader(date: _selectedDay),
                            const SizedBox(height: 8),
                            if (events.isEmpty)
                              const Text("No entries to display",
                                  style: TextStyle(color: Colors.grey))
                            else
                              ...events.map((event) {
                                return InkWell(
                                  onTap: () async {
                                    final entryId = event['entryId'];
                                    final entry = await _controller
                                        .getJournalEntryById(entryId);

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
                                                        await _controller
                                                            .updateJournalEntry(
                                                          entryId: entry.id!,
                                                          babyId: await Keys
                                                              .selectedBabyId
                                                              .read(),
                                                          data: updatedData,
                                                        );

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
                                    color: Colors.purple,
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
