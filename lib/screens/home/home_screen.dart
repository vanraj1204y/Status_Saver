import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/strings.dart';
import '../../models/status_media.dart';
import '../../viewmodels/home_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../preview/preview_screen.dart';
import '../widgets/app_toast.dart';
import '../widgets/empty_state.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/skeleton_grid.dart';
import '../widgets/status_card.dart';

/// Main "Statuses" screen: recent WhatsApp statuses with Photos/Videos tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(onRefresh: () => vm.refresh()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SegmentedTabs(
              labels: const [AppStrings.tabPhotos, AppStrings.tabVideos],
              selectedIndex: _tab,
              onChanged: (index) => setState(() => _tab = index),
            ),
          ),
          Expanded(child: _buildBody(context, vm)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeViewModel vm) {
    switch (vm.status) {
      case HomeStatus.loading:
        return const SkeletonGrid();
      case HomeStatus.needsPermission:
        return EmptyState(
          icon: Icons.folder_shared_outlined,
          title: AppStrings.permissionTitle,
          body: AppStrings.permissionBody,
          actionLabel: AppStrings.permissionButton,
          onAction: () => vm.requestPermission(),
        );
      case HomeStatus.permissionPermanentlyDenied:
        return EmptyState(
          icon: Icons.lock_outline_rounded,
          title: AppStrings.permissionDeniedTitle,
          body: AppStrings.permissionDeniedBody,
          actionLabel: AppStrings.openAppSettings,
          onAction: () => vm.openAppSettings(),
          secondaryLabel: AppStrings.tryAgain,
          onSecondary: () => vm.requestPermission(),
        );
      case HomeStatus.needsSaf:
        return EmptyState(
          icon: Icons.folder_special_outlined,
          title: AppStrings.safTitle,
          body: AppStrings.safBody,
          actionLabel: AppStrings.safButton,
          onAction: () async {
            final granted = await vm.requestSafAccess();
            if (!granted && context.mounted) {
              AppToast.show(context, AppStrings.safDenied,
                  icon: Icons.info_outline_rounded);
            }
          },
        );
      case HomeStatus.error:
        return EmptyState(
          icon: Icons.error_outline_rounded,
          title: AppStrings.errorTitle,
          body: AppStrings.errorBody,
          actionLabel: AppStrings.tryAgain,
          onAction: () => vm.refresh(),
        );
      case HomeStatus.empty:
        return _refreshable(
          vm,
          EmptyState(
            icon: Icons.photo_library_outlined,
            title: AppStrings.emptyStatusesTitle,
            body: AppStrings.emptyStatusesBody,
            actionLabel: AppStrings.refresh,
            onAction: () => vm.refresh(),
          ),
        );
      case HomeStatus.ready:
        final items = _tab == 0 ? vm.photos : vm.videos;
        if (items.isEmpty) {
          return _refreshable(
            vm,
            EmptyState(
              icon: _tab == 0
                  ? Icons.photo_outlined
                  : Icons.videocam_outlined,
              title: _tab == 0
                  ? AppStrings.emptyPhotosTitle
                  : AppStrings.emptyVideosTitle,
              body: AppStrings.emptyStatusesBody,
              actionLabel: AppStrings.refresh,
              onAction: () => vm.refresh(),
            ),
          );
        }
        return _grid(context, vm, items);
    }
  }

  /// Wraps a non-scrolling child so pull-to-refresh still works.
  Widget _refreshable(HomeViewModel vm, Widget child) => RefreshIndicator(
        onRefresh: () => vm.refresh(silent: true),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(height: constraints.maxHeight, child: child),
          ),
        ),
      );

  Widget _grid(BuildContext context, HomeViewModel vm, List<StatusMedia> items) {
    return RefreshIndicator(
      onRefresh: () => vm.refresh(silent: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Text(AppStrings.recentStatuses,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final media = items[index];
                  return StatusCard(
                    media: media,
                    isSaving: vm.isSaving(media),
                    onTap: () => _openPreview(context, items, index),
                    onSave: () => _save(context, vm, media),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
      BuildContext context, HomeViewModel vm, StatusMedia media) async {
    final showConfirmations =
        context.read<SettingsViewModel>().saveConfirmations;
    final outcome = await vm.save(media);
    if (!context.mounted) return;
    switch (outcome) {
      case SaveOutcome.saved:
        if (showConfirmations) {
          AppToast.show(context, AppStrings.savedSuccessfully);
        }
      case SaveOutcome.alreadySaved:
        AppToast.show(context, AppStrings.alreadySaved,
            icon: Icons.info_outline_rounded);
      case SaveOutcome.failed:
        AppToast.show(context, AppStrings.saveFailed,
            icon: Icons.error_outline_rounded, iconColor: Colors.redAccent);
    }
  }

  void _openPreview(
      BuildContext context, List<StatusMedia> items, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PreviewScreen(items: items, initialIndex: index),
    ));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Image.asset('assets/branding/splash_logo.png', width: 34, height: 34),
          const SizedBox(width: 10),
          Text(AppStrings.appName, style: theme.textTheme.titleLarge),
          const Spacer(),
          IconButton(
            tooltip: AppStrings.refresh,
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}
