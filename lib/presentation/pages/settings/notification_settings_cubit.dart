import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsState {
  final bool peerActivity;
  final bool selfActivity;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationSettingsState({
    this.peerActivity = true,
    this.selfActivity = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  NotificationSettingsState copyWith({
    bool? peerActivity,
    bool? selfActivity,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettingsState(
      peerActivity: peerActivity ?? this.peerActivity,
      selfActivity: selfActivity ?? this.selfActivity,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final SharedPreferences _prefs;

  NotificationSettingsCubit(this._prefs) : super(const NotificationSettingsState()) {
    _load();
  }

  static const _kPeerActivity = 'notif_peer_activity';
  static const _kSelfActivity = 'notif_self_activity';
  static const _kSoundEnabled = 'notif_sound_enabled';
  static const _kVibrationEnabled = 'notif_vibration_enabled';

  void _load() {
    emit(state.copyWith(
      peerActivity: _prefs.getBool(_kPeerActivity) ?? true,
      selfActivity: _prefs.getBool(_kSelfActivity) ?? true,
      soundEnabled: _prefs.getBool(_kSoundEnabled) ?? true,
      vibrationEnabled: _prefs.getBool(_kVibrationEnabled) ?? true,
    ));
  }

  Future<void> togglePeerActivity(bool value) async {
    await _prefs.setBool(_kPeerActivity, value);
    emit(state.copyWith(peerActivity: value));
  }

  Future<void> toggleSelfActivity(bool value) async {
    await _prefs.setBool(_kSelfActivity, value);
    emit(state.copyWith(selfActivity: value));
  }

  Future<void> toggleSound(bool value) async {
    await _prefs.setBool(_kSoundEnabled, value);
    emit(state.copyWith(soundEnabled: value));
  }

  Future<void> toggleVibration(bool value) async {
    await _prefs.setBool(_kVibrationEnabled, value);
    emit(state.copyWith(vibrationEnabled: value));
  }
}
