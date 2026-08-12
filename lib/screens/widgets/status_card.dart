import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme/app_colors.dart';
import '../../models/status_media.dart';
import '../../util/formatters.dart';
import 'media_thumb.dart';

/// Grid card for a status: thumbnail, video badge, time and a save action.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.media,
    required this.onTap,
    this.onSave,
    this.isSaving = false,
    this.trailing,
  });

  final StatusMedia media;
  final VoidCallback onTap;

  /// When provided, the card shows a Download / Saved action row.
  final VoidCallback? onSave;
  final bool isSaving;

  /// Optional custom action row (used by the Downloads screen).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label:
          '${media.isVideo ? AppStrings.tabVideos : AppStrings.tabPhotos}, ${Formatters.timeAgo(media.modified)}',
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaThumb(media: media),
                    if (media.isVideo)
                      const Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0x66000000),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: trailing ??
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            Formatters.timeAgo(media.modified),
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onSave != null) _SaveButton(media: media, onSave: onSave!, isSaving: isSaving),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton(
      {required this.media, required this.onSave, required this.isSaving});

  final StatusMedia media;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    if (isSaving) {
      return const SizedBox(
        width: 34,
        height: 34,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    if (media.isSaved) {
      return Tooltip(
        message: AppStrings.alreadySaved,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              size: 20, color: AppColors.primary),
        ),
      );
    }
    return Semantics(
      button: true,
      label: AppStrings.download,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onSave,
          child: const SizedBox(
            width: 34,
            height: 34,
            child: Icon(Icons.download_rounded, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
