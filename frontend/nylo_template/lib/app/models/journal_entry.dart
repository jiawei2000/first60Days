import 'package:nylo_framework/nylo_framework.dart';
import 'feed_type.dart';

class JournalEntry extends Model {
  String? id;
  String? remarks;
  List<FeedType>? feedTypes;
  DateTime? startWakeTime;
  DateTime? startFeedTime;
  DateTime? startPlayTime;
  DateTime? startSleepTime;
  bool? hasStool;
  bool? hasUrine;

  static StorageKey key = 'journal_entry';

  JournalEntry(
      {String? this.id,
      String? this.remarks,
      DateTime? this.startWakeTime,
      DateTime? this.startFeedTime,
      DateTime? this.startPlayTime,
      DateTime? this.startSleepTime,
      List<FeedType>? this.feedTypes,
      bool? this.hasStool,
      bool? this.hasUrine})
      : super(key: key);

  JournalEntry.fromJson(dynamic data) {
    id = data['id'];
    remarks = data['remarks'];
    feedTypes = (data['feedType'] as List?)
        ?.map((item) => FeedType.fromJson(item))
        .toList();
    startWakeTime = parseTimestamp(data['awakeTime']);
    startFeedTime = parseTimestamp(data['startFeedTime']);
    startPlayTime = parseTimestamp(data['startPlayTime']);
    startSleepTime = parseTimestamp(data['startSleepTime']);
    hasStool = data['hasStool'];
    hasUrine = data['hasUrine'];
  }

  @override
  toJson() => {
        "id": id,
        "remarks": remarks,
        "feedType": feedTypes?.map((item) => item.toJson()).toList(),
        "awakeTime": startWakeTime?.toIso8601String(),
        "startFeedTime": startFeedTime?.toIso8601String(),
        "startPlayTime": startPlayTime?.toIso8601String(),
        "startSleepTime": startSleepTime?.toIso8601String(),
        "hasStool": hasStool,
        "hasUrine": hasUrine,
      };
}

DateTime? parseTimestamp(Map<String, dynamic>? timeStamp) {
  if (timeStamp == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(
    timeStamp['_seconds'] * 1000 + (timeStamp['_nanoseconds'] ~/ 1000000),
    isUtc: true,
  ).add(const Duration(hours: 8)); // shift to UTC+8
}
