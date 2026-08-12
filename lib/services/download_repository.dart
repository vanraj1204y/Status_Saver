import '../models/status_media.dart';
import 'native_channel.dart';
import 'status_repository.dart';

/// Manages the app's saved gallery backed by MediaStore.
class DownloadRepository {
  DownloadRepository(this._channel);

  final NativeChannel _channel;

  /// Saves a status into the public gallery. Returns whether it was new.
  Future<SaveResult> save(StatusMedia media) => _channel.saveToGallery(media);

  /// All items previously saved by this app, newest first.
  Future<List<StatusMedia>> listSaved() async {
    final items = await _channel.listSaved();
    for (final item in items) {
      item
        ..isSaved = true
        ..savedUri = item.uri;
    }
    return items;
  }

  /// Display names of saved items, used to flag live statuses as saved.
  Future<Set<String>> savedNames() async =>
      (await _channel.listSaved()).map((e) => e.name).toSet();

  Future<bool> delete(StatusMedia media) async {
    final uri = media.savedUri ?? media.uri;
    if (uri == null) return false;
    return _channel.deleteSaved(uri);
  }

  static String savedNameFor(StatusMedia media) =>
      StatusRepository.savedNameFor(media);
}
