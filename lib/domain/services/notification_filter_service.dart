import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service to check whether a notification should be delivered
/// based on user preferences. Used by both the native notification layer
/// and the inbox persistence layer to ensure consistent filtering.
class NotificationFilterService {
  final SharedPreferences _prefs;

  const NotificationFilterService(this._prefs);

  static const _kPeerActivity = 'notif_peer_activity';
  static const _kSelfActivity = 'notif_self_activity';

  /// Whether incoming peer notifications (claims, transfers, requests) are allowed.
  bool get isPeerActivityEnabled => _prefs.getBool(_kPeerActivity) ?? true;

  /// Whether self-initiated operation notifications are allowed.
  bool get isSelfActivityEnabled => _prefs.getBool(_kSelfActivity) ?? true;
}
