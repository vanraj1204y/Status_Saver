import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Pill-style segmented control matching the tab chips in the UI reference.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selectedIndex,
                label: labels[i],
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: i == selectedIndex
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: i == selectedIndex
                            ? Colors.white
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
