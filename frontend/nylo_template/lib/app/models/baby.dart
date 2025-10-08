import 'package:nylo_framework/nylo_framework.dart';

class Baby extends Model {
  String? id;
  String? name;
  DateTime? dob;
  DateTime? expectedDueDate;
  String? term;
  double? weight;
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
    this.healthConditions,
    this.createdAt,
    this.deletedAt,
  }) : super(key: key);

  Baby.fromJson(dynamic data) : super(key: key) {
    id = data['id']?.toString();
    name = data['name'];
    dob = parseTimestamp(data['dob']);
    expectedDueDate = parseTimestamp(data['expectedDueDate']);
    term = data['term'];
    weight = data['weight']?.toDouble();
    healthConditions = data['healthConditions'];
    createdAt = parseTimestamp(data['createdAt']);
    deletedAt = parseTimestamp(data['deletedAt']);
  }

  @override
  toJson() {
    return {
      'id': id,
      'name': name,
      'dob': dob?.toIso8601String(),
      'expectedDueDate': expectedDueDate?.toIso8601String(),
      'term': term,
      'weight': weight,
      'healthConditions': healthConditions,
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

DateTime? parseTimestamp(Map<String, dynamic>? timestamp) {
  if (timestamp == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(
    timestamp['_seconds'] * 1000 + (timestamp['_nanoseconds'] ~/ 1000000),
    isUtc: true,
  ).toLocal(); // Or add .add(Duration(hours: 8)) if needed for SGT
}
