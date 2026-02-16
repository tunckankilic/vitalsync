/// VitalSync — Main Application Entry Point.
///
/// Health & Fitness Companion with offline-first architecture.
/// GDPR-compliant, multi-language, accessibility-first.
library;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'core/background/background_service.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/network/connectivity_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_provider.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize GetIt dependency injection
    await initializeDependencies();

    // Initialize notification service
    final notificationService = getIt<NotificationService>();
    await notificationService.initialize();
    await notificationService.requestPermissions();

    // Initialize background service
    final backgroundService = getIt<BackgroundService>();
    await backgroundService.initialize();
    await backgroundService.scheduleAllPeriodicTasks();

    // Start connectivity service listening
    final connectivityService = getIt<ConnectivityService>();
    connectivityService.startListening();

    // Start auto-sync on connectivity changes
    final syncService = getIt<SyncService>();
    syncService.startAutoSync();
  } catch (e) {
    // If critical initialization fails, still launch the app
    // so the user sees something instead of a crash
    debugPrint('Initialization error: $e');
  }

  // Run the app wrapped in ProviderScope for Riverpod
  runApp(const ProviderScope(child: VitalSyncApp()));
}

/// VitalSync Application Widget.
///
/// Root widget that configures the app with:
/// - Localization support (EN, TR, DE)
/// - Theme configuration (light, dark, high contrast)
/// - GoRouter navigation
/// - Material You support (Android 12+)
/// - GDPR compliance check on first launch
class VitalSyncApp extends ConsumerWidget {
  const VitalSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeSettingProvider);
    final locale = ref.watch(localeSettingProvider);
    final materialYouEnabled = ref.watch(materialYouSettingProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Material You color schemes (Android 12+)
        // If not available, fallback to default themes

        // Use dynamic colors if available AND enabled in settings
        final useDynamicColors =
            lightDynamic != null && darkDynamic != null && materialYouEnabled;

        ThemeData lightTheme;
        ThemeData darkTheme;

        if (useDynamicColors) {
          // Use Material You colors from wallpaper
          lightTheme = AppTheme.lightTheme.copyWith(colorScheme: lightDynamic);
          darkTheme = AppTheme.darkTheme.copyWith(colorScheme: darkDynamic);
        } else {
          // Fallback to default themes
          lightTheme = AppTheme.lightTheme;
          darkTheme = AppTheme.darkTheme;
        }

        return MaterialApp.router(
          // === APP METADATA ===
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // === ROUTING ===
          routerConfig: appRouter,

          // === LOCALIZATION ===
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          // === THEME ===
          theme: lightTheme,
          darkTheme: darkTheme,
          highContrastTheme: AppTheme.highContrastTheme,
          themeMode: themeMode,
        );
      },
    );
  }
}
