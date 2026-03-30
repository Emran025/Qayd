import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/domain/repositories/auth_repository.dart';

/// HTTP implementation of [AuthRepository].
///
/// Connects to `qaydAPI/v1/auth/login`.
final class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required String baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl.trimRight().replaceAll(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<({String jwt, Map<String, dynamic> licenseData, String serverSalt})>
      login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/auth/login');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 401) {
      throw const AuthException('بيانات الدخول غير صحيحة.');
    }
    if (response.statusCode != 200) {
      throw AuthException(
          'خطأ في الخادم (${response.statusCode}). حاول مرة أخرى.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'] as String? ?? '';
    final licenseData =
        (body['license'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final serverSalt = body['salt'] as String? ?? '';

    if (token.isEmpty) {
      throw const AuthException('الرد غير صالح: لا يوجد رمز مصادقة.');
    }

    return (jwt: token, licenseData: licenseData, serverSalt: serverSalt);
  }
}
