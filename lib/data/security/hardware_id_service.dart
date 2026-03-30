import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Produces a stable, non-volatile hardware-bound identifier for the device.
///
/// Used as the anchor for key derivation and license binding.
final class HardwareIdService {
  HardwareIdService({DeviceInfoPlugin? plugin})
      : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  static const String _fallbackId = 'qayd_unsupported_platform_v1';

  /// Returns a stable hardware identifier for the current platform.
  /// Falls back to a platform-constant string on unsupported targets.
  Future<String> obtainHardwareId() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _plugin.androidInfo;
        final androidId = info.id;
        if (androidId.isNotEmpty) return 'android:$androidId';
        return 'android:${info.fingerprint}';
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _plugin.iosInfo;
        final identifier = info.identifierForVendor ?? '';
        return 'ios:$identifier';
      }

      if (defaultTargetPlatform == TargetPlatform.windows) {
        final info = await _plugin.windowsInfo;
        final deviceId = info.deviceId;
        return 'windows:$deviceId';
      }

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final info = await _plugin.macOsInfo;
        return 'macos:${info.systemGUID ?? info.hostName}';
      }

      if (defaultTargetPlatform == TargetPlatform.linux) {
        final info = await _plugin.linuxInfo;
        return 'linux:${info.machineId ?? info.id}';
      }
    } catch (_) {
      // Defensive: never crash on ID retrieval
    }
    return _fallbackId;
  }
}
