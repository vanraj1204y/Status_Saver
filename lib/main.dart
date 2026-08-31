import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/strings.dart';
import 'app/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/update/force_update_screen.dart';
import 'services/download_repository.dart';
import 'services/native_channel.dart';
import 'services/settings_repository.dart';
import 'services/share_service.dart';
import 'services/status_repository.dart';
import 'services/update/update_gate_controller.dart';
import 'services/update/update_gate_result.dart';
import 'viewmodels/downloads_view_model.dart';
import 'viewmodels/home_view_model.dart';
import 'viewmodels/settings_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Kicked off first so it runs concurrently with the settings warm-read
  // below — never throws (see UpdateGateController).
  final updateGateResultFuture = UpdateGateController().resolve();
  final settings = await SettingsRepository.load();
  final updateGateResult = await updateGateResultFuture;
  runApp(StatusSaverApp(settings: settings, initialUpdateGateResult: updateGateResult));
}

/// Root widget. Also owns the force-update gate: while blocked, this swaps
/// the whole `home:` for [ForceUpdateScreen] so there is no route the user
/// can navigate to bypass it, and re-checks the local install version on
/// resume in case the user updated from the Play Store and came back. This
/// app has no Riverpod/router (Provider only), so the gate result is simply
/// threaded through the widget's own state instead of a provider override.
class StatusSaverApp extends StatefulWidget {
  const StatusSaverApp({
    super.key,
    required this.settings,
    required this.initialUpdateGateResult,
  });

  final SettingsRepository settings;
  final UpdateGateResult initialUpdateGateResult;

  @override
  State<StatusSaverApp> createState() => _StatusSaverAppState();
}

class _StatusSaverAppState extends State<StatusSaverApp> with WidgetsBindingObserver {
  late UpdateGateResult _updateGateResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateGateResult = widget.initialUpdateGateResult;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_updateGateResult.blocked) return;
    UpdateGateController().recheckLocalOnly(_updateGateResult).then((result) {
      if (mounted) setState(() => _updateGateResult = result);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_updateGateResult.blocked) {
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: ForceUpdateScreen(result: _updateGateResult),
      );
    }

    final channel = NativeChannel();
    final statusRepository = StatusRepository(channel);
    final downloadRepository = DownloadRepository(channel);
    final downloadsViewModel = DownloadsViewModel(downloadRepository);
    // Every successful download refreshes the gallery automatically.
    final homeViewModel = HomeViewModel(
        channel, statusRepository, downloadRepository, widget.settings,
        onMediaSaved: () => downloadsViewModel.refresh(silent: true));

    return MultiProvider(
      providers: [
        Provider.value(value: channel),
        Provider.value(value: statusRepository),
        Provider.value(value: downloadRepository),
        Provider(create: (_) => ShareService(channel)),
        ChangeNotifierProvider(create: (_) => SettingsViewModel(widget.settings)),
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
