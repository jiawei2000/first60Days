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

  JournalEntry() : super(key: key);

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
        "feedTypes": feedTypes?.map((item) => item.toJson()).toList(),
        "awakeTime": startWakeTime,
        "startFeedTime": startFeedTime,
        "startPlayTime": startPlayTime,
        "startSleepTime": startSleepTime,
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
