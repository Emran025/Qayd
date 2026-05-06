import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final class SentryDioObserver extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        type: 'http',
        level: SentryLevel.info,
        message: '${options.method} ${options.path}',
        data: <String, dynamic>{
          'method': options.method,
          'path': options.path,
        },
      ),
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final request = response.requestOptions;
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        type: 'http',
        level: SentryLevel.info,
        message: '${request.method} ${request.path} [${response.statusCode}]',
        data: <String, dynamic>{
          'method': request.method,
          'path': request.path,
          'status_code': response.statusCode,
        },
      ),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        type: 'http',
        level: SentryLevel.warning,
        message: '${request.method} ${request.path} failed',
        data: <String, dynamic>{
          'method': request.method,
          'path': request.path,
          'status_code': err.response?.statusCode,
          'error_type': err.type.name,
        },
      ),
    );
    handler.next(err);
  }
}
