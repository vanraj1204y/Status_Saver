import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/update/update_gate_result.dart';

/// Full-screen, non-dismissible "update required" screen. No close/skip/
/// later button anywhere — the system back button is also blocked via
/// [PopScope]. Shown only when [UpdateGateResult.blocked] is true.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, required this.result});

  final UpdateGateResult result;

  Future<void> _openUpdateUrl(BuildContext context) async {
    final rawUrl = result.updateUrl;
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    var opened = false;
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Couldn't open the update link — please update from the Play Store."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = result.title.isEmpty ? 'Update Required' : result.title;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update_alt_rounded, size: 72),
                const SizedBox(height: 24),
                Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                if (result.message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(result.message, textAlign: TextAlign.center),
                ],
                if (result.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: result.releaseNotes
                          .map((note) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('•  '),
                                    Expanded(child: Text(note)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _openUpdateUrl(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Update App'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
