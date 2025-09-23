import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:best_flutter_ui_templates/screens/providers/widget.dart';

import '../model/journal_entry.dart';
import '../model/feed_type.dart';
import '../network/journal_api.dart';
import '../routes.dart';
import 'dart:convert';

const _kFeedTypes = ['EBM', 'Formula', 'Breast (Left)', 'Breast (Right)'];
String _unitForType(String? t) {
  if (t == null) return 'mL';
  return t.startsWith('BF') ? 'min' : 'mL';
}

class EditJournalEntryPage extends StatefulWidget {
  final String babyId;
  final JournalEntry? initialJournalEntry;
  const EditJournalEntryPage({
    super.key,
    required this.babyId,
    this.initialJournalEntry,
  });
  @override
  State<EditJournalEntryPage> createState() => _EditJournalEntryPageState();
}

class _EditJournalEntryPageState extends State<EditJournalEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // TODO get cycle no
  int cycle = 5;
  final remarksController = TextEditingController();

  DateTime startWakeTime = DateTime.now();
  DateTime startFeedTime = DateTime.now();
  DateTime startPlayTime = DateTime.now();
  DateTime startSleepTime = DateTime.now();

  bool hasUrine = false;
  bool hasStool = false;

  final List<TextEditingController> _feedTypeCtrls = [];
  final List<TextEditingController> _feedValueCtrls = [];
  final List<String> _feedUnits = []; // 'mL' or 'minutes'

  @override
  void initState() {
    super.initState();
    loadInitialJournalEntry();
  }

  @override
  void dispose() {
    for (final c in _feedTypeCtrls) {
      c.dispose();
    }
    for (final c in _feedValueCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void loadInitialJournalEntry() {
    String token = get_token(context) ?? "";
    String babyId = get_babyid(context) ?? "";
    if (token.isEmpty) {
      debugPrint("No token found. User may not be logged in.");
      return;
    }

    JournalAPI.getJournalEntryById(
      widget.initialJournalEntry?.id ?? '',
      babyId,
      token,
    ).then((response) {
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        JournalEntry journalEntry = JournalEntry.fromJson(
          json.decode(response.body),
        );
        setState(() {
          debugPrint("BabyId: $babyId");
          debugPrint("EntryId: ${journalEntry.id}");

          hasUrine = journalEntry.hasUrine ?? false;
          hasStool = journalEntry.hasStool ?? false;

          // To fix time being off by 8 hours, create a new DateTime
          startWakeTime = DateTime(
            journalEntry.startWakeTime!.year,
            journalEntry.startWakeTime!.month,
            journalEntry.startWakeTime!.day,
            journalEntry.startWakeTime!.hour,
            journalEntry.startWakeTime!.minute,
          );

          startFeedTime = DateTime(
            journalEntry.startFeedTime!.year,
            journalEntry.startFeedTime!.month,
            journalEntry.startFeedTime!.day,
            journalEntry.startFeedTime!.hour,
            journalEntry.startFeedTime!.minute,
          );
          startPlayTime = DateTime(
            journalEntry.startPlayTime!.year,
            journalEntry.startPlayTime!.month,
            journalEntry.startPlayTime!.day,
            journalEntry.startPlayTime!.hour,
            journalEntry.startPlayTime!.minute,
          );
          startSleepTime = DateTime(
            journalEntry.startSleepTime!.year,
            journalEntry.startSleepTime!.month,
            journalEntry.startSleepTime!.day,
            journalEntry.startSleepTime!.hour,
            journalEntry.startSleepTime!.minute,
          );

          remarksController.text = journalEntry.remarks ?? '';

          //feed types controllers
          _feedTypeCtrls.clear();
          _feedValueCtrls.clear();
          _feedUnits.clear();

          List<FeedType> feedTypes = [];

          if (journalEntry.feedTypes != null &&
              journalEntry.feedTypes!.isNotEmpty) {
            feedTypes = journalEntry.feedTypes!;
          } else {
            // At least have one feed type field
            _addFeed();
          }

          for (var feedType in feedTypes) {
            debugPrint("AAAA");
            final typeCtrl = TextEditingController(text: feedType.type);
            final valueCtrl = TextEditingController(
              text: feedType.value.toString(),
            );
            _feedTypeCtrls.add(typeCtrl);
            _feedValueCtrls.add(valueCtrl);
            _feedUnits.add(feedType.unit ?? 'mL');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Edit Journal Entry'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            children: [
              _weekHeader(),
              SizedBox(height: 20),
              cupertinoDate(
                context,
                startWakeTime,
                'Awake Time',
                (newDateTime) => setState(() => startWakeTime = newDateTime),
              ),
              SizedBox(height: 12),
              cupertinoDate(
                context,
                startFeedTime,
                'Feed Time',
                (newDateTime) => setState(() => startFeedTime = newDateTime),
              ),
              const SizedBox(height: 12),
              _LabeledField(label: "Feed Type", child: Container()),
              for (int i = 0; i < _feedTypeCtrls.length; i++) ...[
                _feedGroup(i),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _addFeed,
                  child: const Text(
                    '+ Add more feed types',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              cupertinoDate(
                context,
                startPlayTime,
                'Play Time',
                (newDateTime) => setState(() => startPlayTime = newDateTime),
              ),
              const SizedBox(height: 12),
              cupertinoDate(
                context,
                startSleepTime,
                'Sleep Time',
                (newDateTime) => setState(() => startSleepTime = newDateTime),
              ),
              const SizedBox(height: 12),
              _textField(
                label: 'Remarks',
                controller: remarksController,
                hintText: 'Add any remarks here',
                onChanged: (value) =>
                    setState(() => remarksController.text = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: hasUrine,
                    onChanged: (v) => setState(() => hasUrine = v ?? false),
                  ),
                  const Text('Pee', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 24),
                  Checkbox(
                    value: hasStool,
                    onChanged: (v) => setState(() => hasStool = v ?? false),
                  ),
                  const Text('Poo', style: TextStyle(fontSize: 20)),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: const StadiumBorder(),
          ),
          child: const Text('Save'),
        ),
      ),
    );
  }

  Widget _feedGroup(int index) {
    final typeCtrl = _feedTypeCtrls[index];
    final valueCtrl = _feedValueCtrls[index];

    // keep unit in sync with type (in case initial data had empty unit)
    final currentUnit = _unitForType(
      typeCtrl.text.isEmpty ? null : typeCtrl.text,
    );
    if (_feedUnits[index] != currentUnit) {
      _feedUnits[index] = currentUnit;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Type
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  color: Theme.of(context).colorScheme.surface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonFormField<String>(
                  value: typeCtrl.text.isEmpty ? null : typeCtrl.text,
                  items: _kFeedTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      typeCtrl.text = v ?? '';
                      _feedUnits[index] = _unitForType(v);
                    });
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Feed Type',
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),

            // Value
            Expanded(
              flex: 7,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  color: Theme.of(context).colorScheme.surface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: valueCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Unit label
                    Text(
                      _feedUnits[index],
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            // const SizedBox(width: 12),

            // Remove feed button (show if >1)
            if (_feedTypeCtrls.length > 1) ...[
              const SizedBox(width: 6),
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    splashRadius: 18,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeFeed(index),
                    tooltip: 'Remove',
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _addFeed() {
    setState(() {
      _feedTypeCtrls.add(TextEditingController());
      _feedValueCtrls.add(TextEditingController());
      _feedUnits.add('mL');
    });
  }

  void _removeFeed(int i) {
    setState(() {
      _feedTypeCtrls.removeAt(i).dispose();
      _feedValueCtrls.removeAt(i).dispose();
      _feedUnits.removeAt(i);
    });
  }

  Widget _weekHeader() {
    var _date = DateTime.now();
    final week = _weekNumber(_date);
    return Row(
      children: [
        const Text('Week ', style: TextStyle(fontSize: 16)),
        GestureDetector(
          onTap: () {},
          child: Text(
            '$week',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        // The Bottom margin is provided to align the popup above the system
        // navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(top: false, child: child),
      ),
    );
  }

  Widget cupertinoDate(
    BuildContext context,
    DateTime dateTime,
    String label,
    ValueChanged<DateTime> onChanged,
  ) {
    return _LabeledField(
      label: label,
      child: InkWell(
        // Give the blinking effect when clicked
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          // Display a CupertinoDatePicker in dateTime picker mode.
          onPressed: () => _showDialog(
            CupertinoDatePicker(
              initialDateTime: dateTime,
              use24hFormat: true,
              // This is called when the user changes the dateTime.
              onDateTimeChanged: (DateTime newDateTime) {
                // setState(() => dateTime = newDateTime);
                onChanged(newDateTime);
              },
            ),
          ),
          child: _ReadOnlyBox(
            text:
                "${dateTime.day}/${dateTime.month}/${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}",
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    required ValueChanged<String> onChanged,
  }) {
    return _LabeledField(
      label: label,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: TextFormField(
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: hintText,
          ),
          style: const TextStyle(fontSize: 18),
          onChanged: onChanged,
          controller: controller,
        ),
      ),
    );
  }

  void onTest() {
    debugPrint("Reach AAA");

    // get data from feed types
    for (int i = 0; i < _feedTypeCtrls.length; i++) {
      debugPrint(
        "Feed Type: ${_feedTypeCtrls[i].text}, Value: ${_feedValueCtrls[i].text} ${_feedUnits[i]}",
      );
    }
  }

  void onSave() async {
    List<FeedType> feedTypes = [];
    for (int i = 0; i < _feedTypeCtrls.length; i++) {
      String type = _feedTypeCtrls[i].text;
      int? value = int.tryParse(_feedValueCtrls[i].text);
      String unit = _feedUnits[i];
      if (type.isNotEmpty && value != null) {
        feedTypes.add(FeedType(type: type, value: value, unit: unit));
      }
    }
    debugPrint("HasUrine: ${hasUrine.toString()}");

    final entry = JournalEntry(
      cycleNo: cycle,
      hasUrine: hasUrine,
      hasStool: hasStool,
      startWakeTime: startWakeTime,
      startFeedTime: startFeedTime,
      startPlayTime: startPlayTime,
      startSleepTime: startSleepTime,
      feedTypes: feedTypes,
      remarks: remarksController.text,
    );

    String babyId = get_babyid(context) ?? "";
    String entryId = widget.initialJournalEntry?.id ?? "";
    // debugPrint("Saving entry for babyId: $babyId");
    // debugPrint("Entry ID: $entryId");
    // debugPrint("Journey Entry Urine: ${entry.hasUrine}");

    final token = get_token(context);
    if (token == null) {
      debugPrint("No token found. User may not be logged in.");
      return;
    }

    // Check sending Journal Entry
    debugPrint("Remarks: ${entry.remarks}");

    JournalAPI.updateJournalEntry(entryId, babyId, entry, token).then(
      (value) => {
        debugPrint("Response status: ${value.statusCode}"),
        debugPrint("Response body: ${value.body}"),

        if (value.statusCode == 200)
          {
            // Navigate to calendar
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.calendar,
              (route) => false,
            ),
          },
      },
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1565C0), // Darker blue
              fontSize: 18, // Increased font size
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  final String text;
  const _ReadOnlyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, color: Colors.black87),
      ),
    );
  }
}

int _weekNumber(DateTime date) {
  // ISO 8601 week number
  final thursday = date.add(Duration(days: 3 - ((date.weekday + 6) % 7)));
  final firstThursday = DateTime(thursday.year, 1, 4);
  return 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
}
