import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/update_config.dart';
import '../../models/version_check_result.dart';
import '../update_repository.dart';
import 'update_check_service.dart';
import 'update_gate_result.dart';

/// Orchestrates the force-update decision. Called once at app bootstrap
/// ([resolve]) and again on resume while blocked ([recheckLocalOnly]) — see
/// lib/main.dart.
///
/// A flaky/not-yet-deployed backend never wrongly blocks OR wrongly clears:
/// on a failed fetch this repeats whatever was last known (nothing known yet
/// == clear()).
class UpdateGateController {
  UpdateGateController({UpdateCheckService? checkService}) : _checkService = checkService ?? UpdateCheckService();

  final UpdateCheckService _checkService;

  Future<UpdateGateResult> resolve() async {
    if (!UpdateConfig.forceUpdateEnabled) return UpdateGateResult.clear();

    final packageInfo = await PackageInfo.fromPlatform();
    final installedVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
    final installedVersionName = packageInfo.version;

    final prefs = await SharedPreferences.getInstance();
    final repository = UpdateRepository(prefs);
    var persisted = repository.loadPersistedResult();

    if (!repository.checkedToday()) {
      final fresh = await _checkService.check();
      if (fresh != null) {
        await repository.saveSuccessfulCheck(fresh);
        persisted = fresh;
        return _decide(fresh, installedVersionCode, installedVersionName);
      }
      // Fetch failed — fall through and use whatever was already persisted.
    }

    if (persisted == null) return UpdateGateResult.clear();
    return _decide(persisted, installedVersionCode, installedVersionName);
  }

  /// Re-evaluates ONLY the local installed version (no network) against the
  /// already-blocked result's fields — e.g. the user went to the Play Store
  /// and came back without a full relaunch.
  Future<UpdateGateResult> recheckLocalOnly(UpdateGateResult current) async {
    if (!current.blocked) return current;

    final packageInfo = await PackageInfo.fromPlatform();
    final installedVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
    final installedVersionName = packageInfo.version;

    final stillBlocked = shouldForceUpdate(
      forceUpdate: current.forceUpdate,
      installedVersionCode: installedVersionCode,
      minimumVersionCode: current.minimumVersionCode,
      installedVersionName: installedVersionName,
      minimumVersionName: current.minimumVersionName,
    );
    if (stillBlocked) return current;
    return UpdateGateResult.clear();
  }

  UpdateGateResult _decide(VersionCheckResult result, int installedVersionCode, String installedVersionName) {
    final blocked = shouldForceUpdate(
      forceUpdate: result.forceUpdate,
      installedVersionCode: installedVersionCode,
      minimumVersionCode: result.minimumVersionCode,
      installedVersionName: installedVersionName,
      minimumVersionName: result.minimumVersionName,
    );
    if (!blocked) return UpdateGateResult.clear();
    return UpdateGateResult.blocked(
      minimumVersionCode: result.minimumVersionCode,
      minimumVersionName: result.minimumVersionName,
      forceUpdate: result.forceUpdate,
      title: result.title,
      message: result.message,
      releaseNotes: result.releaseNotes,
      updateUrl: result.updateUrl,
    );
  }
}
