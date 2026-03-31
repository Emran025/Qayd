import 'package:qayd/core/constants/api_endpoints.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/data/network/api_client.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';

/// HTTP implementation of [IdentityRepository] using the Dio-based [ApiClient].
final class RemoteIdentityRepository implements IdentityRepository {
  RemoteIdentityRepository({required ApiClient apiClient})
      : _client = apiClient;

  final ApiClient _client;

  @override
  Future<int> registerPublicKey({required String publicKeyHex}) async {
    try {
      final data = await _client.post(
        ApiEndpoints.identityRegisterKey,
        body: {'public_key': publicKeyHex},
      );
      return (data['key_generation'] as int?) ?? 1;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('خطأ في تسجيل المفتاح العام: ${e.toString().split('\n').first}');
    }
  }

  @override
  Future<PublicKeyLookupResult?> lookupByPhone({required String phone}) async {
    try {
      final data = await _client.get(
        ApiEndpoints.identityLookup,
        queryParameters: {'phone': phone},
      );
      if (data['public_key'] == null) return null;
      return PublicKeyLookupResult(
        phone: data['phone'] as String? ?? phone,
        publicKeyHex: data['public_key'] as String,
        keyGeneration: (data['key_generation'] as int?) ?? 1,
        name: data['name'] as String? ?? '',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      // Lookup failures are non-fatal — return null for offline/missing cases.
      return null;
    }
  }

  @override
  Future<Map<String, PublicKeyLookupResult>> lookupBatch({
    required List<String> phones,
  }) async {
    try {
      final data = await _client.post(
        ApiEndpoints.identityLookupBatch,
        body: {'phones': phones},
      );
      final results = <String, PublicKeyLookupResult>{};
      final entries = data['results'] as List<dynamic>? ?? [];
      for (final entry in entries) {
        final map = entry as Map<String, dynamic>;
        final phone = map['phone'] as String;
        if (map['public_key'] != null) {
          results[phone] = PublicKeyLookupResult(
            phone: phone,
            publicKeyHex: map['public_key'] as String,
            keyGeneration: (map['key_generation'] as int?) ?? 1,
            name: map['name'] as String? ?? '',
          );
        }
      }
      return results;
    } catch (_) {
      return {};
    }
  }
}
