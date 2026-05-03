import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceSettingsState {
  final ThemeMode themeMode;
  final String languageCode;

  const AppearanceSettingsState({
    this.themeMode = ThemeMode.system,
    this.languageCode = 'ar',
  });

  AppearanceSettingsState copyWith({
    ThemeMode? themeMode,
    String? languageCode,
  }) {
    return AppearanceSettingsState(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class AppearanceSettingsCubit extends Cubit<AppearanceSettingsState> {
  final SharedPreferences _prefs;
  
  static const _themeKey = 'pref_theme_mode';
  static const _langKey = 'pref_language_code';

  AppearanceSettingsCubit(this._prefs) : super(const AppearanceSettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final themeStr = _prefs.getString(_themeKey);
    final langStr = _prefs.getString(_langKey);

    ThemeMode mode = ThemeMode.system;
    if (themeStr == 'light') mode = ThemeMode.light;
    if (themeStr == 'dark') mode = ThemeMode.dark;

    emit(state.copyWith(
      themeMode: mode,
      languageCode: langStr ?? 'ar',
    ));
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    
    await _prefs.setString(_themeKey, val);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> updateLanguage(String code) async {
    await _prefs.setString(_langKey, code);
    emit(state.copyWith(languageCode: code));
  }
}
