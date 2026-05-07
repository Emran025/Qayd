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

class CompanionLinkQrData {
  const CompanionLinkQrData({
    required this.ephemeralPublicKeyHex,
    required this.socketSessionId,
    required this.nonce,
    required this.createdAtIso,
  });

  final String ephemeralPublicKeyHex;
  final String socketSessionId;
  final String nonce;
  final String createdAtIso;
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

  String generateCompanionLinkQr({
    required String ephemeralPublicKeyHex,
    required String socketSessionId,
  }) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final nonce = base64UrlEncode(bytes);
    final payload = <String, dynamic>{
      'v': 1,
      'type': 'QAYD_COMPANION_LINK',
      'ephemeral_public_key': ephemeralPublicKeyHex,
      'socket_session_id': socketSessionId,
      'nonce': nonce,
      'ts': DateTime.now().toUtc().toIso8601String(),
    };
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  CompanionLinkQrData? parseCompanionLinkQr(String raw) {
    try {
      final decoded = utf8.decode(base64Decode(raw));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      if (map['type'] != 'QAYD_COMPANION_LINK') return null;
      final ephemeral = map['ephemeral_public_key'] as String?;
      final session = map['socket_session_id'] as String?;
      final nonce = map['nonce'] as String?;
      final ts = map['ts'] as String?;
      if (ephemeral == null || session == null || nonce == null || ts == null) {
        return null;
      }
      return CompanionLinkQrData(
        ephemeralPublicKeyHex: ephemeral,
        socketSessionId: session,
        nonce: nonce,
        createdAtIso: ts,
      );
    } catch (_) {
      return null;
    }
  }
}
