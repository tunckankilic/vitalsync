/// VitalSync — Main Application Entry Point.
///
/// Health & Fitness Companion with offline-first architecture.
/// GDPR-compliant, multi-language, accessibility-first.
library;

import 'package:amplify_analytics_pinpoint/amplify_analytics_pinpoint.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'core/background/background_service.dart';
import 'core/config/app_environment.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/network/connectivity_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_provider.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';

/// Holds initialization error (if any) for display on splash screen.
Object? _initError;

/// Exposes the initialization error for the splash screen to check.
Object? get appInitError => _initError;

/// Application entry point.
///
/// Wires up crash reporting before running the app:
/// - The DSN comes from the build-time environment ([AppEnvironment.sentryDsn],
///   supplied via `--dart-define=SENTRY_DSN=...`). When empty (local/dev),
///   Sentry is skipped so we don't generate noise and the app behaves exactly
///   as before.
/// - When a DSN is present, [SentryFlutter.init] runs [_bootstrap] inside its
///   guarded zone (`appRunner`) and installs its `FlutterError.onError` and
///   `PlatformDispatcher.onError` integrations. Those chain to the previous
///   handlers, so the existing `FlutterError.reportError` calls below keep
///   working AND are now forwarded to Sentry, including uncaught async errors.
void main() async {
  const sentryDsn = AppEnvironment.sentryDsn;

  if (sentryDsn.isEmpty) {
    await _bootstrap();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
    },
    appRunner: _bootstrap,
  );
}

/// Initializes services and runs the app.
///
/// This preserves the original launch flow unchanged: critical init is guarded
/// so a failure is captured in [_initError] (surfaced on the splash screen),
/// and non-critical services degrade gracefully without blocking launch.
Future<void> _bootstrap() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Release-only diagnostic error screen.
  //
  // In a release/prod build an uncaught error thrown while building a widget
  // (e.g. on the route navigated to after the splash) is otherwise painted by
  // the default [ErrorWidget] as a blank/grey box — the "white screen" with no
  // hint of what failed. Here we replace it with a visible screen that prints
  // the exception type, message and the first stack frames so the real root
  // cause is observable directly on the device.
  //
  // Debug builds are intentionally left untouched ([kDebugMode] guard) so
  // Flutter's familiar red error overlay keeps working in dev exactly as before.
  //
  // This does NOT swallow the error or change reporting: the framework still
  // routes the same error through [FlutterError.onError] (and thus to Sentry,
  // when a DSN is configured) before this builder is asked to render — so the
  // error both surfaces on screen AND lands in crash reporting.
  if (!kDebugMode) {
    ErrorWidget.builder = _buildReleaseErrorWidget;
  }

  try {
    // Initialize AWS Amplify — critical, app cannot function without it
    if (!Amplify.isConfigured) {
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyAPI(),
        AmplifyAnalyticsPinpoint(),
      ]);
      await Amplify.configure(AppEnvironment.amplifyConfig);
    }

    // Initialize GetIt dependency injection
    await initializeDependencies();
  } catch (e, stack) {
    _initError = e;
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: stack, library: 'main'),
    );
  }

  // Non-critical services — failures here should not prevent app launch
  if (_initError == null) {
    try {
      final notificationService = getIt<NotificationService>();
      await notificationService.initialize();
      await notificationService.requestPermissions();

      final backgroundService = getIt<BackgroundService>();
      await backgroundService.initialize();
      await backgroundService.scheduleAllPeriodicTasks();

      final connectivityService = getIt<ConnectivityService>();
      connectivityService.startListening();

      final syncService = getIt<SyncService>();
      syncService.startAutoSync();
    } catch (e, stack) {
      // Non-critical — log but don't block app launch
      debugPrint('Non-critical initialization error: $e');
      FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: stack, library: 'main'),
      );
    }
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

/// Diagnostic screen shown — in release/prod builds only — in place of a widget
/// that threw while building.
///
/// Deliberately dependency-free: it does not read [Theme], [MediaQuery] or any
/// inherited widget, because the failure can happen high in the tree where those
/// ancestors may be absent. Every [Text] carries an explicit style (with
/// `decoration: none`) so it renders correctly without a [DefaultTextStyle]
/// ancestor — i.e. the diagnostic screen itself can never throw.
///
/// This is a developer-facing diagnostic, not a polished user error screen; it
/// exists to make the previously-invisible "white screen" failure readable on
/// device. Wired up via `ErrorWidget.builder` in [_bootstrap].
Widget _buildReleaseErrorWidget(FlutterErrorDetails details) {
  final exceptionType = details.exception.runtimeType.toString();
  final message = details.exceptionAsString();
  final frames =
      details.stack
          ?.toString()
          .trimRight()
          .split('\n')
          .take(8)
          .join('\n') ??
      'No stack trace available.';

  return Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      color: const Color(0xFF1A0000),
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unexpected error',
              style: TextStyle(
                color: Color(0xFFFF8A80),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              exceptionType,
              style: const TextStyle(
                color: Color(0xFFFFD180),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              frames,
              style: const TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 11,
                fontFamily: 'monospace',
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
