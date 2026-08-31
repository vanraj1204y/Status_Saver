import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/version_check_result.dart';

/// Persists the last successful `version.json` check so the force-update
/// gate can rebuild the exact same decision on days the network check is
/// skipped (throttled to once per local calendar day) or fails outright.
class UpdateRepository {
  UpdateRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _lastCheckDateKey = 'update_last_check_date';
  static const _lastResultKey = 'update_last_result_json';

  /// `YYYY-MM-DD` for the device's local calendar day.
  String todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  bool checkedToday() => _prefs.getString(_lastCheckDateKey) == todayKey();

  /// Only advances the stored date on a SUCCESSFUL check — a failed/timed-out
  /// fetch must never mark today as checked, so the very next launch retries.
  Future<void> saveSuccessfulCheck(VersionCheckResult result) async {
    await _prefs.setString(_lastCheckDateKey, todayKey());
    await _prefs.setString(_lastResultKey, jsonEncode(result.toJson()));
  }

  VersionCheckResult? loadPersistedResult() {
    final raw = _prefs.getString(_lastResultKey);
    if (raw == null) return null;
    try {
      return VersionCheckResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
