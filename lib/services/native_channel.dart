import 'package:flutter/services.dart';

import '../models/status_media.dart';

/// Snapshot of the device capabilities relevant to status detection.
class NativeEnvironment {
  const NativeEnvironment({
    required this.sdkInt,
    required this.whatsappInstalled,
    required this.businessInstalled,
    required this.hasSafGrant,
    required this.canReadDirect,
  });

  final int sdkInt;
  final bool whatsappInstalled;
  final bool businessInstalled;
  final bool hasSafGrant;
  final bool canReadDirect;

  factory NativeEnvironment.fromMap(Map<dynamic, dynamic> map) =>
      NativeEnvironment(
        sdkInt: (map['sdkInt'] as num).toInt(),
        whatsappInstalled: map['whatsappInstalled'] == true,
        businessInstalled: map['businessInstalled'] == true,
        hasSafGrant: map['hasSafGrant'] == true,
        canReadDirect: map['canReadDirect'] == true,
      );
}

class ThumbnailResult {
  const ThumbnailResult(this.path, this.duration, {this.width, this.height});

  final String path;
  final Duration? duration;

  /// Rotation-corrected decoded-frame dimensions, when known.
  final int? width;
  final int? height;
}

class SaveResult {
  const SaveResult({required this.alreadyExisted, required this.uri});

  final bool alreadyExisted;
  final String uri;
}

/// Thin, typed wrapper around the platform channel implemented in
/// MainActivity.kt. All heavy work happens natively off the main thread.
class NativeChannel {
  static const _channel = MethodChannel('status_saver/native');

  Future<NativeEnvironment> getEnvironment() async {
    final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('getEnvironment');
    return NativeEnvironment.fromMap(map!);
  }

  Future<List<StatusMedia>> listStatuses() async {
    final list = await _channel.invokeMethod<List<dynamic>>('listStatuses');
    return (list ?? const [])
        .map((e) => StatusMedia.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  Future<bool> requestSafAccess() async =>
      await _channel.invokeMethod<bool>('requestSafAccess') ?? false;

  Future<bool> checkStoragePermission() async =>
      await _channel.invokeMethod<bool>('checkStoragePermission') ?? false;

  /// Returns (granted, permanentlyDenied).
  Future<(bool, bool)> requestStoragePermission() async {
    final map = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('requestStoragePermission');
    return (map!['granted'] == true, map['permanentlyDenied'] == true);
  }

  Future<bool> openAppSettings() async =>
      await _channel.invokeMethod<bool>('openAppSettings') ?? false;

  Future<ThumbnailResult> getThumbnail(StatusMedia media) async {
    final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('getThumbnail', {
      'path': media.path,
      'uri': media.uri,
      'type': media.isVideo ? 'video' : 'image',
      'key': '${media.name}_${media.modified.millisecondsSinceEpoch}_${media.size}',
    });
    final durationMs = (map!['duration'] as num?)?.toInt();
    return ThumbnailResult(
      map['path'] as String,
      durationMs == null ? null : Duration(milliseconds: durationMs),
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
    );
  }

  Future<String> getPlayableFile(StatusMedia media) async {
    final path = await _channel.invokeMethod<String>('getPlayableFile', {
      'path': media.path,
      'uri': media.uri,
      'name': media.name,
    });
    return path!;
  }

  Future<SaveResult> saveToGallery(StatusMedia media) async {
    final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('saveToGallery', {
      'path': media.path,
      'uri': media.uri,
      'name': media.name,
      'type': media.isVideo ? 'video' : 'image',
    });
    return SaveResult(
      alreadyExisted: map!['status'] == 'exists',
      uri: map['uri'] as String,
    );
  }

  Future<List<StatusMedia>> listSaved() async {
    final list = await _channel.invokeMethod<List<dynamic>>('listSaved');
    return (list ?? const [])
        .map((e) => StatusMedia.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  Future<bool> deleteSaved(String uri) async =>
      await _channel.invokeMethod<bool>('deleteSaved', {'uri': uri}) ?? false;

  /// Returns "ok", "not_installed", "no_app" or "error".
  Future<String> shareMedia({
    String? path,
    String? uri,
    required String mime,
    String? targetPackage,
    required String title,
  }) async {
    final result = await _channel.invokeMethod<String>('shareMedia', {
      'path': path,
      'uri': uri,
      'mime': mime,
      'targetPackage': targetPackage,
      'title': title,
    });
    return result ?? 'error';
  }

  Future<String> openMedia({String? path, String? uri, required String mime}) async {
    final result = await _channel.invokeMethod<String>('openMedia', {
      'path': path,
      'uri': uri,
      'mime': mime,
    });
    return result ?? 'error';
  }

}
