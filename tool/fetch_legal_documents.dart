// Build-time-only script — NOT shipped in the app. Run before every release
// build (see build_release.cmd) to refresh assets/legal/*.html from the
// shared update/legal-docs worker, so the app can load them at runtime via
// loadFlutterAsset with zero network calls (see lib/core/config/legal_config.dart).
//
// The worker is the single source of truth: there is no local placeholder
// folder to seed from. On any failure this script leaves whatever is
// already in assets/legal/ untouched and logs a warning instead of failing
// the build; if that asset doesn't exist yet either, it logs a clear
// warning and skips it.
//
// Run with: dart run tool/fetch_legal_documents.dart
import 'dart:convert';
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

  final assetsDir = Directory('assets/legal');
  if (!assetsDir.existsSync()) assetsDir.createSync(recursive: true);

  for (final doc in _documents) {
    final assetFile = File('assets/legal/${doc.name}.html');

    if (baseUrl == null || baseUrl.isEmpty) {
      _warnIfMissing(assetFile, doc.name);
      continue;
    }

    final url = Uri.parse('$baseUrl/${doc.path}');
    try {
      final response = await http.get(url).timeout(_timeout);
      // Decode as UTF-8 explicitly: the worker doesn't always declare a
      // charset, and http's default (Latin-1) mangles multi-byte
      // characters like em/en dashes into mojibake/box glyphs.
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200 && body.trim().isNotEmpty) {
        assetFile.writeAsStringSync(body, encoding: utf8);
        stdout.writeln('[legal] fetched ${doc.name} from $url');
      } else {
        stdout.writeln('[legal] ${doc.name}: server returned ${response.statusCode}, keeping existing copy');
        _warnIfMissing(assetFile, doc.name);
      }
    } catch (e) {
      stdout.writeln('[legal] ${doc.name}: fetch failed ($e), keeping existing copy');
      _warnIfMissing(assetFile, doc.name);
    }
  }
}

/// Logs a clear warning when a fetch failed and there is no previously
/// fetched asset to fall back to — never fails the build.
void _warnIfMissing(File assetFile, String name) {
  if (assetFile.existsSync()) return;
  stdout.writeln('[legal] WARNING: $name could not be fetched and no existing asset at ${assetFile.path} — this build will ship without it.');
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
