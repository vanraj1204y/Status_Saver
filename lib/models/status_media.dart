enum MediaType { image, video }

/// A single status media item, either live (from WhatsApp's status folder)
/// or saved (from this app's gallery).
class StatusMedia {
  StatusMedia({
    required this.id,
    required this.name,
    required this.type,
    required this.modified,
    required this.size,
    this.path,
    this.uri,
    this.isSaved = false,
    this.savedUri,
    this.thumbPath,
    this.duration,
    this.thumbWidth,
    this.thumbHeight,
  });

  final String id;
  final String name;

  /// Absolute file path when directly readable, otherwise null.
  final String? path;

  /// Content URI when the item comes from SAF or MediaStore, otherwise null.
  final String? uri;

  final MediaType type;
  final DateTime modified;
  final int size;

  /// Whether a copy already exists in the app's saved gallery.
  bool isSaved;

  /// URI of the saved copy, when known.
  String? savedUri;

  /// Cached thumbnail file path, filled lazily.
  String? thumbPath;

  /// Video duration, when known.
  Duration? duration;

  /// Real, rotation-corrected media dimensions from the decoded thumbnail
  /// frame — more reliable than `video_player`'s reported size for some
  /// files, where it can come back as zero. Filled lazily.
  int? thumbWidth;
  int? thumbHeight;

  /// Rotation-corrected aspect ratio derived from the thumbnail, when known.
  double? get thumbAspectRatio {
    final w = thumbWidth;
    final h = thumbHeight;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return w / h;
  }

  bool get isVideo => type == MediaType.video;

  String get mimeType {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (type == MediaType.video) {
      return switch (ext) {
        '3gp' => 'video/3gpp',
        'mkv' => 'video/x-matroska',
        'webm' => 'video/webm',
        _ => 'video/mp4',
      };
    }
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  factory StatusMedia.fromMap(Map<dynamic, dynamic> map) => StatusMedia(
        id: map['id'] as String,
        name: map['name'] as String,
        path: map['path'] as String?,
        uri: map['uri'] as String?,
        type: (map['type'] as String) == 'video' ? MediaType.video : MediaType.image,
        modified: DateTime.fromMillisecondsSinceEpoch((map['modified'] as num).toInt()),
        size: (map['size'] as num).toInt(),
      );
}
