import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/status_media.dart';
import '../../services/status_repository.dart';
import '../../util/formatters.dart';

/// Lazily loads and displays a media thumbnail through the native cache.
/// For videos, overlays the duration badge once known.
class MediaThumb extends StatelessWidget {
  const MediaThumb({super.key, required this.media});

  final StatusMedia media;

  @override
  Widget build(BuildContext context) {
    if (media.thumbPath != null) {
      return _withBadge(_image(media.thumbPath!));
    }
    final repo = context.read<StatusRepository>();
    return FutureBuilder(
      future: repo.thumbnailFor(media),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ThumbPlaceholder();
        }
        final thumb = snapshot.data;
        if (thumb == null) return const _ThumbBroken();
        return _withBadge(_image(thumb.path));
      },
    );
  }

  Widget _withBadge(Widget image) {
    if (!media.isVideo || media.duration == null) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xB3000000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              Formatters.duration(media.duration!),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _image(String path) => Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => const _ThumbBroken(),
      );
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
}

class _ThumbBroken extends StatelessWidget {
  const _ThumbBroken();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).textTheme.bodySmall?.color,
          size: 28,
        ),
      );
}
