import 'dart:collection';

/// Result of installing or reusing the opt-in POS template.
final class PosActivationResult {
  PosActivationResult({
    required this.templateKey,
    required this.templateVersion,
    required this.warehouseId,
    required Map<String, String> accountIdsByKey,
    required this.alreadyInstalled,
  }) : accountIdsByKey = UnmodifiableMapView(accountIdsByKey);

  final String templateKey;
  final int templateVersion;
  final String warehouseId;
  final Map<String, String> accountIdsByKey;
  final bool alreadyInstalled;
}
