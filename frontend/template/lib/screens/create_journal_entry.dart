import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JournalEntry {
  DateTime date;
  String? cycle; // e.g., "First Feed"
  TimeOfDay? wakeTime;
  TimeOfDay? feedTime;
  TimeOfDay? playTime;
  TimeOfDay? sleepTime;

  // Advanced fields
  TimeOfDay? wakeUpTime;
  TimeOfDay? startFeedTime;
  String? typeOfFeed; // EBM / FM / Direct Latch etc.
  int? totalFeedRightMins;
  int? totalFeedLeftMins;
  int? feedAmountMl;
  TimeOfDay? startPlayTime;
  TimeOfDay? startSleepTime;
  Duration? sleepDuration;
  bool pee;
  bool poo;

  JournalEntry({
    required this.date,
    this.cycle,
    this.wakeTime,
    this.feedTime,
    this.playTime,
    this.sleepTime,
    this.wakeUpTime,
    this.startFeedTime,
    this.typeOfFeed,
    this.totalFeedRightMins,
    this.totalFeedLeftMins,
    this.feedAmountMl,
    this.startPlayTime,
    this.startSleepTime,
    this.sleepDuration,
    this.pee = false,
    this.poo = false,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'cycle': cycle,
        'wakeTime': _fmtTOD(wakeTime),
        'feedTime': _fmtTOD(feedTime),
        'playTime': _fmtTOD(playTime),
        'sleepTime': _fmtTOD(sleepTime),
        'wakeUpTime': _fmtTOD(wakeUpTime),
        'startFeedTime': _fmtTOD(startFeedTime),
        'typeOfFeed': typeOfFeed,
        'totalFeedRightMins': totalFeedRightMins,
        'totalFeedLeftMins': totalFeedLeftMins,
        'feedAmountMl': feedAmountMl,
        'startPlayTime': _fmtTOD(startPlayTime),
        'startSleepTime': _fmtTOD(startSleepTime),
        'sleepDuration': sleepDuration?.inSeconds,
        'pee': pee,
        'poo': poo,
      };

  static String? _fmtTOD(TimeOfDay? t) => t == null ? null : _formatTimeOfDay(t);
}

class JournalEntryPage extends StatefulWidget {
  final JournalEntry? initial;
  final ValueChanged<JournalEntry>? onSave;
  const JournalEntryPage({super.key, this.initial, this.onSave});

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  final _formKey = GlobalKey<FormState>();
  bool _showAllFields = false;

  // Core state
  late DateTime _date;
  TimeOfDay? _wakeTime;
  TimeOfDay? _feedTime;
  TimeOfDay? _playTime;
  TimeOfDay? _sleepTime;

  // Advanced state
  String? _cycle;
  TimeOfDay? _wakeUpTime;
  TimeOfDay? _startFeedTime;
  String? _typeOfFeed;
  final _totalRightCtrl = TextEditingController();
  final _totalLeftCtrl = TextEditingController();
  final _feedAmountCtrl = TextEditingController();
  TimeOfDay? _startPlayTime;
  TimeOfDay? _startSleepTime;
  final _sleepDurationCtrl = TextEditingController(text: '02:30:00');
  bool _pee = false;
  bool _poo = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _date = init?.date ?? DateTime.now();
    _wakeTime = init?.wakeTime;
    _feedTime = init?.feedTime;
    _playTime = init?.playTime;
    _sleepTime = init?.sleepTime;

    _cycle = init?.cycle;
    _wakeUpTime = init?.wakeUpTime;
    _startFeedTime = init?.startFeedTime;
    _typeOfFeed = init?.typeOfFeed;
    if (init?.totalFeedRightMins != null) {
      _totalRightCtrl.text = init!.totalFeedRightMins.toString();
    }
    if (init?.totalFeedLeftMins != null) {
      _totalLeftCtrl.text = init!.totalFeedLeftMins.toString();
    }
    if (init?.feedAmountMl != null) {
      _feedAmountCtrl.text = init!.feedAmountMl.toString();
    }
    if (init?.sleepDuration != null) {
      _sleepDurationCtrl.text = _formatDuration(init!.sleepDuration!);
    }
    _startPlayTime = init?.startPlayTime;
    _startSleepTime = init?.startSleepTime;
    _pee = init?.pee ?? false;
    _poo = init?.poo ?? false;
  }

  @override
  void dispose() {
    _totalRightCtrl.dispose();
    _totalLeftCtrl.dispose();
    _feedAmountCtrl.dispose();
    _sleepDurationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Log an Entry'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showAllFields = !_showAllFields),
            child: Text(_showAllFields ? 'Simple' : 'Edit'),
          )
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _weekHeader(),
              const SizedBox(height: 8),
              _dateField(context),
              const SizedBox(height: 12),
              _timeField(context, label: 'Wake time', value: _wakeTime,
                  onPicked: (t) => setState(() => _wakeTime = t)),
              const SizedBox(height: 12),
              _timeField(context, label: 'Feed time', value: _feedTime,
                  onPicked: (t) => setState(() => _feedTime = t)),
              const SizedBox(height: 12),
              _timeField(context, label: 'Play time', value: _playTime,
                  onPicked: (t) => setState(() => _playTime = t)),
              const SizedBox(height: 12),
              _timeField(context, label: 'Sleep time', value: _sleepTime,
                  onPicked: (t) => setState(() => _sleepTime = t)),
              if (_showAllFields) ...[
                const SizedBox(height: 24),
                _section('All fields'),
                _textField(label: 'Cycle', onChanged: (v) => _cycle = v),
                _timeField(context, label: 'Wake Up time', value: _wakeUpTime,
                    onPicked: (t) => setState(() => _wakeUpTime = t)),
                _timeField(context, label: 'Start of Feed Time', value: _startFeedTime,
                    onPicked: (t) => setState(() => _startFeedTime = t)),
                _textField(label: 'Type of Feed', onChanged: (v) => _typeOfFeed = v,
                    hintText: 'EBM / FM / Direct Latch'),
                _numberField('Total Feed Time in Mins (R)', _totalRightCtrl),
                _numberField('Total Feed Time in Mins (L)', _totalLeftCtrl),
                _numberField('Feed Amount (mL)', _feedAmountCtrl),
                _timeField(context, label: 'Start of Play Time', value: _startPlayTime,
                    onPicked: (t) => setState(() => _startPlayTime = t)),
                _timeField(context, label: 'Start of Sleep Time', value: _startSleepTime,
                    onPicked: (t) => setState(() => _startSleepTime = t)),
                _durationField(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(value: _pee, onChanged: (v) => setState(() => _pee = v ?? false)),
                    const Text('Pee'),
                    const SizedBox(width: 24),
                    Checkbox(value: _poo, onChanged: (v) => setState(() => _poo = v ?? false)),
                    const Text('Poo'),
                  ],
                ),
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
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: const StadiumBorder()),
          child: const Text('Save'),
        ),
      ),
    );
  }

  Widget _weekHeader() {
    final week = _weekNumber(_date);
    return Row(
      children: [
        const Text('Week ', style: TextStyle(fontSize: 16)),
        GestureDetector(
          onTap: () {},
          child: Text('$week', style: const TextStyle(fontSize: 18, color: Colors.blue, decoration: TextDecoration.underline)),
        )
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _dateField(BuildContext context) {
    return _LabeledField(
      label: 'Date',
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) setState(() => _date = picked);
        },
        child: _ReadOnlyBox(text: _formatDate(_date)),
      ),
    );
  }

  Widget _timeField(BuildContext context, {required String label, required TimeOfDay? value, required ValueChanged<TimeOfDay> onPicked}) {
    return _LabeledField(
      label: label,
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(context: context, initialTime: value ?? TimeOfDay.now());
          if (picked != null) onPicked(picked);
        },
        child: _ReadOnlyBox(text: value == null ? '' : _formatTimeOfDay(value)),
      ),
    );
  }

  Widget _durationField() {
    return _LabeledField(
      label: 'Sleep Duration',
      child: TextFormField(
        controller: _sleepDurationCtrl,
        decoration: const InputDecoration(hintText: 'HH:MM:SS'),
        validator: (v) {
          if (v == null || v.isEmpty) return null; // optional
          return _parseDuration(v) == null ? 'Use HH:MM:SS' : null;
        },
      ),
    );
  }

  Widget _textField({required String label, String? hintText, required ValueChanged<String> onChanged}) {
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

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final entry = JournalEntry(
      date: _date,
      cycle: _cycle,
      wakeTime: _wakeTime,
      feedTime: _feedTime,
      playTime: _playTime,
      sleepTime: _sleepTime,
      wakeUpTime: _wakeUpTime,
      startFeedTime: _startFeedTime,
      typeOfFeed: _typeOfFeed,
      totalFeedRightMins: _tryParseInt(_totalRightCtrl.text),
      totalFeedLeftMins: _tryParseInt(_totalLeftCtrl.text),
      feedAmountMl: _tryParseInt(_feedAmountCtrl.text),
      startPlayTime: _startPlayTime,
      startSleepTime: _startSleepTime,
      sleepDuration: _parseDuration(_sleepDurationCtrl.text),
      pee: _pee,
      poo: _poo,
    );

    widget.onSave?.call(entry);
    // For now, pop and return the entry
    Navigator.of(context).pop(entry);
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
          child: Text(label, style: const TextStyle(color: Colors.blue)),
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
      child: Text(text),
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

int? _tryParseInt(String s) => s.trim().isEmpty ? null : int.tryParse(s.trim());

Duration? _parseDuration(String? hhmmss) {
  if (hhmmss == null || hhmmss.isEmpty) return null;
  final parts = hhmmss.split(':');
  if (parts.length != 3) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final s = int.tryParse(parts[2]);
  if (h == null || m == null || s == null) return null;
  return Duration(hours: h, minutes: m, seconds: s);
}

String _formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}
