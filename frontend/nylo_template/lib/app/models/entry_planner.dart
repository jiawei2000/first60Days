import 'package:nylo_framework/nylo_framework.dart';

class EntryPlanner {
  String? id;
  int? totalFeeds;
  DateTime? firstFeedTime;
  DateTime? lastFeedTime;
  int? mONInterval;
  List<String>? feedTimings;
  int? weekNo;
  DateTime? createdAt;

  static StorageKey key = 'entry_planner';

  EntryPlanner({
    this.id,
    this.totalFeeds,
    this.firstFeedTime,
    this.lastFeedTime,
    this.mONInterval,
    this.feedTimings,
    this.weekNo,
    this.createdAt,
  });

  EntryPlanner.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    totalFeeds = json['totalFeeds'];
    firstFeedTime = parseTimestamp(json['firstFeedTime']);
    lastFeedTime = parseTimestamp(json['lastFeedTime']);
    mONInterval = json['MONInterval'];
    if (json['feedTimings'] != null) {
      feedTimings = (json['feedTimings'] as List)
          .map<String>((e) => e.toString())
          .toList();
    }
    weekNo = json['weekNo'];
    createdAt = parseTimestamp(json['createdAt']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalFeeds': totalFeeds,
      'firstFeedTime': firstFeedTime?.toIso8601String(),
      'lastFeedTime': lastFeedTime?.toIso8601String(),
      'MONInterval': mONInterval,
      'feedTimings': feedTimings,
      'weekNo': weekNo,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

DateTime? parseTimestamp(Map<String, dynamic>? timeStamp) {
  if (timeStamp == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(
    timeStamp['_seconds'] * 1000 + (timeStamp['_nanoseconds'] ~/ 1000000),
    isUtc: true,
  ).add(const Duration(hours: 8)); // shift to UTC+8
}
