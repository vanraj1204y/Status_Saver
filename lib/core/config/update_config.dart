import 'app_config.dart';

/// Force-update version-gate config. See lib/services/update/update_gate_controller.dart
/// for how [updateCheckUrl] is used and lib/services/update_repository.dart
/// for the once-per-day throttle.
class UpdateConfig {
  UpdateConfig._();

  static const String updateCheckUrl = '${AppConfig.updateApiBaseUrl}/${AppConfig.appSlug}/version.json';

  static const bool forceUpdateEnabled = AppConfig.forceUpdateEnabled;

  static const Duration updateCheckTimeout = Duration(seconds: 12);
}
