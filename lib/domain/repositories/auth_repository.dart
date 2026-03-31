/// Domain contract for API authentication and account management.
abstract interface class AuthRepository {
  /// Authenticates an existing user against the governance API.
  ///
  /// Returns a record of [jwt], [licenseData], and [serverSalt] on success.
  /// Throws [AuthException] on network or authentication failure.
  Future<({String jwt, Map<String, dynamic> licenseData, String serverSalt})>
      login({
    required String email,
    required String password,
    required String deviceId,
  });

  /// Provisions a new user account (admin-only; not publicly self-registered).
  ///
  /// [deviceId] must be the hardware-bound identifier from [HardwareIdService].
  /// Returns the same record as [login] on success.
  /// Throws [AuthException] on failure.
  Future<({String jwt, Map<String, dynamic> licenseData, String serverSalt})>
      register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String deviceId,
  });

  /// Sends a password-reset link or OTP to the given [email].
  ///
  /// Returns `true` if the server accepted the request.
  /// Throws [AuthException] on network failure.
  Future<bool> requestPasswordReset({required String email});

  /// Verifies a reset [token] and sets a [newPassword] for [email].
  ///
  /// Returns `true` on success.
  /// Throws [AuthException] on invalid token or network failure.
  Future<bool> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  });
}
