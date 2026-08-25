import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/di/injection_container.dart';
import 'package:vitalsync/core/gdpr/gdpr_manager.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/network/connectivity_service.dart';
import 'package:vitalsync/core/settings/settings_provider.dart';
import 'package:vitalsync/core/sync/sync_provider.dart';
import 'package:vitalsync/core/utils/url_launcher_helper.dart';
import 'package:vitalsync/presentation/screens/gdpr/consent_screen.dart'
    show gdprManagerProvider;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Watch providers
    final themeMode = ref.watch(themeSettingProvider);
    final locale = ref.watch(localeSettingProvider);
    final notificationsEnabled = ref.watch(notificationSettingProvider);
    final postMealReminderEnabled = ref.watch(postMealReminderSettingProvider);
    final unitSystem = ref.watch(unitSystemSettingProvider);

    final calibrationMetricsConsent =
        ref.watch(gdprConsentSettingProvider)[AppConstants
            .gdprConsentTypeCalibrationMetrics] ??
        false;

    // Sync state
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _SettingsSection(
            title: l10n.appearance,
            children: [
              _SettingsTile(
                title: l10n.theme,
                subtitle: _getThemeName(themeMode, l10n),
                icon: Icons.brightness_6_outlined,
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  underline: const SizedBox(),
                  onChanged: (ThemeMode? newMode) {
                    if (newMode != null) {
                      ref
                          .read(themeSettingProvider.notifier)
                          .setThemeMode(newMode);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(l10n.themeSystem),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l10n.themeLight),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l10n.themeDark),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                title: l10n.materialYou,
                subtitle: l10n.materialYouSubtitle,
                icon: Icons.palette_outlined,
                trailing: Switch(
                  value: ref.watch(materialYouSettingProvider),
                  activeThumbColor: Theme.of(context).primaryColor,
                  activeTrackColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.5),
                  onChanged: (val) {
                    ref
                        .read(materialYouSettingProvider.notifier)
                        .setEnabled(val);
                  },
                ),
              ),
              _SettingsTile(
                title: l10n.language,
                subtitle: _getLanguageName(locale.languageCode, l10n),
                icon: Icons.language_outlined,
                trailing: DropdownButton<String>(
                  value: locale.languageCode,
                  underline: const SizedBox(),
                  onChanged: (String? newCode) {
                    if (newCode != null) {
                      ref
                          .read(localeSettingProvider.notifier)
                          .setLocale(Locale(newCode));
                    }
                  },
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.languageEn)),
                    DropdownMenuItem(value: 'tr', child: Text(l10n.languageTr)),
                    DropdownMenuItem(value: 'de', child: Text(l10n.languageDe)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _SettingsSection(
            title: l10n.notifications,
            children: [
              SwitchListTile(
                title: Text(l10n.enableNotifications),
                secondary: const Icon(Icons.notifications_outlined),
                value: notificationsEnabled,
                onChanged: (val) {
                  ref
                      .read(notificationSettingProvider.notifier)
                      .setEnabled(val);
                },
                activeThumbColor: Theme.of(context).primaryColor,
                activeTrackColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.5),
              ),
              // Time-triggered only: it asks for a measurement a fixed
              // interval after a logged meal and says nothing about one.
              // Disabled while notifications are off as a whole.
              SwitchListTile(
                title: Text(l10n.postMealReminderSetting),
                subtitle: Text(l10n.postMealReminderSettingSubtitle),
                secondary: const Icon(Icons.water_drop_outlined),
                value: postMealReminderEnabled && notificationsEnabled,
                onChanged: notificationsEnabled
                    ? (val) {
                        ref
                            .read(postMealReminderSettingProvider.notifier)
                            .setEnabled(val);
                      }
                    : null,
                activeThumbColor: Theme.of(context).primaryColor,
                activeTrackColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.5),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Units Section
          _SettingsSection(
            title: l10n.units,
            children: [
              _SettingsTile(
                title: l10n.unitSystem,
                subtitle: unitSystem == UnitSystem.metric
                    ? l10n.unitMetric
                    : l10n.unitImperial,
                icon: Icons.scale_outlined,
                trailing: Switch(
                  value: unitSystem == UnitSystem.metric,
                  activeThumbColor: Theme.of(context).primaryColor,
                  activeTrackColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.5),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.withValues(alpha: 0.5),
                  onChanged: (val) {
                    ref
                        .read(unitSystemSettingProvider.notifier)
                        .setUnitSystem(
                          val ? UnitSystem.metric : UnitSystem.imperial,
                        );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Privacy & Data
          _SettingsSection(
            title: l10n.privacyData,
            children: [
              _SettingsTile(
                title: l10n.healthDisclaimerTitle,
                subtitle: l10n.healthDisclaimerSubtitle,
                icon: Icons.health_and_safety_outlined,
                onTap: () => _showHealthDisclaimer(context, l10n),
              ),
              _SettingsTile(
                title: l10n.healthSources,
                subtitle: l10n.healthSourcesSubtitle,
                icon: Icons.favorite_outline_rounded,
                onTap: () {
                  context.pushNamed('health_sources');
                },
              ),
              // Opt-in, off unless the user turns it on. While it is off no
              // calibration metrics row is produced at all.
              _SettingsTile(
                title: l10n.calibrationMetrics,
                subtitle: l10n.calibrationMetricsSubtitle,
                icon: Icons.insights_outlined,
                onTap: () => _showCalibrationMetricsInfo(context, l10n),
                trailing: Switch(
                  value: calibrationMetricsConsent,
                  activeThumbColor: Theme.of(context).primaryColor,
                  activeTrackColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.5),
                  onChanged: (granted) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final manager = ref.read(gdprManagerProvider);
                    if (granted) {
                      await manager.grantConsent(
                        AppConstants.gdprConsentTypeCalibrationMetrics,
                      );
                    } else {
                      await manager.revokeConsent(
                        AppConstants.gdprConsentTypeCalibrationMetrics,
                      );
                    }
                    ref.invalidate(gdprConsentSettingProvider);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? l10n.calibrationMetricsEnabled
                              : l10n.calibrationMetricsDisabled,
                        ),
                      ),
                    );
                  },
                ),
              ),
              _SettingsTile(
                title: l10n.manageConsents,
                subtitle: l10n.manageConsentsSubtitle,
                icon: Icons.shield_outlined,
                onTap: () {
                  context.pushNamed('gdpr_consent');
                },
              ),
              _SettingsTile(
                title: l10n.exportData,
                subtitle: l10n.exportDataSubtitle,
                icon: Icons.download_outlined,
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.exportStarted)));
                },
              ),
              _SettingsTile(
                title: l10n.deleteAccount,
                subtitle: l10n.deleteAccountSubtitle,
                icon: Icons.delete_forever_outlined,
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                  _showDeleteConfirmation(context, ref, l10n);
                },
              ),
              _SettingsTile(
                title: l10n.privacyPolicy,
                subtitle: l10n.privacyPolicySubtitle,
                icon: Icons.privacy_tip_outlined,
                onTap: () => UrlLauncherHelper.open(
                  context,
                  AppConstants.privacyPolicyUrl,
                ),
              ),
              _SettingsTile(
                title: l10n.termsOfService,
                subtitle: l10n.termsOfServiceSubtitle,
                icon: Icons.description_outlined,
                onTap: () => UrlLauncherHelper.open(
                  context,
                  AppConstants.termsOfServiceUrl,
                ),
              ),
              _SettingsTile(
                title: l10n.support,
                subtitle: l10n.supportSubtitle,
                icon: Icons.help_outline,
                onTap: () =>
                    UrlLauncherHelper.open(context, AppConstants.supportUrl),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sync Section
          _SettingsSection(
            title: l10n.sync,
            children: [
              ListTile(
                leading:
                    Icon(
                          syncStatus == SyncStatus.syncing
                              ? Icons.sync
                              : Icons.cloud_done_outlined,
                          color: syncStatus == SyncStatus.error
                              ? Colors.red
                              : Colors.blue,
                        )
                        .animate(
                          target: syncStatus == SyncStatus.syncing ? 1 : 0,
                        )
                        .rotate(duration: 1.seconds, curve: Curves.linear),
                title: Text(l10n.syncStatus),
                subtitle: Text(_getSyncStatusText(syncStatus, l10n)),
                trailing: TextButton(
                  onPressed: syncStatus == SyncStatus.syncing
                      ? null
                      : () async {
                          // Mirror SyncService.sync()'s silent guards so the
                          // button tells the user why a manual sync did nothing
                          // (it used to be a silent no-op). Capture the messenger
                          // before any await to stay off context across gaps.
                          final messenger = ScaffoldMessenger.of(context);

                          final consents = ref.read(gdprConsentSettingProvider);
                          if (!(consents[AppConstants
                                  .gdprConsentTypeCloudBackup] ??
                              false)) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.syncNeedsCloudConsent),
                              ),
                            );
                            return;
                          }

                          if (ref.read(authRepositoryProvider).currentUser ==
                              null) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.syncNeedsSignIn)),
                            );
                            return;
                          }

                          if (!await ref
                              .read(connectivityServiceProvider)
                              .isConnected()) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.syncOfflineTooltip)),
                            );
                            return;
                          }

                          try {
                            await ref
                                .read(syncStatusProvider.notifier)
                                .triggerSync();
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.syncCompleted)),
                            );
                          } catch (_) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.syncFailed)),
                            );
                          }
                        },
                  child: Text(l10n.syncNow),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About
          _SettingsSection(
            title: l10n.about,
            children: [
              _SettingsTile(
                title: l10n.version,
                subtitle: '1.0.0 (Build 100)',
                icon: Icons.info_outline,
              ),
              _SettingsTile(
                title: l10n.licenses,
                icon: Icons.description_outlined,
                onTap: () => showLicensePage(context: context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Log Out — placed at the bottom and visually distinct (red) so it's
          // easy to find; this is the conventional spot users look for it.
          OutlinedButton.icon(
            onPressed: () => _confirmAndSignOut(context, ref, l10n),
            icon: const Icon(Icons.logout),
            label: Text(l10n.logOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  /// Confirms, then signs out. The auth-state stream drives the GoRouter
  /// redirect back to /auth/login, so no manual navigation is needed (same
  /// pattern as [_performAccountDeletion]). The messenger is captured before
  /// the await so an error can still be surfaced after teardown.
  Future<void> _confirmAndSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logOutConfirmTitle),
        content: Text(l10n.logOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(authProvider.notifier).signOut();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric(e))));
    }
  }

  String _getThemeName(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.themeSystem;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }

  String _getLanguageName(String code, AppLocalizations l10n) {
    switch (code) {
      case 'en':
        return l10n.languageEn;
      case 'tr':
        return l10n.languageTr;
      case 'de':
        return l10n.languageDe;
      default:
        return code;
    }
  }

  String _getSyncStatusText(SyncStatus status, AppLocalizations l10n) {
    switch (status) {
      case SyncStatus.idle:
        return l10n.syncIdle;
      case SyncStatus.syncing:
        return l10n.syncing; // Existing
      case SyncStatus.error:
        return l10n.syncError;
    }
  }

  void _showHealthDisclaimer(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.healthDisclaimerTitle),
        content: SingleChildScrollView(child: Text(l10n.healthDisclaimerBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.understood),
          ),
        ],
      ),
    );
  }

  /// Explains exactly what the opt-in counters send.
  ///
  /// The wording never calls the data anonymous: it is stored under the
  /// user's own Cognito partition, so it is tied to their account.
  void _showCalibrationMetricsInfo(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.calibrationMetrics),
        content: SingleChildScrollView(
          child: Text(l10n.calibrationMetricsConsentBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.understood),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountDialogTitle),
        content: Text(l10n.deleteAccountDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel), // Existing
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // close the confirm dialog
              // Use the screen context (still mounted) for the deletion flow.
              _performAccountDeletion(context, l10n);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete), // Existing
          ),
        ],
      ),
    );
  }

  /// Runs the GDPR right-to-erasure flow: wipes cloud + local data and deletes
  /// the account, then lets the auth-state redirect return the user to login.
  ///
  /// Deletion must reach the server, so connectivity is required up front —
  /// otherwise we could delete the account while server-side health data
  /// remains. Failures are reported to crash reporting (Sentry) and surfaced
  /// to the user; they are never silently swallowed.
  Future<void> _performAccountDeletion(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final online = await getIt<ConnectivityService>().isConnected();
    if (!online) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountOnlineRequired)),
      );
      return;
    }
    if (!context.mounted) return;

    // Blocking progress on the root navigator — it survives the post-delete
    // redirect to login, and we dismiss it explicitly below.
    final navigator = Navigator.of(context, rootNavigator: true);
    // Not awaited: the dialog stays up until we pop it after the delete call.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      await getIt<GDPRManager>().deleteAllUserData();
      // Success: the `userDeleted` auth event drives the router to /auth/login.
      navigator.pop(); // dismiss the progress dialog
    } catch (e, stack) {
      navigator.pop(); // dismiss the progress dialog
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'settings.deleteAccount',
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleteAccountFailed)));
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // Transparent Material so the ListTiles inside have a proper Material
          // ancestor for their background/ink. Without it the coloured
          // BoxDecoration above is the nearest painted surface and Flutter warns
          // "ListTile background color or ink splashes may be invisible".
          child: Material(
            type: MaterialType.transparency,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.textColor,
    this.iconColor,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: iconColor ?? Colors.grey[700])
          : null,
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                )
              : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
