class FeedType {
  final String? type;
  final int? value;
  final String? unit;

  FeedType({this.type, this.value, this.unit});

  Map<String, dynamic> toJson() => {'type': type, 'value': value, 'unit': unit};

  factory FeedType.fromJson(Map<String, dynamic> json) => FeedType(
    type: json['type'] as String?,
    value: json['value'] as int?,
    unit: json['unit'] as String?,
  );
}
