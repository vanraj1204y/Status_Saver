// Build-time-only script — NOT shipped in the app. Run before every release
// build (see build_release.cmd) to refresh assets/legal/*.html from the
// shared update/legal-docs worker, so the app can load them at runtime via
// loadFlutterAsset with zero network calls (see lib/core/config/legal_config.dart).
//
// This app deliberately never fetches legal docs at runtime: the worker
// might be down, slow, or (right now) not deployed yet at all. On any
// failure this script leaves whatever is already in assets/legal/ untouched,
// seeding it from the local legal/ source folder only the first time
// assets/legal/ has nothing in it — so a build never ships blank content.
//
// Run with: dart run tool/fetch_legal_documents.dart
import 'dart:io';

import 'package:http/http.dart' as http;

const _timeout = Duration(seconds: 20);

const _documents = [
  (name: 'privacy-policy', path: 'privacy-policy'),
  (name: 'terms', path: 'terms'),
];

Future<void> main() async {
  final env = _readEnvFile(File('.env'));
  final baseUrl = env['UPDATE_API_BASE_URL'];
  final slug = env['APP_SLUG'];

  final assetsDir = Directory('assets/legal');
  if (!assetsDir.existsSync()) assetsDir.createSync(recursive: true);

  for (final doc in _documents) {
    final assetFile = File('assets/legal/${doc.name}.html');
    final localSourceFile = File('legal/${doc.name}.html');

    if (baseUrl == null || baseUrl.isEmpty || slug == null || slug.isEmpty) {
      _seedFromLocalIfMissing(assetFile, localSourceFile, doc.name);
      continue;
    }

    final url = Uri.parse('$baseUrl/$slug/${doc.path}');
    try {
      final response = await http.get(url).timeout(_timeout);
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        assetFile.writeAsStringSync(response.body);
        stdout.writeln('[legal] fetched ${doc.name} from $url');
      } else {
        stdout.writeln('[legal] ${doc.name}: server returned ${response.statusCode}, keeping existing copy');
        _seedFromLocalIfMissing(assetFile, localSourceFile, doc.name);
      }
    } catch (e) {
      stdout.writeln('[legal] ${doc.name}: fetch failed ($e), keeping existing copy');
      _seedFromLocalIfMissing(assetFile, localSourceFile, doc.name);
    }
  }
}

/// Only seeds from the local placeholder when the shipped asset doesn't
/// exist yet at all — never overwrites a previously fetched (or previously
/// seeded) copy just because this run's fetch failed.
void _seedFromLocalIfMissing(File assetFile, File localSourceFile, String name) {
  if (assetFile.existsSync()) return;
  if (!localSourceFile.existsSync()) {
    stdout.writeln('[legal] $name: no existing asset and no local fallback at ${localSourceFile.path} — skipping');
    return;
  }
  assetFile.writeAsStringSync(localSourceFile.readAsStringSync());
  stdout.writeln('[legal] $name: seeded from ${localSourceFile.path}');
}

/// Minimal `KEY=value` line parser matching android/app/build.gradle.kts's
/// reader — `.env` uses `#` comments, which `Properties.load` mishandles.
Map<String, String> _readEnvFile(File file) {
  final result = <String, String>{};
  if (!file.existsSync()) return result;
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#') || !trimmed.contains('=')) continue;
    final index = trimmed.indexOf('=');
    result[trimmed.substring(0, index).trim()] = trimmed.substring(index + 1).trim();
  }
  return result;
}
