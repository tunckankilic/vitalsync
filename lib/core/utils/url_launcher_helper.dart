/// VitalSync — External URL Launcher Helper.
///
/// Centralizes opening external links (privacy policy, terms, support) so the
/// launch + graceful failure handling lives in one place instead of being
/// duplicated at every call site.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

/// External-link launching utilities.
class UrlLauncherHelper {
  UrlLauncherHelper._();

  /// Opens [url] in the platform's default browser/app.
  ///
  /// On failure (malformed URL, no handler, or the page being unreachable) it
  /// does not throw: it shows a localized SnackBar so the user gets feedback
  /// instead of a silent no-op. Safe to call from a `StatelessWidget` —
  /// `context.mounted` is re-checked after the async gap.
  static Future<void> open(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.linkOpenError)));
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.linkOpenError)));
      }
    }
  }
}
