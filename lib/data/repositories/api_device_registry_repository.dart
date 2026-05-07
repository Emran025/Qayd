import 'package:qayd/core/constants/api_endpoints.dart';
import 'package:qayd/data/network/api_client.dart';
import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/domain/repositories/device_registry_repository.dart';

class ApiDeviceRegistryRepository implements DeviceRegistryRepository {
  const ApiDeviceRegistryRepository({
    required ApiClient apiClient,
    required String currentDeviceId,
  })  : _apiClient = apiClient,
        _currentDeviceId = currentDeviceId;

  final ApiClient _apiClient;
  final String _currentDeviceId;

  @override
  Future<DeviceSession> pairDevice({
    required String deviceId,
    required String deviceName,
    required String publicKeyHex,
    required String signedChallenge,
  }) async {
    final data = await _apiClient.post(
      ApiEndpoints.devicesPair,
      body: {
        'device_id': deviceId,
        'device_name': deviceName,
        'public_key': publicKeyHex,
        'signed_challenge': signedChallenge,
      },
    ) as Map<String, dynamic>;
    return _mapSession(data);
  }

  @override
  Future<List<DeviceSession>> listDevices() async {
    final data = await _apiClient.get(ApiEndpoints.devicesList);
    if (data is! List) return <DeviceSession>[];
    return data
        .whereType<Map>()
        .map((e) => _mapSession(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> revokeDevice(String deviceId) async {
    await _apiClient.post(ApiEndpoints.deviceRevoke(deviceId));
  }

  DeviceSession _mapSession(Map<String, dynamic> raw) {
    final deviceId = raw['device_id'] as String? ?? '';
    return DeviceSession(
      deviceId: deviceId,
      deviceName: raw['device_name'] as String?,
      publicKeyHex: raw['public_key'] as String? ?? '',
      pairedAt: DateTime.tryParse(raw['paired_at'] as String? ?? '') ??
          DateTime.now(),
      lastSyncSeq: 0,
      lastSeenAt: raw['last_seen_at'] != null
          ? DateTime.tryParse(raw['last_seen_at'] as String)
          : null,
      isCurrent: deviceId == _currentDeviceId,
      isActive: (raw['is_active'] as bool?) ?? true,
    );
  }
}
