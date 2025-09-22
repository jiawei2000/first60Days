import 'feed_type.dart';

class JournalEntry {
  final String? id;
  final int? cycleNo;
  final String? remarks;
  final List<FeedType>? feedTypes;
  final int? sleepDuration;
  final DateTime? startWakeTime;
  final DateTime? startFeedTime;
  final DateTime? startPlayTime;
  final DateTime? startSleepTime;
  final bool? hasStool;
  final bool? hasUrine;
  bool? isCompleted;

  JournalEntry({
    this.id,
    this.cycleNo,
    this.remarks,
    this.feedTypes,
    this.sleepDuration,
    this.startWakeTime,
    this.startFeedTime,
    this.startPlayTime,
    this.startSleepTime,
    this.hasStool,
    this.hasUrine,
    this.isCompleted,
  });

  // Map<String, dynamic> toJson() => {
  //   'id': id,
  //   'cycleNo': cycleNo,
  //   'remarks': remarks,
  //   'feedTypes': feedTypes?.map((item) => item.toJson()).toList(),
  //   'sleepDuration': sleepDuration,
  //   'awakeTime': startWakeTime?.toIso8601String(),
  //   'startFeedTime': startFeedTime?.toIso8601String(),
  //   'startPlayTime': startPlayTime?.toIso8601String(),
  //   'startSleepTime': startSleepTime?.toIso8601String(),
  //   'stool': hasStool,
  //   'urine': hasUrine,
  // };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    cycleNo: json['cycleNo'] as int?,
    remarks: json['remarks'] as String?,
    feedTypes: List<FeedType>.from(
      (json['feedType'] as List).map((item) => FeedType.fromJson(item)),
    ),
    sleepDuration: json['sleepDuration'] as int?,
    startWakeTime: parseTimestamp(json['awakeTime']),
    startFeedTime: parseTimestamp(json['startFeedTime']),
    startPlayTime: parseTimestamp(json['startPlayTime']),
    startSleepTime: parseTimestamp(json['startSleepTime']),
    hasStool: json['stool'] as bool?,
    hasUrine: json['urine'] as bool?,
  );
}

DateTime? parseTimestamp(Map<String, dynamic>? timeStamp) {
  if (timeStamp == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(
    timeStamp['_seconds'] * 1000 + (timeStamp['_nanoseconds'] ~/ 1000000),
    isUtc: true,
  ).add(const Duration(hours: 8)); // shift to UTC+8
}
