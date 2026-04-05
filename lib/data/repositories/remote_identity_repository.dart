import 'package:dio/dio.dart';
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

      // Parse historical public keys for cross-vector verification.
      final previousKeysRaw =
          data['previous_public_keys'] as List<dynamic>? ?? [];
      final previousKeys =
          previousKeysRaw.map((e) => e as String).toList();

      return PublicKeyLookupResult(
        phone: data['phone'] as String? ?? phone,
        publicKeyHex: data['public_key'] as String,
        previousPublicKeysHex: previousKeys,
        keyGeneration: (data['key_generation'] as int?) ?? 1,
        name: data['name'] as String? ?? '',
        email: data['email'] as String?,
        whatsappNumber: data['whatsapp_number'] as String?,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      // Lookup failures are non-fatal — return null for offline/missing cases.
      return null;
    }
  }

  @override
  Future<PublicKeyLookupResult?> lookupByEmail({required String email}) async {
    try {
      final data = await _client.get(
        ApiEndpoints.identityLookup,
        queryParameters: {'email': email},
      );
      if (data['public_key'] == null) return null;

      // Parse historical public keys for cross-vector verification.
      final previousKeysRaw =
          data['previous_public_keys'] as List<dynamic>? ?? [];
      final previousKeys =
          previousKeysRaw.map((e) => e as String).toList();

      return PublicKeyLookupResult(
        phone: data['phone'] as String? ?? '',
        publicKeyHex: data['public_key'] as String,
        previousPublicKeysHex: previousKeys,
        keyGeneration: (data['key_generation'] as int?) ?? 1,
        name: data['name'] as String? ?? '',
        email: data['email'] as String?,
        whatsappNumber: data['whatsapp_number'] as String?,
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
          final previousKeysRaw =
              map['previous_public_keys'] as List<dynamic>? ?? [];
          final previousKeys =
              previousKeysRaw.map((e) => e as String).toList();
          results[phone] = PublicKeyLookupResult(
            phone: phone,
            publicKeyHex: map['public_key'] as String,
            previousPublicKeysHex: previousKeys,
            keyGeneration: (map['key_generation'] as int?) ?? 1,
            name: map['name'] as String? ?? '',
            email: map['email'] as String?,
            whatsappNumber: map['whatsapp_number'] as String?,
          );
        }
      }
      return results;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<PublicKeyLookupResult?> reverseLookupByPublicKey({
    required String publicKeyHex,
  }) async {
    try {
      final data = await _client.get(
        ApiEndpoints.identityReverseLookup,
        queryParameters: {'public_key': publicKeyHex},
      );
      final owner = data['owner'] as Map<String, dynamic>?;
      if (owner == null) return null;

      final previousKeysRaw =
          owner['previous_public_keys'] as List<dynamic>? ?? [];
      final previousKeys =
          previousKeysRaw.map((e) => e as String).toList();

      return PublicKeyLookupResult(
        phone: owner['phone'] as String? ?? '',
        publicKeyHex: owner['current_public_key'] as String? ?? publicKeyHex,
        previousPublicKeysHex: previousKeys,
        keyGeneration: (owner['key_generation'] as int?) ?? 1,
        name: owner['name'] as String? ?? '',
        email: owner['email'] as String?,
        whatsappNumber: owner['whatsapp_number'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? whatsappNumber,
    String? avatarPath,
    String? logoPath,
  }) async {
    try {
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
        if (avatarPath != null)
          'avatar': await MultipartFile.fromFile(avatarPath),
        if (logoPath != null)
          'logo': await MultipartFile.fromFile(logoPath),
      };

      final data = await _client.postMultipart(
        ApiEndpoints.authProfileUpdate,
        body: body,
      );

      return data['user'] as Map<String, dynamic>;
    } catch (e) {
      throw AuthException(
          'خطأ في تحديث البيانات: ${e.toString().split('\n').first}');
    }
  }
}
