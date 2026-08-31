import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/update_config.dart';
import '../../models/version_check_result.dart';

/// Fetches and parses `version.json` from the shared update worker. Never
/// throws — any network error, non-200 status, timeout, or malformed body
/// returns null so the caller can safely fall back to the last known state.
class UpdateCheckService {
  Future<VersionCheckResult?> check() async {
    try {
      final response = await http.get(Uri.parse(UpdateConfig.updateCheckUrl)).timeout(UpdateConfig.updateCheckTimeout);
      if (response.statusCode != 200) return null;
      return VersionCheckResult.tryParse(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }
}
