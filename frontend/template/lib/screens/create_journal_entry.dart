import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/journal_entry.dart';
import '../network/journal_api.dart';

class Feed {
  String type; // e.g. EBM / FM / BF(L) / BF(R)
  String unit; // mL or minutes
  double? value; // numeric value

  Feed({this.type = '', this.unit = 'mL', this.value});

  Map<String, dynamic> toJson() => {'type': type, 'unit': unit, 'value': value};
  bool get isEmpty => type.isEmpty && (value == null);
}

const _kFeedTypes = ['EBM', 'FM', 'BF (L)', 'BF (R)'];
String _unitForType(String? t) {
  if (t == null) return 'mL';
  return t.startsWith('BF') ? 'minutes' : 'mL';
}

class JournalEntryPage extends StatefulWidget {
  final String babyId;
  final JournalEntry? initial;
  final ValueChanged<JournalEntry>? onSave;
  const JournalEntryPage({
    super.key,
    required this.babyId,
    this.initial,
    this.onSave,
  });
  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  final _formKey = GlobalKey<FormState>();
  bool _showAllFields = false;

  // Advanced state
  String? _cycle;
  final _cycleNoCtrl = TextEditingController();
  String? _typeOfFeed;
  final _totalRightCtrl = TextEditingController();
  final _totalLeftCtrl = TextEditingController();
  final _feedAmountCtrl = TextEditingController();
  final _sleepDurationCtrl = TextEditingController(text: '02:30:00');
  bool _pee = false;
  bool _poo = false;

  DateTime _startWakeTime = DateTime.now();
  DateTime _startFeedTime = DateTime.now();
  DateTime _startPlayTime = DateTime.now();
  DateTime _startSleepTime = DateTime.now();
  TimeOfDay? _playTime;

  final List<TextEditingController> _feedTypeCtrls = [];
  final List<TextEditingController> _feedValueCtrls = [];
  final List<String> _feedUnits = []; // 'mL' or 'minutes'

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
  }

  @override
  void dispose() {
    _totalRightCtrl.dispose();
    _totalLeftCtrl.dispose();
    _feedAmountCtrl.dispose();
    _sleepDurationCtrl.dispose();
    for (final c in _feedTypeCtrls) {
      c.dispose();
    }
    for (final c in _feedValueCtrls) {
      c.dispose();
    }
    _cycleNoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Log Journal Entry'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showAllFields = !_showAllFields),
            child: Text(_showAllFields ? 'Simple' : 'Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            children: [
              _weekHeader(),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: _cupertinoDate(
                  context,
                  _startWakeTime,
                  'Awake Time',
                  (newDateTime) => setState(() => _startWakeTime = newDateTime),
                ),
              ),
              SizedBox(height: 12),
              _cupertinoDate(
                context,
                _startFeedTime,
                'Feed Time',
                (newDateTime) => setState(() => _startFeedTime = newDateTime),
              ),
              const SizedBox(height: 12),
              _section('Feed(s)'),
              for (int i = 0; i < _feedTypeCtrls.length; i++) ...[
                _feedGroup(i),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _addFeed,
                  child: const Text(
                    '+ Add new feed',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _pee,
                    onChanged: (v) => setState(() => _pee = v ?? false),
                  ),
                  const Text('Pee'),
                  const SizedBox(width: 24),
                  Checkbox(
                    value: _poo,
                    onChanged: (v) => setState(() => _poo = v ?? false),
                  ),
                  const Text('Poo'),
                ],
              ),
              if (_showAllFields) ...[
                const SizedBox(height: 24),
                _section('Advanced (legacy)'),
                _textField(label: 'Cycle', onChanged: (v) => _cycle = v),
                _LabeledField(
                  label: 'Cycle No',
                  child: TextFormField(
                    controller: _cycleNoCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(hintText: 'e.g. 4'),
                    onChanged: (v) => _cycle = v,
                  ),
                ),
                _textField(
                  label: 'Type of Feed (legacy)',
                  onChanged: (v) => _typeOfFeed = v,
                ),
                _numberField('Total Feed Time in Mins (R)', _totalRightCtrl),
                _numberField('Total Feed Time in Mins (L)', _totalLeftCtrl),
                _numberField('Feed Amount (mL)', _feedAmountCtrl),
              ],
              const SizedBox(height: 80), // spacing for bottom button
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _onSave,
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
        Text(
          'Feed Type ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        // Feed TYPE dropdown
        DropdownButtonFormField<String>(
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
            hintText: 'Select feed type',
            isDense: true,
          ),
        ),

        const SizedBox(height: 12),

        // Row: Value (left) • Unit (right, auto-filled)
        Row(
          children: [
            // VALUE
            Expanded(
              flex: 2,
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
                  isDense: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  return double.tryParse(v) == null ? 'Numeric' : null;
                },
              ),
            ),

            const SizedBox(width: 12),

            // UNIT (read-only, auto-filled)
            Expanded(
              flex: 1,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                child: Text(_feedUnits[index]),
              ),
            ),

            // Remove feed button (show if >1)
            if (_feedTypeCtrls.length > 1) ...[
              const SizedBox(width: 6),
              SizedBox(
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

  Widget _cupertinoDate(
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
          // child: Text(
          //   // Format DateTime
          //   '${dateTime.month}/${dateTime.day}/${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
          //   style: const TextStyle(fontSize: 22.0),
          // ),
          child: _ReadOnlyBox(
            text:
                "${dateTime.day}/${dateTime.month}/${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}",
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  Widget _timeField(
    BuildContext context, {
    required String label,
    required TimeOfDay? value,
    required ValueChanged<TimeOfDay> onPicked,
  }) {
    return _LabeledField(
      label: label,
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: value ?? TimeOfDay.now(),
          );
          if (picked != null) onPicked(picked);
        },
        child: _ReadOnlyBox(text: value == null ? '' : _formatTimeOfDay(value)),
      ),
    );
  }

  Widget _textField({
    required String label,
    String? hintText,
    required ValueChanged<String> onChanged,
  }) {
    return _LabeledField(
      label: label,
      child: TextFormField(
        decoration: InputDecoration(hintText: hintText),
        onChanged: onChanged,
      ),
    );
  }

  Widget _numberField(String label, TextEditingController ctrl) {
    return _LabeledField(
      label: label,
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(hintText: '0'),
      ),
    );
  }

  void _onSave() async {
    final entry = JournalEntry(remarks: "test");

    debugPrint("Reach AAA");
    String babyId = "W6bOM4UJxxfbo0bktsmO"; // Replace with actual babyId

    JournalAPI.createJournalEntry(babyId, entry).then((response) {
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");
    });
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

// ----------------- Helpers -----------------
String _formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String _formatTimeOfDay(TimeOfDay t) {
  final hours = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final minutes = t.minute.toString().padLeft(2, '0');
  final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hours : $minutes $suffix';
}

int _weekNumber(DateTime date) {
  // ISO 8601 week number
  final thursday = date.add(Duration(days: 3 - ((date.weekday + 6) % 7)));
  final firstThursday = DateTime(thursday.year, 1, 4);
  return 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
}

