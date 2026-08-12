import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/strings.dart';
import 'app/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'services/download_repository.dart';
import 'services/native_channel.dart';
import 'services/settings_repository.dart';
import 'services/share_service.dart';
import 'services/status_repository.dart';
import 'viewmodels/downloads_view_model.dart';
import 'viewmodels/home_view_model.dart';
import 'viewmodels/settings_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsRepository.load();
  runApp(StatusSaverApp(settings: settings));
}

class StatusSaverApp extends StatelessWidget {
  const StatusSaverApp({super.key, required this.settings});

  final SettingsRepository settings;

  @override
  Widget build(BuildContext context) {
    final channel = NativeChannel();
    final statusRepository = StatusRepository(channel);
    final downloadRepository = DownloadRepository(channel);
    final downloadsViewModel = DownloadsViewModel(downloadRepository);
    // Every successful download refreshes the gallery automatically.
    final homeViewModel = HomeViewModel(
        channel, statusRepository, downloadRepository, settings,
        onMediaSaved: () => downloadsViewModel.refresh(silent: true));

    return MultiProvider(
      providers: [
        Provider.value(value: channel),
        Provider.value(value: statusRepository),
        Provider.value(value: downloadRepository),
        Provider(create: (_) => ShareService(channel)),
        ChangeNotifierProvider(create: (_) => SettingsViewModel(settings)),
        ChangeNotifierProvider.value(value: homeViewModel),
        ChangeNotifierProvider.value(value: downloadsViewModel),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settingsVm, _) => MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settingsVm.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
