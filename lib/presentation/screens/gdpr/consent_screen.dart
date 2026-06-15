import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/di/injection_container.dart';
import 'package:vitalsync/core/gdpr/gdpr_manager.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/settings/settings_provider.dart';
import 'package:vitalsync/core/utils/url_launcher_helper.dart';

/// Exposes the singleton [GDPRManager] through Riverpod so the consent screen's
/// writes can be overridden in widget tests (the rest of the app may keep using
/// `getIt<GDPRManager>()` directly).
final gdprManagerProvider = Provider<GDPRManager>(
  (ref) => getIt<GDPRManager>(),
);

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key, this.isOnboarding = false});
  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).privacyAndData),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(child: ConsentContent(isOnboarding: isOnboarding)),
    );
  }
}

class ConsentContent extends ConsumerWidget {
  const ConsentContent({super.key, required this.isOnboarding});
  final bool isOnboarding;

  /// Persists a consent change through [GDPRManager] — this writes the same
  /// SharedPreferences key the rest of the app (including sync) reads AND
  /// appends the timestamped audit entry. The reactive provider is refreshed
  /// once the write completes. The previous in-memory notifiers never persisted,
  /// so e.g. Cloud Backup could never actually be enabled and sync stayed
  /// blocked.
  void _persistConsent(WidgetRef ref, String type, {required bool granted}) {
    final manager = ref.read(gdprManagerProvider);
    final write = granted
        ? manager.grantConsent(type)
        : manager.revokeConsent(type);
    write.then((_) => ref.invalidate(gdprConsentSettingProvider));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the persisted consent map so the toggles reflect — and write to —
    // the store sync and the rest of the app actually use.
    final consents = ref.watch(gdprConsentSettingProvider);
    final analyticsConsent =
        consents[AppConstants.gdprConsentTypeAnalytics] ?? false;
    final healthConsent =
        consents[AppConstants.gdprConsentTypeHealthData] ?? false;
    final fitnessConsent =
        consents[AppConstants.gdprConsentTypeFitnessData] ?? false;
    final cloudConsent =
        consents[AppConstants.gdprConsentTypeCloudBackup] ?? false;
    final l10n = AppLocalizations.of(context);

    // Form logic: Check if required consents are given
    final canProceed = healthConsent && fitnessConsent;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOnboarding) ...[
            const Icon(Icons.shield_outlined, size: 48, color: Colors.indigo),
            const SizedBox(height: 16),
            Text(
              l10n.privacyTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ).animate().fadeIn().moveY(begin: 10, end: 0),
            const SizedBox(height: 8),
            Text(
              l10n.privacySubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
          ],

          Expanded(
            child: ListView(
              children: [
                _ConsentCard(
                  title: l10n.consentHealthTitle,
                  description: l10n.consentHealthDescription,
                  isRequired: true,
                  value: healthConsent,
                  onChanged: (val) {
                    if (!val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.consentRequiredMessage(l10n.health),
                          ),
                        ),
                      );
                      return;
                    }
                    _persistConsent(
                      ref,
                      AppConstants.gdprConsentTypeHealthData,
                      granted: val,
                    );
                  },
                  icon: Icons.medical_services_outlined,
                ),
                _ConsentCard(
                  title: l10n.consentFitnessTitle,
                  description: l10n.consentFitnessDescription,
                  isRequired: true,
                  value: fitnessConsent,
                  onChanged: (val) {
                    if (!val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.consentRequiredMessage(l10n.fitness),
                          ),
                        ),
                      );
                      return;
                    }
                    _persistConsent(
                      ref,
                      AppConstants.gdprConsentTypeFitnessData,
                      granted: val,
                    );
                  },
                  icon: Icons.fitness_center_outlined,
                ),
                _ConsentCard(
                  title: l10n.consentAnalyticsTitle,
                  description: l10n.consentAnalyticsDescription,
                  isRequired: false,
                  value: analyticsConsent,
                  onChanged: (val) => _persistConsent(
                    ref,
                    AppConstants.gdprConsentTypeAnalytics,
                    granted: val,
                  ),
                  icon: Icons.analytics_outlined,
                ),
                _ConsentCard(
                  title: l10n.consentBackupTitle,
                  description: l10n.consentBackupDescription,
                  isRequired: false,
                  value: cloudConsent,
                  onChanged: (val) => _persistConsent(
                    ref,
                    AppConstants.gdprConsentTypeCloudBackup,
                    granted: val,
                  ),
                  icon: Icons.cloud_upload_outlined,
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => UrlLauncherHelper.open(
                      context,
                      AppConstants.privacyPolicyUrl,
                    ),
                    child: Text(l10n.readPrivacyPolicy),
                  ),
                ),
              ],
            ),
          ),

          if (isOnboarding)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canProceed
                    ? () {
                        // Save consents and navigate
                        context.go('/auth/login');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(l10n.acceptContinue),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.title,
    required this.description,
    required this.isRequired,
    required this.value,
    required this.onChanged,
    required this.icon,
  });
  final String title;
  final String description;
  final bool isRequired;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      color: Colors.white.withValues(alpha: 0.8), // Glass-ish
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isRequired)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            l10n.requiredTag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: isRequired && value ? onChanged : onChanged,
              activeThumbColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
