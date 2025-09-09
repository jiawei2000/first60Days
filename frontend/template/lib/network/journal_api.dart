// lib/network/journal_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../screens/create_journal_entry.dart' show JournalEntry, Feed;

/// Android emulator hits host via 10.0.2.2
const String _baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

class JournalApi {
  final String token;
  JournalApi(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<String> createEntry({
    required String babyId,
    required JournalEntry entry,
  }) async {
    final uri = Uri.parse('$_baseUrl/journal/newEntry');
    final body = _mapEntry(entry)..['babyId'] = babyId;
    final payload = jsonEncode(body);
    debugPrint('>> POST /journal/newEntry payload: $payload');
    debugPrint('>> has cycleNo: ${body.containsKey('cycleNo')} value: ${body['cycleNo']}');
    final res = await http.post(uri, headers: _headers, body: payload);
    debugPrint('<< status: ${res.statusCode} body: ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['entryId'] as String;
    }
    throw _err(res);
  }

  Future<void> updateEntry({
    required String babyId,
    required String entryId,
    required JournalEntry entry,
  }) async {
    final uri = Uri.parse('$_baseUrl/journal/editEntry/$babyId/$entryId');
    final body = _mapEntry(entry);
    final res = await http.put(uri, headers: _headers, body: jsonEncode(body));
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw _err(res);
  }

  // ---------- helpers ----------
  Map<String, dynamic> _mapEntry(JournalEntry e) {
    DateTime? _combine(TimeOfDay? tod) {
      if (tod == null) return null;
      final d = e.date;
      return DateTime(d.year, d.month, d.day, tod.hour, tod.minute);
    }

    // Backend sample shows an integer (hours). Adjust if your API expects seconds.
    int? _sleepHours(Duration? d) => d == null ? null : d.inHours;

    // Map UI feeds -> backend feedType array
  List<Map<String, dynamic>>? _feedType() {
    if (e.feeds.isEmpty) return null;
    final out = <Map<String, dynamic>>[];
    for (final f in e.feeds) {
      final t = f.type.trim().toLowerCase();
      if (t.isEmpty) continue;
      // normalize keys
      if (t == 'ebm' || t == 'fm' || t == 'formula') {
        if (f.value != null) out.add({'type': t == 'fm' ? 'formula' : 'ebm', 'ml': f.value});
      } else if (t == 'bf l' || t == 'bf r' || t == 'bf(l)' || t == 'bf(r)' || t == 'breastfeed') {
        if (f.value != null) out.add({'type': 'breastfeed', 'minutes': f.value});
      } else {
        // fallback: pass as-is with a neutral value key
        if (f.value != null) out.add({'type': f.type, 'value': f.value});
      }
    }
    return out.isEmpty ? null : out;
  }

    final m = <String, dynamic>{
      'awakeTime'     : _combine(e.wakeTime)?.toIso8601String(),
      'startFeedTime' : _combine(e.feedTime ?? e.startFeedTime)?.toIso8601String(),
      'startPlayTime' : _combine(e.playTime ?? e.startPlayTime)?.toIso8601String(),
      'startSleepTime': _combine(e.sleepTime ?? e.startSleepTime)?.toIso8601String(),
      'sleepDuration' : _sleepHours(e.sleepDuration), // <- integer hours
      'urine'         : e.pee,
      'stool'         : e.poo,
      'cycleNo'       : e.cycle,
      'feedType'      : _feedType(),
      'remarks'       : '',
    };
    return m;
  }

  Exception _err(http.Response r) {
    try {
      final m = jsonDecode(r.body);
      final msg = (m is Map && m['error'] != null) ? m['error'].toString() : r.body;
      return Exception('HTTP ${r.statusCode}: $msg');
    } catch (_) {
      return Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }
}
