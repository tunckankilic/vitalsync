import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitalsync/core/settings/settings_provider.dart';
import 'package:vitalsync/core/sync/sync_provider.dart';
import 'package:vitalsync/presentation/screens/gdpr/consent_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final themeMode = ref.watch(themeSettingProvider);
    final locale = ref.watch(localeSettingProvider);
    final notificationsEnabled = ref.watch(notificationSettingProvider);
    final unitSystem = ref.watch(unitSystemSettingProvider);

    // Sync state
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _SettingsSection(
            title: 'Appearance',
            children: [
              _SettingsTile(
                title: 'Theme',
                subtitle: _getThemeName(themeMode),
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
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                title: 'Language',
                subtitle: _getLanguageName(locale.languageCode),
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
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                    DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _SettingsSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
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

          // Units Section
          _SettingsSection(
            title: 'Units',
            children: [
              _SettingsTile(
                title: 'Unit System',
                subtitle: unitSystem == UnitSystem.metric
                    ? 'Metric (kg, cm)'
                    : 'Imperial (lbs, in)',
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
            title: 'Privacy & Data',
            children: [
              _SettingsTile(
                title: 'Manage Consents',
                subtitle: 'Update your GDPR privacy choices',
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
                title: 'Export Data',
                subtitle: 'Download a copy of your data',
                icon: Icons.download_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export started...')),
                  );
                },
              ),
              _SettingsTile(
                title: 'Delete Account',
                subtitle: 'Permanently delete your account and data',
                icon: Icons.delete_forever_outlined,
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                  _showDeleteConfirmation(context, ref);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sync Section
          _SettingsSection(
            title: 'Sync',
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
                title: const Text('Sync Status'),
                subtitle: Text(_getSyncStatusText(syncStatus)),
                trailing: TextButton(
                  onPressed: syncStatus == SyncStatus.syncing
                      ? null
                      : () {
                          ref.read(syncStatusProvider.notifier).triggerSync();
                        },
                  child: const Text('Sync Now'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About
          _SettingsSection(
            title: 'About',
            children: [
              const _SettingsTile(
                title: 'Version',
                subtitle: '1.0.0 (Build 100)',
                icon: Icons.info_outline,
              ),
              _SettingsTile(
                title: 'Open Source Licenses',
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

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'tr':
        return 'Türkçe';
      case 'de':
        return 'Deutsch';
      default:
        return code;
    }
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'Last synced recently';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.error:
        return 'Sync failed. Tap to retry.';
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion requested.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
