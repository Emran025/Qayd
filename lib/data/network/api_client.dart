import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qayd/core/error/exceptions.dart';

/// Dio-based HTTP client for all qaydAPI v1 requests.
///
/// Provides:
///   - Base URL and JSON headers pre-configured.
///   - [AuthInterceptor] to attach the stored JWT automatically.
///   - [_ErrorInterceptor] to normalize Dio/HTTP errors into [AuthException].
///   - Timeout configuration (connect: 10s, receive: 30s).
///
/// Usage:
/// ```dart
/// final client = ApiClient(baseUrl: 'https://api.qayd.app');
/// final data = await client.post('api/v1/auth/login', body: {...});
/// ```
final class ApiClient {
  ApiClient({
    required String baseUrl,
    Future<String?> Function()? tokenProvider,
    Dio? dio,
  }) : _dio = dio ?? _buildDio(baseUrl) {
    if (tokenProvider != null) {
      _dio.interceptors.add(AuthInterceptor(tokenProvider));
    }
    _dio.interceptors.add(_ErrorInterceptor());
  }

  final Dio _dio;

  static Dio _buildDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.trimRight().replaceAll(RegExp(r'/$'), ''),
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Accept-Language': 'ar',
        },
        responseType: ResponseType.json,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }

    return dio;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Performs a POST request to [path] with optional [body].
  ///
  /// Returns the parsed `data` field from the standard API envelope.
  /// Throws [AuthException] on 4xx/5xx or network errors.
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Options? options,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: body,
      options: options,
    );
    return _extractData(response);
  }

  /// Performs a multipart/form-data POST request for file uploads.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, dynamic> body,
    Options? options,
  }) async {
    final formData = FormData.fromMap(body);
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: formData,
      options: (options ?? Options()).copyWith(
        contentType: 'multipart/form-data',
      ),
    );
    return _extractData(response);
  }

  /// Performs a GET request to [path].
  ///
  /// Returns the parsed `data` field from the standard API envelope.
  /// Throws [AuthException] on 4xx/5xx or network errors.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    return _extractData(response);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  dynamic _extractData(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) return {};
    return body['data'] ?? body;
  }
}

// ── Auth interceptor ─────────────────────────────────────────────────────────

/// Attaches the JWT bearer token to every request when available.
final class AuthInterceptor extends Interceptor {
  const AuthInterceptor(this._tokenProvider);

  final Future<String?> Function() _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ── Error interceptor ────────────────────────────────────────────────────────

/// Converts Dio errors into structured [AuthException] with Arabic messages.
final class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final arabicMessage = _resolveArabicMessage(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: AuthException(arabicMessage),
        type: err.type,
        response: err.response,
        message: arabicMessage,
      ),
    );
  }

  String _resolveArabicMessage(DioException err) {
    // Server responded with a 4xx/5xx and a message field.
    final serverMessage =
        err.response?.data?['message'] as String?;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.';
    }

    if (err.type == DioExceptionType.connectionError) {
      return 'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.';
    }

    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      switch (statusCode) {
        case 401:
          return 'بيانات الدخول غير صحيحة.';
        case 403:
          return 'الحساب موقوف أو انتهت فترته التجريبية. تواصل مع المسؤول.';
        case 409:
          return 'البريد الإلكتروني مسجّل مسبقاً.';
        case 422:
          return 'بيانات غير صالحة. تحقق من المدخلات وأعد المحاولة.';
        case >= 500:
          return 'خطأ في الخادم. يرجى المحاولة لاحقاً.';
      }
    }

    return serverMessage ?? 'خطأ غير متوقع. حاول مرة أخرى.';
  }
}

/// Extension to extract [AuthException] from [DioException.error].
extension DioExceptionX on DioException {
  /// Returns the wrapped [AuthException] if present, or builds one from message.
  AuthException toAuthException() {
    final err = error;
    if (err is AuthException) return err;
    return AuthException(message ?? 'خطأ غير متوقع. حاول مرة أخرى.');
  }
}
