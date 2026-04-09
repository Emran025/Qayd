/// Formats minor units as a decimal string for amount fields (e.g. "12.50").
String formatMinorAmountForField(int minorUnits, {int fractionalDigits = 2}) {
  num divisor = 1;
  for (var i = 0; i < fractionalDigits; i++) {
    divisor *= 10;
  }
  return (minorUnits / divisor).toStringAsFixed(fractionalDigits);
}

/// Parses a decimal text field into positive minor units, or null if invalid.
int? parsePositiveMinorUnits(String raw, {int fractionalDigits = 2}) {
  final t = raw.trim().replaceAll(',', '.');
  if (t.isEmpty) {
    return null;
  }
  final v = double.tryParse(t);
  if (v == null || v <= 0) {
    return null;
  }
  num multiplier = 1;
  for (var i = 0; i < fractionalDigits; i++) {
    multiplier *= 10;
  }
  final minor = (v * multiplier).round();
  if (minor <= 0) {
    return null;
  }
  return minor;
}

/// Validates that minor units fit a pragmatic scale (no overflow for UI).
bool isReasonableMinorAmount(int minorUnits) {
  return minorUnits > 0 && minorUnits <= 999999999999; // pragmatic cap
}
