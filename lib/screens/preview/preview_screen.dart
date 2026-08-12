import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../app/strings.dart';
import '../../app/theme/app_colors.dart';
import '../../models/status_media.dart';
import '../../services/share_service.dart';
import '../../services/status_repository.dart';
import '../../util/formatters.dart';
import '../../viewmodels/downloads_view_model.dart';
import '../../viewmodels/home_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../widgets/app_toast.dart';

/// Full-screen media viewer for images and videos, swipeable between items.
///
/// Used both for live statuses (save action) and for the saved gallery
/// (delete action) via [fromDownloads].
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    this.fromDownloads = false,
  });

  final List<StatusMedia> items;
  final int initialIndex;
  final bool fromDownloads;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  VideoPlayerController? _video;
  bool _videoLoading = false;
  bool _videoError = false;
  bool _muted = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  StatusMedia get _current => widget.items[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _muted = context.read<SettingsViewModel>().muteByDefault;
    _prepareCurrent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _pageController.dispose();
    _disposeVideo();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _video?.pause();
    }
  }

  void _disposeVideo() {
    final old = _video;
    _video = null;
    old?.dispose();
  }

  Future<void> _prepareCurrent({int attempt = 0}) async {
    _disposeVideo();
    _videoError = false;
    if (!_current.isVideo) {
      setState(() => _videoLoading = false);
      return;
    }
    setState(() => _videoLoading = true);
    final media = _current;
    try {
      final path = await context.read<StatusRepository>().playableFile(media);
      // The user may have swiped on while the file was being resolved.
      if (!mounted || media != _current) return;
      final controller = VideoPlayerController.file(File(path));
      try {
        await controller.initialize();
      } catch (e) {
        controller.dispose();
        // Some device decoders (notably emulators) fail once and then
        // succeed — retry a single time before surfacing the error.
        if (attempt == 0 && mounted && media == _current) {
          return _prepareCurrent(attempt: 1);
        }
        rethrow;
      }
      if (!mounted || media != _current) {
        controller.dispose();
        return;
      }
      controller
        ..setLooping(true)
        ..setVolume(_muted ? 0 : 1);
      _video = controller;
      if (context.read<SettingsViewModel>().videoAutoplay) {
        controller.play();
        _scheduleHide();
      }
      setState(() => _videoLoading = false);
    } catch (e) {
      if (!mounted || media != _current) return;
      setState(() {
        _videoLoading = false;
        _videoError = true;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
      _controlsVisible = true;
    });
    _prepareCurrent();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 3200), () {
      final playing = _video?.value.isPlaying ?? false;
      if (mounted && playing) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  void _togglePlay() {
    final video = _video;
    if (video == null) return;
    setState(() {
      video.value.isPlaying ? video.pause() : video.play();
    });
    _scheduleHide();
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      _video?.setVolume(_muted ? 0 : 1);
    });
  }

  Future<void> _save() async {
    final vm = context.read<HomeViewModel>();
    final showConfirmations =
        context.read<SettingsViewModel>().saveConfirmations;
    final outcome = await vm.save(_current);
    if (!mounted) return;
    switch (outcome) {
      case SaveOutcome.saved:
        if (showConfirmations) {
          AppToast.show(context, AppStrings.savedSuccessfully);
        }
        context.read<DownloadsViewModel>().refresh(silent: true);
      case SaveOutcome.alreadySaved:
        AppToast.show(context, AppStrings.alreadySaved,
            icon: Icons.info_outline_rounded);
      case SaveOutcome.failed:
        AppToast.show(context, AppStrings.saveFailed,
            icon: Icons.error_outline_rounded, iconColor: Colors.redAccent);
    }
  }

  Future<void> _share({bool whatsapp = false}) async {
    final shareService = context.read<ShareService>();
    final statusRepo = context.read<StatusRepository>();
    final media = _current;
    try {
      // Resolve SAF-backed items to a real file so FileProvider can share it.
      final resolved =
          media.path ?? (media.uri!.startsWith('content://') && !widget.fromDownloads
              ? await statusRepo.playableFile(media)
              : null);
      final outcome = whatsapp
          ? await shareService.sendToWhatsApp(media, resolvedPath: resolved)
          : await shareService.share(media, resolvedPath: resolved);
      if (!mounted) return;
      if (outcome == ShareOutcome.whatsappMissingFellBack) {
        AppToast.show(context, AppStrings.whatsappMissing,
            icon: Icons.info_outline_rounded);
      } else if (outcome == ShareOutcome.failed) {
        AppToast.show(context, AppStrings.shareFailed,
            icon: Icons.error_outline_rounded, iconColor: Colors.redAccent);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, AppStrings.shareFailed,
            icon: Icons.error_outline_rounded, iconColor: Colors.redAccent);
      }
    }
  }

  Future<void> _delete() async {
    final downloadsVm = context.read<DownloadsViewModel>();
    final confirm = context.read<SettingsViewModel>().confirmDelete;
    if (confirm) {
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
    if (!mounted) return;
    final ok = await downloadsVm.delete(_current);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      AppToast.show(context, AppStrings.deleteFailed,
          icon: Icons.error_outline_rounded, iconColor: Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.viewerBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.items.length,
              itemBuilder: (context, index) => _MediaPage(
                media: widget.items[index],
                isCurrent: index == _index,
                video: index == _index ? _video : null,
                videoLoading: index == _index && _videoLoading,
                videoError: index == _index && _videoError,
                onTap: _toggleControls,
                onRetry: _prepareCurrent,
              ),
            ),
            AnimatedOpacity(
              opacity: _controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: Column(
                  children: [
                    _topBar(context),
                    const Spacer(),
                    if (_current.isVideo) _videoBottomBlock(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xB3000000), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _current.isVideo
                        ? AppStrings.tabVideos
                        : AppStrings.tabPhotos,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    Formatters.timeAgo(_current.modified),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${_index + 1} / ${widget.items.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(width: 8),
              // Compact download action + overflow menu for every media type.
              if (!widget.fromDownloads)
                _SaveFab(
                  saved: _current.isSaved,
                  saving: context.watch<HomeViewModel>().isSaving(_current),
                  onTap: _save,
                ),
              _moreMenu(context),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  /// Top-bar overflow menu for videos: Share, Send to WhatsApp and, for
  /// saved items, Delete — shown as a dark action sheet.
  Widget _moreMenu(BuildContext context) {
    return IconButton(
      tooltip: 'More options',
      onPressed: _showActionSheet,
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
    );
  }

  Future<void> _showActionSheet() async {
    _video?.pause();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E262E),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetItem(context, 'share',
                const Icon(Icons.share_rounded, color: Colors.white),
                AppStrings.share),
            _sheetItem(context, 'whatsapp',
                const FaIcon(FontAwesomeIcons.whatsapp,
                    color: Color(0xFF25D366)),
                AppStrings.sendToWhatsApp),
            if (widget.fromDownloads)
              _sheetItem(context, 'delete',
                  const Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger),
                  AppStrings.delete,
                  textColor: AppColors.danger),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'share':
        _share();
      case 'whatsapp':
        _share(whatsapp: true);
      case 'delete':
        _delete();
    }
  }

  Widget _sheetItem(
      BuildContext context, String value, Widget leading, String label,
      {Color textColor = Colors.white}) {
    return ListTile(
      leading: leading,
      title: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: () => Navigator.pop(context, value),
    );
  }

  /// Bottom overlay for videos: playback buttons with the progress bar
  /// anchored at the very bottom edge.
  Widget _videoBottomBlock(BuildContext context) {
    if (_video == null) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xE6000000), Color(0x66000000), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: _videoControls(),
      ),
    );
  }

  Widget _videoControls() {
    final video = _video!;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: video,
      builder: (context, value, _) {
        final position = value.position;
        final duration = value.duration == Duration.zero
            ? const Duration(seconds: 1)
            : value.duration;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: _muted ? AppStrings.unmute : AppStrings.mute,
                  onPressed: _toggleMute,
                  icon: Icon(
                      _muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Back 10 seconds',
                  onPressed: () {
                    video.seekTo(position - const Duration(seconds: 10));
                    _scheduleHide();
                  },
                  icon: const Icon(Icons.replay_10_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: value.isPlaying ? AppStrings.pause : AppStrings.play,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _togglePlay,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.viewerBackground,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Forward 10 seconds',
                  onPressed: () {
                    video.seekTo(position + const Duration(seconds: 10));
                    _scheduleHide();
                  },
                  icon: const Icon(Icons.forward_10_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 40),
              ],
            ),
            // Progress bar sits at the very bottom edge of the screen.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Text(Formatters.duration(position),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble(),
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (ms) {
                          video.seekTo(Duration(milliseconds: ms.round()));
                          _scheduleHide();
                        },
                      ),
                    ),
                  ),
                  Text(Formatters.duration(duration),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

}

class _MediaPage extends StatelessWidget {
  const _MediaPage({
    required this.media,
    required this.isCurrent,
    required this.video,
    required this.videoLoading,
    required this.videoError,
    required this.onTap,
    required this.onRetry,
  });

  final StatusMedia media;
  final bool isCurrent;
  final VideoPlayerController? video;
  final bool videoLoading;
  final bool videoError;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (media.isVideo) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: _videoBody(context),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: _ImageBody(media: media),
    );
  }

  Widget _videoBody(BuildContext context) {
    if (videoError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined,
                color: Colors.white54, size: 56),
            const SizedBox(height: 12),
            const Text(AppStrings.videoError,
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54)),
              child: const Text(AppStrings.tryAgain),
            ),
          ],
        ),
      );
    }
    final controller = video;
    if (!isCurrent || videoLoading || controller == null ||
        !controller.value.isInitialized) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 9 / 16
            : controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({required this.media});

  final StatusMedia media;

  @override
  Widget build(BuildContext context) {
    if (media.path != null) {
      return _zoomable(Image.file(File(media.path!),
          fit: BoxFit.contain, errorBuilder: _error));
    }
    // SAF-backed image: resolve to a cached local file first.
    return FutureBuilder<String>(
      future: context.read<StatusRepository>().playableFile(media),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error(context, snapshot.error!, null);
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        return _zoomable(Image.file(File(snapshot.data!),
            fit: BoxFit.contain, errorBuilder: _error));
      },
    );
  }

  Widget _zoomable(Widget child) => InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(child: child),
      );

  Widget _error(BuildContext context, Object error, StackTrace? stack) =>
      const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white54, size: 56),
            SizedBox(height: 12),
            Text(AppStrings.fileGone, style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
}

/// Compact circular download action sized to sit inside the top bar.
class _SaveFab extends StatelessWidget {
  const _SaveFab({
    required this.saved,
    required this.saving,
    required this.onTap,
  });

  final bool saved;
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: saved ? AppStrings.alreadySaved : AppStrings.save,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: saving ? null : onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: saving
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.2),
                  )
                : Icon(
                    saved ? Icons.check_rounded : Icons.download_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }
}
