import 'package:nylo_framework/nylo_framework.dart';

class Baby extends Model {
  String? id;
  String? name;
  DateTime? dob;
  DateTime? expectedDueDate;
  int? term;
  double? weight;
  // New optional fields
  String? gender; // e.g. Male/Female/Other
  double? height; // height in cm (optional)
  String? trainerName; // assigned trainer's display name if provided by API
  String? healthConditions;
  DateTime? createdAt;
  DateTime? deletedAt;

  static StorageKey key = "baby";

  Baby({
    this.id,
    this.name,
    this.dob,
    this.expectedDueDate,
    this.term,
    this.weight,
    this.gender,
    this.height,
    this.trainerName,
    this.healthConditions,
    this.createdAt,
    this.deletedAt,
  }) : super(key: key);

  Baby.fromJson(dynamic data) : super(key: key) {
    id = data['id']?.toString();
    name = data['name']?.toString();
    dob = parseFlexibleDateTime(data['dob']);
    expectedDueDate = parseFlexibleDateTime(data['expectedDueDate']);
    createdAt = parseFlexibleDateTime(data['createdAt']);
    deletedAt = parseFlexibleDateTime(data['deletedAt']);
    term = _toInt(data['term']);
    weight = _toDouble(data['weight']);
    gender = data['gender']?.toString();
    height = _toDouble(data['height']);
    trainerName = data['trainerName']?.toString() ?? data['trainer']?.toString();
    healthConditions = data['healthConditions']?.toString();
  }

  @override
  toJson() {
    return {
      'id': id,
      'name': name,
      // API expects date-only in ISO (yyyy-MM-dd)
      'dob': _dateToIsoDate(dob),
      'expectedDueDate': _dateToIsoDate(expectedDueDate),
      'term': term,
      'weight': weight,
      if (gender != null) 'gender': gender,
      if (height != null) 'height': height,
      if (trainerName != null) 'trainerName': trainerName,
      'healthConditions': healthConditions,
      // Keep full ISO for timestamps where appropriate
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

// Helpers

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String? _dateToIsoDate(DateTime? dt) => dt?.toIso8601String().substring(0, 10);

DateTime? parseFlexibleDateTime(dynamic value) {
  if (value == null) return null;

  // Firestore Timestamp-like map
  if (value is Map) {
    final seconds = value['_seconds'] ?? value['seconds'];
    final nanos = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
    if (seconds is int) {
      final ms = seconds * 1000 + ((nanos is int) ? (nanos ~/ 1000000) : 0);
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
  }

  // Milliseconds since epoch
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
  }

  // String date: try ISO or yyyy-MM-dd
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  final dt = DateTime.tryParse(s);
  if (dt != null) return dt.toLocal();

  // Attempt dd/MM/yyyy
  final parts = s.split("/");
  if (parts.length == 3) {
    final day = int.tryParse(parts[0]);
    final mon = int.tryParse(parts[1]);
    final yr = int.tryParse(parts[2]);
    if (day != null && mon != null && yr != null) {
      return DateTime(yr, mon, day);
    }
  }

  return null;
}
