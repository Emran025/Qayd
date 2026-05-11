import 'package:flutter/foundation.dart';
import 'package:qayd/core/constants/api_endpoints.dart';
import 'package:qayd/data/network/api_client.dart';

/// Represents the result of requesting a short pairing code from the server.
class ManualLinkCodeResult {
  const ManualLinkCodeResult({
    required this.shortCode,
    required this.expiresAt,
  });

  final String shortCode;
  final DateTime expiresAt;

  /// Display version: "A7B9-X2K4" (formatted with dash in the middle)
  String get displayCode =>
      '${shortCode.substring(0, 4)}-${shortCode.substring(4)}';
}

/// Represents the companion data returned once the Companion enters the code.
class CompanionPairingData {
  const CompanionPairingData({
    required this.companionSessionId,
    required this.companionEphemeralKey,
    required this.companionNonce,
  });

  final String companionSessionId;
  final String companionEphemeralKey;
  final String companionNonce;
}

/// Service for the WhatsApp-style manual device pairing flow.
///
/// Role inversion compared to QR flow:
/// - [generateShortCode]: called by PRIMARY to get a display code.
/// - [submitCompanionData]: called by COMPANION to register their keys using the code.
/// - [pollForCompanionData]: called by PRIMARY polling until COMPANION submits.
class ManualLinkService {
  ManualLinkService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// PRIMARY DEVICE: Request a new 8-character pairing code from the server.
  ///
  /// The server invalidates any previous unused code for this user before
  /// creating a new one.
  Future<ManualLinkCodeResult> generateShortCode() async {
    final res = await _apiClient.post(
      ApiEndpoints.devicesCompanionGenerateCode,
      body: {},
    ) as Map<String, dynamic>?;

    if (res == null) throw StateError('Server returned null for generateLinkCode.');

    final data = res.containsKey('data') ? (res['data'] as Map<String, dynamic>) : res;
    final shortCode = data['short_code'] as String?;
    final expiresAtStr = data['expires_at'] as String?;

    if (shortCode == null || expiresAtStr == null) {
      throw StateError('Invalid response from generateLinkCode: $res');
    }

    return ManualLinkCodeResult(
      shortCode: shortCode,
      expiresAt: DateTime.parse(expiresAtStr).toLocal(),
    );
  }

  /// COMPANION DEVICE: Submit ephemeral key data using the code entered by the user.
  ///
  /// This is called WITHOUT authentication — the Companion hasn't logged in yet
  /// on this device (same pattern as the QR bootstrap flow).
  ///
  /// Returns true on success, false if code is invalid/expired.
  Future<bool> submitCompanionData({
    required String shortCode,
    required String companionSessionId,
    required String companionEphemeralKey,
    required String companionNonce,
  }) async {
    try {
      final res = await _apiClient.post(
        ApiEndpoints.devicesCompanionSubmitData,
        body: {
          'short_code': shortCode.toUpperCase().replaceAll('-', ''),
          'companion_session_id': companionSessionId,
          'companion_ephemeral_key': companionEphemeralKey,
          'companion_nonce': companionNonce,
        },
      ) as Map<String, dynamic>?;

      if (res == null) return false;
      final status = res['status'] as String?;
      return status == 'success';
    } catch (e) {
      debugPrint('ManualLinkService: ❌ submitCompanionData failed: $e');
      rethrow;
    }
  }

  /// PRIMARY DEVICE: Poll to check if Companion has submitted their data.
  ///
  /// Returns [CompanionPairingData] when the Companion has entered the code,
  /// or null if still waiting.
  Future<CompanionPairingData?> pollForCompanionData({
    required String shortCode,
  }) async {
    try {
      final res = await _apiClient.post(
        ApiEndpoints.devicesCompanionPollCode,
        body: {'short_code': shortCode.toUpperCase().replaceAll('-', '')},
      ) as Map<String, dynamic>?;

      if (res == null) return null;

      final data = res.containsKey('data') ? res['data'] : null;
      if (data == null) return null;

      final dataMap = data as Map<String, dynamic>;
      final sessionId = dataMap['companion_session_id'] as String?;
      final ephemeralKey = dataMap['companion_ephemeral_key'] as String?;
      final nonce = dataMap['companion_nonce'] as String?;

      if (sessionId == null || ephemeralKey == null || nonce == null) return null;

      return CompanionPairingData(
        companionSessionId: sessionId,
        companionEphemeralKey: ephemeralKey,
        companionNonce: nonce,
      );
    } catch (e) {
      debugPrint('ManualLinkService: ⚠️ pollForCompanionData error: $e');
      return null;
    }
  }
}
