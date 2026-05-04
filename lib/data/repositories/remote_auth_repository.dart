import 'package:qayd/core/constants/api_endpoints.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/data/network/api_client.dart';
import 'package:qayd/core/utils/text_sanitizer.dart';
import 'package:qayd/domain/repositories/auth_repository.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// HTTP implementation of [AuthRepository] using the Dio-based [ApiClient].
///
/// All endpoint paths come from [ApiEndpoints] — never hard-coded strings here.
/// All errors surface as [AuthException] via [ApiClient]'s error interceptor.
final class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  // ── AuthRepository ────────────────────────────────────────────────────────

  @override
  Future<({String jwt, Map<String, dynamic> licenseData, String serverSalt})>
      login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    try {
      final data = await _client.post(
        ApiEndpoints.authLogin,
        body: {'email': email, 'password': password, 'device_id': deviceId},
      );
      return _parseProvisioningResponse(data);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_unknownError(e));
    }
  }

  @override
  Future<({String jwt, Map<String, dynamic> licenseData, String serverSalt})>
      register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String deviceId,
  }) async {
    try {
      final data = await _client.post(
        ApiEndpoints.authRegister,
        body: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': password,
          'device_id': deviceId,
        },
      );
      return _parseProvisioningResponse(data);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_unknownError(e));
    }
  }

  @override
  Future<bool> requestPasswordReset({required String email}) async {
    try {
      await _client.post(
        ApiEndpoints.passwordEmail,
        body: {'email': email},
      );
      return true;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_unknownError(e));
    }
  }

  @override
  Future<bool> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _client.post(
        ApiEndpoints.passwordReset,
        body: {
          'email': email,
          'token': token,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );
      return true;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_unknownError(e));
    }
  }

  @override
  Future<int> sendVerificationEmail() async {
    try {
      final data = await _client.post(ApiEndpoints.verificationSend);
      return (data['next_retry_delay'] as num?)?.toInt() ?? 60;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_unknownError(e));
    }
  }

  @override
  Future<bool> verifyEmailOtp(String code) async {
    try {
      await _client.post(
        ApiEndpoints.verificationVerifyOtp,
        body: {'code': code},
      );
      return true;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_unknownError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> refreshLicense() async {
    try {
      final data = await _client.get(ApiEndpoints.licenseRefresh);
      return data;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_unknownError(e));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  ({String jwt, Map<String, dynamic> licenseData, String serverSalt})
      _parseProvisioningResponse(Map<String, dynamic> data) {
    final token = data['token'] as String? ?? '';
    if (token.isEmpty) {
      throw  AuthException(AppStrings.invalidResponseNoAuthentication);
    }
    return (
      jwt: token,
      licenseData:
          (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      serverSalt: data['salt'] as String? ?? '',
    );
  }

  String _unknownError(Object e) {
    final sanitized = TextSanitizer.sanitizeErrorMessage(e);
    return 'خطأ غير متوقع: $sanitized';
  }
}
