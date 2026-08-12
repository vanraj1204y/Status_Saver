import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme/app_colors.dart';

/// Beginner-friendly walkthrough of how the app works.
class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  static const _steps = [
    (Icons.chat_outlined, AppStrings.howToStep1Title, AppStrings.howToStep1Body),
    (Icons.visibility_outlined, AppStrings.howToStep2Title, AppStrings.howToStep2Body),
    (Icons.replay_rounded, AppStrings.howToStep3Title, AppStrings.howToStep3Body),
    (Icons.download_rounded, AppStrings.howToStep4Title, AppStrings.howToStep4Body),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: Text(AppStrings.navHowTo, style: theme.textTheme.titleLarge),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF00A88F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.howToTitle,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Four quick steps — no account, no setup.',
                        style: TextStyle(color: Colors.white70, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.tips_and_updates_outlined,
                    color: Colors.white, size: 44),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _steps.length; i++) ...[
            _StepCard(
              index: i + 1,
              icon: _steps[i].$1,
              title: _steps[i].$2,
              body: _steps[i].$3,
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.howToNote,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int index;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$index',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
