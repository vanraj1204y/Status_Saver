import 'package:flutter/material.dart';

import '../services/settings_repository.dart';

/// Exposes persisted settings to the UI and applies changes app-wide.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._repo);

  final SettingsRepository _repo;

  ThemeMode get themeMode => _repo.themeMode;
  bool get autoSave => _repo.autoSave;
  bool get saveConfirmations => _repo.saveConfirmations;
  bool get videoAutoplay => _repo.videoAutoplay;
  bool get muteByDefault => _repo.muteByDefault;
  bool get confirmDelete => _repo.confirmDelete;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repo.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setAutoSave(bool value) async {
    await _repo.setAutoSave(value);
    notifyListeners();
  }

  Future<void> setSaveConfirmations(bool value) async {
    await _repo.setSaveConfirmations(value);
    notifyListeners();
  }

  Future<void> setVideoAutoplay(bool value) async {
    await _repo.setVideoAutoplay(value);
    notifyListeners();
  }

  Future<void> setMuteByDefault(bool value) async {
    await _repo.setMuteByDefault(value);
    notifyListeners();
  }

  Future<void> setConfirmDelete(bool value) async {
    await _repo.setConfirmDelete(value);
    notifyListeners();
  }
}
