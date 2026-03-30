/// Domain contract for API authentication.
abstract interface class AuthRepository {
  /// Authenticates with the governance API.
  ///
  /// Returns a record of [jwt] and [licenseData] on success.
  /// Throws on network or authentication failure.
  Future<({String jwt, Map<String, dynamic> licenseData, String serverSalt})>
      login({
    required String email,
    required String password,
  });
}
