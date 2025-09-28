import 'package:nylo_framework/nylo_framework.dart';

class FeedType extends Model {
  String? type;
  int? value;
  String? unit;

  static StorageKey key = 'feed_type';

  FeedType() : super(key: key);

  FeedType.fromJson(dynamic data) {
    type = data['type'];
    value = data['value'];
    unit = data['unit'];
  }

  @override
  toJson() => {"type": type, "value": value, "unit": unit};
}
