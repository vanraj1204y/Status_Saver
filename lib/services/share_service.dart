import '../app/strings.dart';
import '../models/status_media.dart';
import 'native_channel.dart';

enum ShareOutcome { ok, whatsappMissingFellBack, failed, noApp }

/// Wraps the native Android share sheet and direct-to-WhatsApp sending.
class ShareService {
  ShareService(this._channel);

  final NativeChannel _channel;
  static const _whatsappPackage = 'com.whatsapp';

  Future<ShareOutcome> share(StatusMedia media, {String? resolvedPath}) async {
    final result = await _channel.shareMedia(
      path: resolvedPath ?? media.path,
      uri: media.uri,
      mime: media.mimeType,
      title: AppStrings.share,
    );
    return result == 'ok' ? ShareOutcome.ok : ShareOutcome.failed;
  }

  /// Sends directly to WhatsApp when installed; otherwise falls back to the
  /// system share sheet so the user can still share the media.
  Future<ShareOutcome> sendToWhatsApp(StatusMedia media, {String? resolvedPath}) async {
    final result = await _channel.shareMedia(
      path: resolvedPath ?? media.path,
      uri: media.uri,
      mime: media.mimeType,
      targetPackage: _whatsappPackage,
      title: AppStrings.share,
    );
    switch (result) {
      case 'ok':
        return ShareOutcome.ok;
      case 'not_installed':
      case 'no_app':
        final fallback = await share(media, resolvedPath: resolvedPath);
        return fallback == ShareOutcome.ok
            ? ShareOutcome.whatsappMissingFellBack
            : ShareOutcome.failed;
      default:
        return ShareOutcome.failed;
    }
  }

  /// Opens WhatsApp's Status composer with the media pre-loaded, so the
  /// user only has to tap WhatsApp's own Send button. Falls back to the
  /// chat-forward share when WhatsApp isn't installed or doesn't support
  /// the status intent on this device.
  Future<ShareOutcome> sendToWhatsAppStatus(StatusMedia media, {String? resolvedPath}) async {
    final result = await _channel.shareToWhatsAppStatus(
      path: resolvedPath ?? media.path,
      uri: media.uri,
      mime: media.mimeType,
    );
    switch (result) {
      case 'ok':
        return ShareOutcome.ok;
      case 'not_installed':
      case 'no_app':
        final fallback = await sendToWhatsApp(media, resolvedPath: resolvedPath);
        return fallback == ShareOutcome.ok
            ? ShareOutcome.whatsappMissingFellBack
            : fallback;
      default:
        return ShareOutcome.failed;
    }
  }

  Future<ShareOutcome> open(StatusMedia media, {String? resolvedPath}) async {
    final result = await _channel.openMedia(
      path: resolvedPath ?? media.path,
      uri: media.uri,
      mime: media.mimeType,
    );
    return switch (result) {
      'ok' => ShareOutcome.ok,
      'no_app' => ShareOutcome.noApp,
      _ => ShareOutcome.failed,
    };
  }
}
