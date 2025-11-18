double? parseSleepDuration(String input) {
  final value = input.trim();
  if (value.isEmpty) return null;
  return double.tryParse(value);
}

String formatSleepDuration(double? duration) {
  if (duration == null) return '';
  final stringValue = duration.toString();
  if (stringValue.contains('.')) {
    return stringValue.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return stringValue;
}
