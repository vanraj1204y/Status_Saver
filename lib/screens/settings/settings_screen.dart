import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/strings.dart';
import '../../app/theme/app_colors.dart';
import '../../viewmodels/settings_view_model.dart';

/// App settings: general, appearance, media behavior and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(AppStrings.navSettings,
                style: theme.textTheme.titleLarge),
          ),

          _SectionLabel(AppStrings.settingsGeneral),
          _SectionCard(children: [
            _SwitchTile(
              icon: Icons.save_alt_rounded,
              title: AppStrings.autoSave,
              subtitle: AppStrings.autoSaveSub,
              value: vm.autoSave,
              onChanged: vm.setAutoSave,
            ),
            _InfoTile(
              icon: Icons.high_quality_outlined,
              title: AppStrings.downloadQuality,
              subtitle: AppStrings.downloadQualitySub,
            ),
            _InfoTile(
              icon: Icons.folder_outlined,
              title: AppStrings.downloadFolder,
              subtitle: AppStrings.downloadFolderSub,
            ),
            _SwitchTile(
              icon: Icons.notifications_none_rounded,
              title: AppStrings.notifications,
              subtitle: AppStrings.notificationsSub,
              value: vm.saveConfirmations,
              onChanged: vm.setSaveConfirmations,
            ),
          ]),

          _SectionLabel(AppStrings.settingsAppearance),
          _SectionCard(children: [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text(AppStrings.theme),
              subtitle: Text(_themeLabel(vm.themeMode)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickTheme(context, vm),
            ),
          ]),

          _SectionLabel(AppStrings.settingsMedia),
          _SectionCard(children: [
            _SwitchTile(
              icon: Icons.play_circle_outline_rounded,
              title: AppStrings.autoplay,
              subtitle: AppStrings.autoplaySub,
              value: vm.videoAutoplay,
              onChanged: vm.setVideoAutoplay,
            ),
            _SwitchTile(
              icon: Icons.volume_off_outlined,
              title: AppStrings.muteByDefault,
              subtitle: AppStrings.muteByDefaultSub,
              value: vm.muteByDefault,
              onChanged: vm.setMuteByDefault,
            ),
            _SwitchTile(
              icon: Icons.delete_sweep_outlined,
              title: AppStrings.confirmDelete,
              subtitle: AppStrings.confirmDeleteSub,
              value: vm.confirmDelete,
              onChanged: vm.setConfirmDelete,
            ),
          ]),

          _SectionLabel(AppStrings.settingsAbout),
          _SectionCard(children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text(AppStrings.privacy),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showInfo(
                  context, AppStrings.privacy, AppStrings.privacyText),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text(AppStrings.terms),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  _showInfo(context, AppStrings.terms, AppStrings.termsText),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text(AppStrings.about),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  _showInfo(context, AppStrings.about, AppStrings.aboutText),
            ),
            const ListTile(
              leading: Icon(Icons.tag_rounded),
              title: Text(AppStrings.appVersionLabel),
              trailing: Text(AppStrings.appVersion,
                  style: TextStyle(fontSize: 13)),
            ),
          ]),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => AppStrings.themeLight,
        ThemeMode.dark => AppStrings.themeDark,
        ThemeMode.system => AppStrings.themeSystem,
      };

  Future<void> _pickTheme(BuildContext context, SettingsViewModel vm) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(AppStrings.theme,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            RadioGroup<ThemeMode>(
              groupValue: vm.themeMode,
              onChanged: (value) {
                if (value != null) vm.setThemeMode(value);
                Navigator.pop(context);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final mode in [
                    ThemeMode.system,
                    ThemeMode.light,
                    ThemeMode.dark
                  ])
                    RadioListTile<ThemeMode>(
                      value: mode,
                      activeColor: AppColors.primary,
                      title: Text(_themeLabel(mode)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
