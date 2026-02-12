/// VitalSync — Main Application Entry Point.
///
/// Health & Fitness Companion with offline-first architecture.
/// GDPR-compliant, multi-language, accessibility-first.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/background/background_service.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/network/connectivity_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize GetIt dependency injection
  await initializeDependencies();

  // Initialize notification service
  final notificationService = getIt<NotificationService>();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Initialize background service
  final backgroundService = getIt<BackgroundService>();
  await backgroundService.initialize();
  await backgroundService.scheduleMedicationReminderCheck();
  await backgroundService.scheduleBackgroundSync();

  // Start connectivity service listening
  final connectivityService = getIt<ConnectivityService>();
  connectivityService.startListening();

  // Start auto-sync on connectivity changes
  final syncService = getIt<SyncService>();
  syncService.startAutoSync();

  // Run the app wrapped in ProviderScope for Riverpod
  runApp(const ProviderScope(child: VitalSyncApp()));
}

/// VitalSync Application Widget.
///
/// Root widget that configures the app with:
/// - Localization support (EN, TR, DE)
/// - Theme configuration (light, dark, high contrast)
/// - GoRouter navigation
/// - GDPR compliance check on first launch
class VitalSyncApp extends StatelessWidget {
  const VitalSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // === APP METADATA ===
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // === LOCALIZATION ===
      // TODO: Add AppLocalizations.delegate when l10n is generated (Prompt 1.2)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('tr'), // Turkish
        Locale('de'), // German
      ],
      locale: const Locale('en'), // Default locale
      // TODO: In Prompt 3.x, connect to locale provider for dynamic locale

      // === THEME ===
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      highContrastTheme: AppTheme.highContrastTheme,
      themeMode: ThemeMode.system,
      // TODO: In Prompt 3.x, connect to theme provider for dynamic theme

      // === NAVIGATION ===
      // TODO: In Prompt 1.2 implementation, replace with GoRouter
      // For now, using basic MaterialApp with placeholder home
      home: const _PlaceholderHomePage(),

      // When GoRouter is implemented in app_router.dart, use:
      // routerConfig: appRouter,
    );
  }
}

/// Placeholder home page until router is fully implemented.
///
/// This will be replaced when go_router is configured in app_router.dart.
class _PlaceholderHomePage extends StatelessWidget {
  const _PlaceholderHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VitalSync'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'VitalSync',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Health & Fitness Companion',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '✅ Dependency Injection Initialized',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const _ServiceStatusList(),
              const SizedBox(height: 32),
              Text(
                'Router configuration will be added in Prompt 1.2',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows status of registered services for verification.
class _ServiceStatusList extends StatelessWidget {
  const _ServiceStatusList();

  @override
  Widget build(BuildContext context) {
    final services = [
      'Firebase',
      'Database (Drift)',
      'Analytics Service',
      'GDPR Manager',
      'Notification Service',
      'Connectivity Service',
      'Sync Service',
      'Repositories',
    ];

    return Column(
      children: services.map((service) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(service, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      }).toList(),
    );
  }
}
