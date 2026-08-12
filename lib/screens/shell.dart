import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/strings.dart';
import '../viewmodels/downloads_view_model.dart';
import '../viewmodels/home_view_model.dart';
import 'downloads/downloads_screen.dart';
import 'home/home_screen.dart';
import 'howto/how_to_screen.dart';
import 'settings/settings_screen.dart';

/// Root scaffold with the four-tab bottom navigation.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh silently when the user comes back from WhatsApp.
    if (state == AppLifecycleState.resumed) {
      context.read<HomeViewModel>().refresh(silent: true);
      context.read<DownloadsViewModel>().refresh(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back from any other tab returns to Statuses first; the app only
      // closes when back is pressed on the Statuses tab itself.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          DownloadsScreen(
              onGoToStatuses: () => setState(() => _index = 0)),
          const HowToScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          setState(() => _index = index);
          // Keep the gallery current whenever the user opens the tab.
          if (index == 1) {
            context.read<DownloadsViewModel>().refresh(silent: true);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: AppStrings.navStatuses,
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download_rounded),
            label: AppStrings.navDownloads,
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline_rounded),
            selectedIcon: Icon(Icons.help_rounded),
            label: AppStrings.navHowTo,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: AppStrings.navSettings,
          ),
        ],
      ),
    );
  }
}
