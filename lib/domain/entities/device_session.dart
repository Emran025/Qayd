class DeviceSession {
  const DeviceSession({
    required this.deviceId,
    this.deviceName,
    required this.publicKeyHex,
    required this.pairedAt,
    required this.lastSyncSeq,
    this.lastSeenAt,
    this.isCurrent = false,
    this.isActive = true,
  });

  final String deviceId;
  final String? deviceName;
  final String publicKeyHex;
  final DateTime pairedAt;
  final int lastSyncSeq;
  final DateTime? lastSeenAt;
  final bool isCurrent;
  final bool isActive;

  Map<String, Object?> toMap() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'public_key_hex': publicKeyHex,
      'paired_at': pairedAt.toUtc().toIso8601String(),
      'last_sync_seq': lastSyncSeq,
      'last_seen_at': lastSeenAt?.toUtc().toIso8601String(),
      'is_current': isCurrent ? 1 : 0,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory DeviceSession.fromMap(Map<String, Object?> map) {
    return DeviceSession(
      deviceId: map['device_id'] as String,
      deviceName: map['device_name'] as String?,
      publicKeyHex: map['public_key_hex'] as String,
      pairedAt: DateTime.parse(map['paired_at'] as String).toLocal(),
      lastSyncSeq: (map['last_sync_seq'] as int?) ?? 0,
      lastSeenAt: map['last_seen_at'] != null
          ? DateTime.parse(map['last_seen_at'] as String).toLocal()
          : null,
      isCurrent: (map['is_current'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
