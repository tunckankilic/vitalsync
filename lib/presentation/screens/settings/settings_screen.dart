import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/settings/settings_provider.dart';
import 'package:vitalsync/core/sync/sync_provider.dart';
import 'package:vitalsync/presentation/screens/gdpr/consent_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Watch providers
    final themeMode = ref.watch(themeSettingProvider);
    final locale = ref.watch(localeSettingProvider);
    final notificationsEnabled = ref.watch(notificationSettingProvider);
    final unitSystem = ref.watch(unitSystemSettingProvider);

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
            ],
          ),

          const SizedBox(height: 24),

          // Security Section
          _SettingsSection(
            title: l10n.security,
            children: [
              SwitchListTile(
                title: Text(l10n.biometricLogin),
                subtitle: Text(l10n.biometricLoginDescription),
                secondary: const Icon(Icons.fingerprint),
                value: ref.watch(biometricSettingProvider),
                onChanged: (val) {
                  ref
                      .read(biometricSettingProvider.notifier)
                      .setEnabled(val);
                },
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
                title: l10n.manageConsents,
                subtitle: l10n.manageConsentsSubtitle,
                icon: Icons.shield_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ConsentScreen(isOnboarding: false),
                    ),
                  );
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
                      : () {
                          ref.read(syncStatusProvider.notifier).triggerSync();
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

          const SizedBox(height: 48),
        ],
      ),
    );
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

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountDialogTitle),
        content: Text(l10n.deleteAccountDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel), // Existing
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.deleteAccountRequested)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete), // Existing
          ),
        ],
      ),
    );
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
          child: Column(children: children),
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
