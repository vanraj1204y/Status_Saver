import 'package:flutter/material.dart';

/// Softly pulsing placeholder grid shown while statuses are being scanned.
class SkeletonGrid extends StatefulWidget {
  const SkeletonGrid({super.key});

  @override
  State<SkeletonGrid> createState() => _SkeletonGridState();
}

class _SkeletonGridState extends State<SkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1.0,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: _controller,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: 9,
        itemBuilder: (context, index) => DecoratedBox(
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
