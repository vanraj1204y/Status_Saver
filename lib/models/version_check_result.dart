/// Parsed response from the shared update worker's `version.json`. Only
/// [minimumVersionCode] is required — any other structural problem in the
/// payload means [tryParse] returns null (fail safe: a malformed response
/// must never accidentally force-block everyone).
class VersionCheckResult {
  const VersionCheckResult({
    required this.minimumVersionCode,
    this.minimumVersionName,
    this.latestVersionCode,
    this.latestVersionName,
    required this.forceUpdate,
    this.updateUrl,
    this.title = '',
    this.message = '',
    this.releaseNotes = const [],
  });

  final int minimumVersionCode;
  final String? minimumVersionName;
  final int? latestVersionCode;
  final String? latestVersionName;
  final bool forceUpdate;
  final String? updateUrl;
  final String title;
  final String message;
  final List<String> releaseNotes;

  static VersionCheckResult? tryParse(Object? json) {
    if (json is! Map) return null;
    final minimumVersionCode = json['minimumVersionCode'];
    if (minimumVersionCode is! int) return null;

    return VersionCheckResult(
      minimumVersionCode: minimumVersionCode,
      minimumVersionName: json['minimumVersionName'] is String ? json['minimumVersionName'] as String : null,
      latestVersionCode: json['latestVersionCode'] is int ? json['latestVersionCode'] as int : null,
      latestVersionName: json['latestVersionName'] is String ? json['latestVersionName'] as String : null,
      forceUpdate: json['forceUpdate'] == true,
      updateUrl: _tryParseHttpUri(json['updateUrl']),
      title: json['title'] is String ? json['title'] as String : '',
      message: json['message'] is String ? json['message'] as String : '',
      releaseNotes: json['releaseNotes'] is List
          ? (json['releaseNotes'] as List).whereType<String>().toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'minimumVersionCode': minimumVersionCode,
        'minimumVersionName': minimumVersionName,
        'latestVersionCode': latestVersionCode,
        'latestVersionName': latestVersionName,
        'forceUpdate': forceUpdate,
        'updateUrl': updateUrl,
        'title': title,
        'message': message,
        'releaseNotes': releaseNotes,
      };

  static VersionCheckResult fromJson(Map<String, dynamic> json) =>
      VersionCheckResult(
        minimumVersionCode: json['minimumVersionCode'] as int,
        minimumVersionName: json['minimumVersionName'] as String?,
        latestVersionCode: json['latestVersionCode'] as int?,
        latestVersionName: json['latestVersionName'] as String?,
        forceUpdate: json['forceUpdate'] as bool? ?? false,
        updateUrl: json['updateUrl'] as String?,
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        releaseNotes: (json['releaseNotes'] as List?)?.whereType<String>().toList() ?? const [],
      );

  static String? _tryParseHttpUri(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.isScheme('http') && !uri.isScheme('https')) return null;
    return value;
  }
}

/// True when the installed app must be blocked behind the force-update
/// screen. The integer versionCode compare is the primary signal;
/// [minimumVersionName] is only a defense-in-depth fallback.
bool shouldForceUpdate({
  required bool forceUpdate,
  required int installedVersionCode,
  required int minimumVersionCode,
  required String installedVersionName,
  String? minimumVersionName,
}) {
  if (!forceUpdate) return false;
  if (installedVersionCode < minimumVersionCode) return true;
  if (minimumVersionName != null) {
    final cmp = compareVersionNames(installedVersionName, minimumVersionName);
    if (cmp != null && cmp < 0) return true;
  }
  return false;
}

/// Dotted-integer version compare (e.g. "1.0.10" > "1.0.9"). Returns null —
/// "skip this check" — if either string has a non-numeric segment. No
/// semver pre-release/build-metadata support.
int? compareVersionNames(String a, String b) {
  final partsA = a.split('.').map(int.tryParse).toList();
  final partsB = b.split('.').map(int.tryParse).toList();
  if (partsA.contains(null) || partsB.contains(null)) return null;

  final length = partsA.length > partsB.length ? partsA.length : partsB.length;
  for (var i = 0; i < length; i++) {
    final valueA = i < partsA.length ? partsA[i]! : 0;
    final valueB = i < partsB.length ? partsB[i]! : 0;
    if (valueA != valueB) return valueA.compareTo(valueB);
  }
  return 0;
}
