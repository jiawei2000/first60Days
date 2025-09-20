class FeedType {
  final String type;
  final int? minutes;
  final int? ml;

  FeedType({required this.type, this.minutes, this.ml});

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (minutes != null) 'minutes': minutes,
      if (ml != null) 'ml': ml,
    };
  }

  factory FeedType.fromJson(Map<String, dynamic> json) {
    return FeedType(
      type: json['type'] as String,
      minutes: json['minutes'] as int?,
      ml: json['ml'] as int?,
    );
  }
}
