import 'package:flutter/foundation.dart';

import '../models/status_media.dart';
import '../services/download_repository.dart';
import '../services/native_channel.dart';
import '../services/settings_repository.dart';
import '../services/status_repository.dart';

enum HomeStatus {
  loading,
  ready,
  empty,
  needsPermission,
  permissionPermanentlyDenied,
  needsSaf,
  error,
}

enum SaveOutcome { saved, alreadySaved, failed }

/// Drives the Statuses screen: permission flow, scanning and saving.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(
      this._channel, this._statusRepo, this._downloadRepo, this._settings,
      {this.onMediaSaved});

  /// Invoked after every successful save so the Downloads gallery can
  /// refresh itself without the user tapping refresh.
  final VoidCallback? onMediaSaved;

  final NativeChannel _channel;
  final StatusRepository _statusRepo;
  final DownloadRepository _downloadRepo;
  final SettingsRepository _settings;

  HomeStatus status = HomeStatus.loading;
  List<StatusMedia> items = const [];
  NativeEnvironment? environment;
  bool _initialized = false;
  final Set<String> _savingIds = {};

  bool isSaving(StatusMedia media) => _savingIds.contains(media.id);

  List<StatusMedia> get photos =>
      items.where((e) => e.type == MediaType.image).toList();
  List<StatusMedia> get videos =>
      items.where((e) => e.type == MediaType.video).toList();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  /// Re-scans statuses, resolving the permission strategy for this device.
  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      status = HomeStatus.loading;
      notifyListeners();
    }
    try {
      environment = await _statusRepo.environment();
      final env = environment!;

      final hasPermission = await _channel.checkStoragePermission();
      // Below Android 13 the runtime permission is a hard requirement for
      // reading any shared storage. On 13+ statuses come from SAF instead.
      if (env.sdkInt <= 32 && !hasPermission && !env.canReadDirect) {
        status = HomeStatus.needsPermission;
        notifyListeners();
        return;
      }

      final savedNames = await _downloadRepo.savedNames();
      final statuses = await _statusRepo.loadStatuses(savedNames);

      if (statuses.isEmpty) {
        // On scoped-storage Androids, an empty scan without a folder grant
        // almost always means we need the SAF grant, so guide the user there.
        final canUseSaf = env.sdkInt >= 30 && !env.hasSafGrant;
        status = canUseSaf ? HomeStatus.needsSaf : HomeStatus.empty;
        items = const [];
        notifyListeners();
        return;
      }

      items = statuses;
      status = HomeStatus.ready;
      notifyListeners();

      if (_settings.autoSave) {
        await _autoSaveNew();
      }
    } catch (e) {
      debugPrint('Status scan failed: $e');
      status = HomeStatus.error;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    final (granted, permanentlyDenied) = await _channel.requestStoragePermission();
    if (granted) {
      await refresh();
    } else {
      status = permanentlyDenied
          ? HomeStatus.permissionPermanentlyDenied
          : HomeStatus.needsPermission;
      notifyListeners();
    }
  }

  Future<void> openAppSettings() => _channel.openAppSettings();

  /// Launches the system folder picker; returns whether access was granted.
  Future<bool> requestSafAccess() async {
    final granted = await _statusRepo.requestSafAccess();
    if (granted) await refresh();
    return granted;
  }

  Future<SaveOutcome> save(StatusMedia media) async {
    if (_savingIds.contains(media.id)) return SaveOutcome.failed;
    _savingIds.add(media.id);
    notifyListeners();
    try {
      final result = await _downloadRepo.save(media);
      media
        ..isSaved = true
        ..savedUri = result.uri;
      if (!result.alreadyExisted) onMediaSaved?.call();
      return result.alreadyExisted ? SaveOutcome.alreadySaved : SaveOutcome.saved;
    } catch (e) {
      debugPrint('Save failed for ${media.name}: $e');
      return SaveOutcome.failed;
    } finally {
      _savingIds.remove(media.id);
      notifyListeners();
    }
  }

  Future<void> _autoSaveNew() async {
    for (final media in List<StatusMedia>.from(items)) {
      if (!media.isSaved && !_savingIds.contains(media.id)) {
        await save(media);
      }
    }
  }
}
