import 'package:qayd/domain/repositories/identity_repository.dart';

/// Looks up a counterparty's public key by phone number for signature verification.
final class LookupPublicKeyUseCase {
  const LookupPublicKeyUseCase({
    required IdentityRepository identityRepository,
  }) : _identity = identityRepository;

  final IdentityRepository _identity;

  /// Returns the public key lookup result for a phone number.
  ///
  /// Returns `null` if the phone is not registered or has no public key.
  Future<PublicKeyLookupResult?> call({required String phone}) =>
      _identity.lookupByPhone(phone: phone);

  /// Batch lookup for multiple phone numbers.
  Future<Map<String, PublicKeyLookupResult>> batch({
    required List<String> phones,
  }) =>
      _identity.lookupBatch(phones: phones);
}
