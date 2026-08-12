import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Floating pill toast matching the "Saved successfully ✓" style from the
/// UI reference. Safe to call from any screen with an [Overlay].
abstract final class AppToast {
  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
    Color iconColor = AppColors.primary,
  }) {
    _timer?.cancel();
    _current?.remove();

    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 32,
        right: 32,
        bottom: MediaQuery.of(context).size.height * 0.16,
        child: IgnorePointer(
          child: Center(
            child: _ToastBody(message: message, icon: icon, iconColor: iconColor),
          ),
        ),
      ),
    );
    _current = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(milliseconds: 2200), () {
      entry.remove();
      if (_current == entry) _current = null;
    });
  }
}

class _ToastBody extends StatefulWidget {
  const _ToastBody({required this.message, required this.icon, required this.iconColor});

  final String message;
  final IconData icon;
  final Color iconColor;

  @override
  State<_ToastBody> createState() => _ToastBodyState();
}

class _ToastBodyState extends State<_ToastBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260))
    ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xE6262D34),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(widget.icon, color: widget.iconColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
