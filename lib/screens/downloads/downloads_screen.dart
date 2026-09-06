import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/strings.dart';
import '../../app/theme/app_colors.dart';
import '../../models/status_media.dart';
import '../../services/share_service.dart';
import '../../viewmodels/downloads_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../preview/preview_screen.dart';
import '../widgets/app_toast.dart';
import '../widgets/empty_state.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/skeleton_grid.dart';
import '../widgets/status_card.dart';

/// Gallery of statuses saved by this app.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key, this.onGoToStatuses});

  /// Switches the shell back to the Statuses tab.
  final VoidCallback? onGoToStatuses;

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadsViewModel>().refresh();
    });
  }

  List<StatusMedia> _itemsFor(DownloadsViewModel vm) => switch (_tab) {
        1 => vm.photos,
        2 => vm.videos,
        _ => vm.items,
      };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DownloadsViewModel>();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(AppStrings.navDownloads,
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  tooltip: AppStrings.refresh,
                  onPressed: () => vm.refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SegmentedTabs(
              labels: const [
                AppStrings.tabAll,
                AppStrings.tabPhotos,
                AppStrings.tabVideos
              ],
              selectedIndex: _tab,
              onChanged: (index) => setState(() => _tab = index),
            ),
          ),
          Expanded(child: _body(context, vm)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, DownloadsViewModel vm) {
    switch (vm.status) {
      case DownloadsStatus.loading:
        return const SkeletonGrid();
      case DownloadsStatus.error:
        return EmptyState(
          icon: Icons.error_outline_rounded,
          title: AppStrings.errorTitle,
          body: AppStrings.errorBody,
          actionLabel: AppStrings.tryAgain,
          onAction: () => vm.refresh(),
        );
      case DownloadsStatus.empty:
        return _emptyState(context);
      case DownloadsStatus.ready:
        final items = _itemsFor(vm);
        if (items.isEmpty) return _emptyState(context);
        return RefreshIndicator(
          onRefresh: () => vm.refresh(silent: true),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final media = items[index];
              return StatusCard(
                media: media,
                onTap: () => _openPreview(context, items, index),
                trailing: _cardActions(context, vm, media),
              );
            },
          ),
        );
    }
  }

  Widget _emptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.download_outlined,
      title: AppStrings.emptyDownloadsTitle,
      body: AppStrings.emptyDownloadsBody,
      actionLabel: AppStrings.openStatuses,
      onAction: widget.onGoToStatuses,
    );
  }

  Widget _cardActions(
      BuildContext context, DownloadsViewModel vm, StatusMedia media) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            _dateLabel(media),
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _SmallIconButton(
          icon: Icons.share_rounded,
          tooltip: AppStrings.share,
          onTap: () => _share(context, media),
        ),
        const SizedBox(width: 4),
        _SmallIconButton(
          icon: Icons.delete_outline_rounded,
          tooltip: AppStrings.delete,
          color: AppColors.danger,
          onTap: () => _delete(context, vm, media),
        ),
      ],
    );
  }

  String _dateLabel(StatusMedia media) {
    final date = media.modified;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _share(BuildContext context, StatusMedia media) async {
    final outcome = await context.read<ShareService>().share(media);
    if (context.mounted && outcome == ShareOutcome.failed) {
      AppToast.show(context, AppStrings.shareFailed,
          icon: Icons.error_outline_rounded, iconColor: Colors.redAccent);
    }
  }

  Future<void> _delete(
      BuildContext context, DownloadsViewModel vm, StatusMedia media) async {
    if (context.read<SettingsViewModel>().confirmDelete) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.deleteTitle),
          content: const Text(AppStrings.deleteBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.delete,
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (sure != true) return;
    }
    if (!context.mounted) return;
    final ok = await vm.delete(media);
    if (!context.mounted) return;
    AppToast.show(
      context,
      ok ? AppStrings.deleted : AppStrings.deleteFailed,
      icon: ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
      iconColor: ok ? AppColors.primary : Colors.redAccent,
    );
  }

  void _openPreview(
      BuildContext context, List<StatusMedia> items, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PreviewScreen(
          items: items, initialIndex: index, fromDownloads: true),
    ));
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon,
              size: 19,
              color: color ?? Theme.of(context).textTheme.bodySmall?.color),
        ),
      ),
    );
  }
}
