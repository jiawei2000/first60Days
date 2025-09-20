import 'feed_type.dart';

class JournalEntry {
  final String id;
  final int? cycleNo;
  final String? remarks;
  final List<FeedType>? feedType;
  final int? sleepDuration;
  final DateTime? startWakeTime;
  final DateTime? startFeedTime;
  final DateTime? startPlayTime;
  final DateTime? startSleepTime;
  final bool? hasStool;
  final bool? hasUrine;

  JournalEntry({
    required this.id,
    this.cycleNo,
    this.remarks,
    this.feedType,
    this.sleepDuration,
    this.startWakeTime,
    this.startFeedTime,
    this.startPlayTime,
    this.startSleepTime,
    this.hasStool,
    this.hasUrine,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    cycleNo: json['cycleNo'] as int,
    remarks: json['remarks'] as String,
    feedType: List<FeedType>.from(
      (json['feedType'] as List).map((item) => FeedType.fromJson(item)),
    ),
    sleepDuration: json['sleepDuration'] as int,
    startWakeTime: DateTime.fromMillisecondsSinceEpoch(
      json['awakeTime']['_seconds'] * 1000,
    ),
    startFeedTime: DateTime.fromMillisecondsSinceEpoch(
      json['startFeedTime']['_seconds'] * 1000,
    ),
    startPlayTime: DateTime.fromMillisecondsSinceEpoch(
      json['startPlayTime']['_seconds'] * 1000,
    ),
    startSleepTime: DateTime.fromMillisecondsSinceEpoch(
      json['startSleepTime']['_seconds'] * 1000,
    ),
    hasStool: json['stool'] as bool?,
    hasUrine: json['urine'] as bool?,
  );
}

JournalEntry toJson(Map<String, dynamic> json) => JournalEntry(
  id: json['id'] as String,
  cycleNo: json['cycleNo'] as int,
  remarks: json['remarks'] as String,
  feedType: List<FeedType>.from(
    (json['feedType'] as List).map((item) => FeedType.fromJson(item)),
  ),
  sleepDuration: json['sleepDuration'] as int,
  hasStool: json['stool'] as bool?,
  hasUrine: json['urine'] as bool?,
);
