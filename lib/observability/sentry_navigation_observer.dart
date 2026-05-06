import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final class SentryNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('push', route, previousRoute);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('pop', route, previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final to = _routeName(newRoute);
    final from = _routeName(oldRoute);
    Sentry.addBreadcrumb(Breadcrumb(
      category: 'navigation',
      type: 'navigation',
      level: SentryLevel.info,
      message: 'replace $from -> $to',
      data: <String, dynamic>{
        'action': 'replace',
        'from': from,
        'to': to,
      },
    ));
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _record(
    String action,
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    final to = _routeName(route);
    final from = _routeName(previousRoute);
    Sentry.addBreadcrumb(Breadcrumb(
      category: 'navigation',
      type: 'navigation',
      level: SentryLevel.info,
      message: '$action $from -> $to',
      data: <String, dynamic>{
        'action': action,
        'from': from,
        'to': to,
      },
    ));
  }

  String _routeName(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    if (route != null) {
      return route.runtimeType.toString();
    }
    return 'unknown';
  }
}
