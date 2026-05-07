import 'dart:convert';
import 'dart:math';

class DevicePairingQrData {
  const DevicePairingQrData({
    required this.deviceId,
    required this.publicKeyHex,
    required this.pairingChallenge,
    this.deviceName,
  });

  final String deviceId;
  final String publicKeyHex;
  final String pairingChallenge;
  final String? deviceName;
}

class DevicePairingQrService {
  const DevicePairingQrService();

  String generateQr({
    required String deviceId,
    required String publicKeyHex,
    required String deviceName,
  }) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final challenge = base64UrlEncode(bytes);

    final payload = <String, dynamic>{
      'v': 1,
      'type': 'QAYD_DEVICE_PAIR',
      'device_id': deviceId,
      'public_key': publicKeyHex,
      'device_name': deviceName,
      'pairing_challenge': challenge,
      'ts': DateTime.now().toIso8601String(),
    };
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  DevicePairingQrData? parseQr(String raw) {
    try {
      final decoded = utf8.decode(base64Decode(raw));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      if (map['type'] != 'QAYD_DEVICE_PAIR') return null;
      final deviceId = map['device_id'] as String?;
      final publicKey = map['public_key'] as String?;
      final challenge = map['pairing_challenge'] as String?;
      if (deviceId == null || publicKey == null || challenge == null) {
        return null;
      }
      return DevicePairingQrData(
        deviceId: deviceId,
        publicKeyHex: publicKey,
        pairingChallenge: challenge,
        deviceName: map['device_name'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
