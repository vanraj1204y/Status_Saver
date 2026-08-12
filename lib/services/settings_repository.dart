import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user preferences. Loaded once at startup.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _keyTheme = 'theme_mode';
  static const _keyAutoSave = 'auto_save';
  static const _keyNotifications = 'save_confirmations';
  static const _keyAutoplay = 'video_autoplay';
  static const _keyMute = 'mute_by_default';
  static const _keyConfirmDelete = 'confirm_delete';

  static Future<SettingsRepository> load() async =>
      SettingsRepository(await SharedPreferences.getInstance());

  ThemeMode get themeMode => switch (_prefs.getString(_keyTheme)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_keyTheme, mode.name);

  bool get autoSave => _prefs.getBool(_keyAutoSave) ?? false;
  Future<void> setAutoSave(bool value) => _prefs.setBool(_keyAutoSave, value);

  bool get saveConfirmations => _prefs.getBool(_keyNotifications) ?? true;
  Future<void> setSaveConfirmations(bool value) =>
      _prefs.setBool(_keyNotifications, value);

  bool get videoAutoplay => _prefs.getBool(_keyAutoplay) ?? true;
  Future<void> setVideoAutoplay(bool value) => _prefs.setBool(_keyAutoplay, value);

  bool get muteByDefault => _prefs.getBool(_keyMute) ?? false;
  Future<void> setMuteByDefault(bool value) => _prefs.setBool(_keyMute, value);

  bool get confirmDelete => _prefs.getBool(_keyConfirmDelete) ?? true;
  Future<void> setConfirmDelete(bool value) =>
      _prefs.setBool(_keyConfirmDelete, value);
}
