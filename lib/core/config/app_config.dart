/// Single source of truth for values baked in at build time via
/// `--dart-define-from-file=.env` (see build_release.cmd and the top-level
/// .env / .env.example). No other file in lib/ should call
/// `String.fromEnvironment`/`bool.fromEnvironment` directly.
///
/// App display name/version are intentionally NOT read here: the .env file
/// only drives the Android build (applicationId/versionCode/versionName/
/// appLabel, see android/app/build.gradle.kts) — the UI reads those back
/// from the real installed APK via `package_info_plus` instead, so they can
/// never drift from what's actually running.
class AppConfig {
  AppConfig._();

  /// This app's complete base URL on the shared update/legal-docs worker
  /// (already includes this app's path segment), e.g.
  /// `$updateApiBaseUrl/version.json`. See tool/fetch_legal_documents.dart.
  static const String updateApiBaseUrl = String.fromEnvironment(
    'UPDATE_API_BASE_URL',
    defaultValue: 'https://app-update-server.kolivanraj1204y.workers.dev/StatusNest',
  );

  /// Master kill switch for the force-update gate.
  static const bool forceUpdateEnabled = bool.fromEnvironment('FORCE_UPDATE_ENABLED', defaultValue: true);
}
