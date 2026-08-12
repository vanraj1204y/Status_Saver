import 'package:flutter/foundation.dart';

import '../models/status_media.dart';
import 'native_channel.dart';

/// Loads live WhatsApp statuses and enriches them with thumbnails and
/// saved-state information.
class StatusRepository {
  StatusRepository(this._channel);

  final NativeChannel _channel;
  final Map<String, ThumbnailResult> _thumbCache = {};

  Future<NativeEnvironment> environment() => _channel.getEnvironment();

  Future<bool> requestSafAccess() => _channel.requestSafAccess();

  /// Returns statuses newest-first, flagged with whether a saved copy exists.
  Future<List<StatusMedia>> loadStatuses(Set<String> savedNames) async {
    final statuses = await _channel.listStatuses();
    for (final status in statuses) {
      final saved = savedNames.contains(savedNameFor(status));
      status.isSaved = saved;
      final cached = _thumbCache['${status.id}_${status.modified.millisecondsSinceEpoch}'];
      if (cached != null) {
        status
          ..thumbPath = cached.path
          ..duration = cached.duration ?? status.duration;
      }
    }
    return statuses;
  }

  /// Mirrors the native naming scheme used when saving to the gallery.
  static String savedNameFor(StatusMedia media) =>
      'StatusSaver_${media.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}';

  /// Fetches (and caches) a thumbnail for the given item.
  Future<ThumbnailResult?> thumbnailFor(StatusMedia media) async {
    final key = '${media.id}_${media.modified.millisecondsSinceEpoch}';
    final cached = _thumbCache[key];
    if (cached != null) return cached;
    try {
      final result = await _channel.getThumbnail(media);
      _thumbCache[key] = result;
      media
        ..thumbPath = result.path
        ..duration = result.duration ?? media.duration;
      return result;
    } catch (e) {
      debugPrint('Thumbnail failed for ${media.name}: $e');
      return null;
    }
  }

  /// Resolves a local file path that can be displayed or played.
  Future<String> playableFile(StatusMedia media) => _channel.getPlayableFile(media);
}
