import 'package:flutter/foundation.dart';

import '../models/status_media.dart';
import '../services/download_repository.dart';

enum DownloadsStatus { loading, ready, empty, error }

/// Drives the Downloads gallery.
class DownloadsViewModel extends ChangeNotifier {
  DownloadsViewModel(this._repo);

  final DownloadRepository _repo;

  DownloadsStatus status = DownloadsStatus.loading;
  List<StatusMedia> items = const [];

  List<StatusMedia> get photos =>
      items.where((e) => e.type == MediaType.image).toList();
  List<StatusMedia> get videos =>
      items.where((e) => e.type == MediaType.video).toList();

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      status = DownloadsStatus.loading;
      notifyListeners();
    }
    try {
      items = await _repo.listSaved();
      status = items.isEmpty ? DownloadsStatus.empty : DownloadsStatus.ready;
    } catch (e) {
      if (kDebugMode) debugPrint('Loading downloads failed: $e');
      status = DownloadsStatus.error;
    }
    notifyListeners();
  }

  Future<bool> delete(StatusMedia media) async {
    final ok = await _repo.delete(media);
    if (ok) {
      items = items.where((e) => e.id != media.id).toList();
      if (items.isEmpty) status = DownloadsStatus.empty;
      notifyListeners();
    }
    return ok;
  }
}
