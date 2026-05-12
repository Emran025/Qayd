import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'sentry_navigation_observer.dart';

abstract final class AppObservability {
  static const String _dsn = String.fromEnvironment('SENTRY_DSN');
  static const String _environment =
      String.fromEnvironment('SENTRY_ENV', defaultValue: 'production');
  static const String _release = String.fromEnvironment('SENTRY_RELEASE');
  static const String _dist = String.fromEnvironment('SENTRY_DIST');
  static const bool _enabled = bool.fromEnvironment(
    'SENTRY_ENABLED',
    defaultValue: false,
  );

  static final NavigatorObserver navigatorObserver = SentryNavigationObserver();

  static Future<void> bootstrap(FutureOr<void> Function() appRunner) async {
    if (!_enabled || _dsn.isEmpty) {
      _installFlutterErrorWidgetFallback();
      await runZonedGuarded(appRunner, _fallbackZoneErrorHandler);
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.environment = _environment;
        if (_release.isNotEmpty) {
          options.release = _release;
        }
        if (_dist.isNotEmpty) {
          options.dist = _dist;
        }
        options.sendDefaultPii = false;
        options.maxBreadcrumbs = 150;
      },
      appRunner: () async {
        _installFlutterErrorWidgetFallback();
        await runZonedGuarded(appRunner, _captureZoneError);
      },
    );
  }

  static void setUserContext({
    required String id,
    String? tenantId,
  }) {
    if (!_enabled || _dsn.isEmpty) return;
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: id));
      if (tenantId != null && tenantId.isNotEmpty) {
        scope.setTag('tenant_id', tenantId);
      }
    });
  }

  static void clearUserContext() {
    if (!_enabled || _dsn.isEmpty) return;
    Sentry.configureScope((scope) {
      scope.setUser(null);
      scope.removeTag('tenant_id');
    });
  }

  static Future<void> captureHandledError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    SentryLevel level = SentryLevel.warning,
    Map<String, String> tags = const <String, String>{},
  }) async {
    if (!_enabled || _dsn.isEmpty) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.level = level;
        if (context != null && context.isNotEmpty) {
          scope.setTag('error_context', context);
        }
        for (final entry in tags.entries) {
          scope.setTag(entry.key, entry.value);
        }
      },
    );
  }

  static Future<void> addBreadcrumb({
    required String message,
    String category = 'app',
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) async {
    if (!_enabled || _dsn.isEmpty) return;
    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
      ),
    );
  }

  static void _installFlutterErrorWidgetFallback() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      FlutterError.reportError(details);
      return _FriendlyErrorFallback(errorDetails: details);
    };
  }

  static void _fallbackZoneErrorHandler(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
  }

  static void _captureZoneError(Object error, StackTrace stackTrace) {
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}

class _FriendlyErrorFallback extends StatelessWidget {
  const _FriendlyErrorFallback({this.errorDetails});

  final FlutterErrorDetails? errorDetails;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (kDebugMode && errorDetails != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorDetails!.exceptionAsString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontFamily: 'monospace',
                        ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
