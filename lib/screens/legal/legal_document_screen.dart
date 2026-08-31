import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Shows a bundled legal HTML asset (privacy policy / terms of use) via
/// `loadFlutterAsset` with JavaScript disabled — never a live URL, so this
/// screen makes zero network requests. See lib/core/config/legal_config.dart.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.title, required this.assetPath});

  final String title;
  final String assetPath;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.disabled)
    ..setNavigationDelegate(
      NavigationDelegate(onNavigationRequest: _onNavigationRequest),
    )
    ..loadFlutterAsset(widget.assetPath);

  // The initial `loadFlutterAsset` load is itself a navigation request too,
  // always either http(s) to the local asset-loader domain or a bare file://
  // URL depending on engine version — a scheme that loader could never
  // produce (mailto/tel, or an http(s) link to a real external host) is a
  // link the user actually tapped inside the document.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    final isExternalLink = uri != null &&
        (uri.scheme == 'mailto' ||
            uri.scheme == 'tel' ||
            ((uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.host != 'appassets.androidplatform.net'));
    if (!isExternalLink) return NavigationDecision.navigate;
    unawaited(_openExternally(uri));
    return NavigationDecision.prevent;
  }

  Future<void> _openExternally(Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open $uri')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
