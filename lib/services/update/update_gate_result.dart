/// Outcome of [UpdateGateController.resolve]/[UpdateGateController.recheckLocalOnly].
/// Exactly two shapes: the app proceeds normally, or it's blocked behind a
/// full-screen, non-dismissible force-update screen — there is no
/// optional/soft/dismissible update tier in this gate.
class UpdateGateResult {
  const UpdateGateResult._({
    required this.blocked,
    this.minimumVersionCode = 0,
    this.minimumVersionName,
    this.forceUpdate = false,
    this.title = '',
    this.message = '',
    this.releaseNotes = const [],
    this.updateUrl,
  });

  final bool blocked;
  final int minimumVersionCode;
  final String? minimumVersionName;
  final bool forceUpdate;
  final String title;
  final String message;
  final List<String> releaseNotes;
  final String? updateUrl;

  factory UpdateGateResult.clear() => const UpdateGateResult._(blocked: false);

  factory UpdateGateResult.blocked({
    required int minimumVersionCode,
    String? minimumVersionName,
    required bool forceUpdate,
    required String title,
    required String message,
    required List<String> releaseNotes,
    required String? updateUrl,
  }) =>
      UpdateGateResult._(
        blocked: true,
        minimumVersionCode: minimumVersionCode,
        minimumVersionName: minimumVersionName,
        forceUpdate: forceUpdate,
        title: title,
        message: message,
        releaseNotes: releaseNotes,
        updateUrl: updateUrl,
      );
}
