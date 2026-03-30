import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Detects system clock rollback (anti-tamper).
///
/// On every write / app-close event, persist the UTC timestamp.
/// On app start, if now < last-known-good-time → clock tampered.
final class MonotonicClockGuard {
  MonotonicClockGuard({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kLastGoodTime = 'qayd_last_good_utc_epoch_v1';

  /// Returns true if the system clock appears to have been rolled back.
  Future<bool> detectTamper() async {
    final raw = await _storage.read(key: _kLastGoodTime);
    if (raw == null) {
      await _stampNow();
      return false;
    }
    final lastEpoch = int.tryParse(raw);
    if (lastEpoch == null) {
      await _stampNow();
      return false;
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    // Allow up to 60 seconds of drift for legitimate NTP corrections.
    if (now < lastEpoch - 60000) {
      return true;
    }
    await _stampNow();
    return false;
  }

  /// Call this on every database write operation and on app pause.
  Future<void> stamp() => _stampNow();

  Future<void> _stampNow() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    await _storage.write(key: _kLastGoodTime, value: now);
  }

  Future<void> delete() => _storage.delete(key: _kLastGoodTime);
}
