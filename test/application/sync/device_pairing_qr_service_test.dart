import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/application/sync/device_pairing_qr_service.dart';

void main() {
  group('DevicePairingQrService', () {
    const service = DevicePairingQrService();

    test('parses legacy pairing QR', () {
      final qr = service.generateQr(
        deviceId: 'device-a',
        publicKeyHex: 'abc123',
        deviceName: 'A',
      );
      final parsed = service.parseQr(qr);
      expect(parsed, isNotNull);
      expect(parsed!.deviceId, 'device-a');
      expect(parsed.publicKeyHex, 'abc123');
      expect(parsed.pairingChallenge.isNotEmpty, isTrue);
    });

    test('parses companion link QR', () {
      final qr = service.generateCompanionLinkQr(
        ephemeralPublicKeyHex: 'ephemeral-key',
        socketSessionId: 'session-1',
      );
      final parsed = service.parseCompanionLinkQr(qr);
      expect(parsed, isNotNull);
      expect(parsed!.ephemeralPublicKeyHex, 'ephemeral-key');
      expect(parsed.socketSessionId, 'session-1');
      expect(parsed.nonce.isNotEmpty, isTrue);
    });
  });
}
