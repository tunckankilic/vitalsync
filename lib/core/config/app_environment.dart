/// VitalSync — Build-time environment configuration.
///
/// Selects which backend configuration the app runs against, decided at
/// build time via `--dart-define=ENV=dev|prod`. This replaces the previous
/// flow where the dev/prod split required hand-editing the Amplify config
/// file — which risked shipping a prod build wired to dev resources.
///
/// Usage:
///   `flutter run   --dart-define=ENV=dev`
///   `flutter build --dart-define=ENV=prod --dart-define=SENTRY_DSN=<prod_dsn>`
///
/// When `ENV` is absent or unrecognized the app falls back to [AppEnv.dev]
/// (the safe default) — never to prod.
library;

import '../../amplifyconfiguration.dart';
import '../../amplifyconfiguration_prod.dart';

/// Supported build environments.
enum AppEnv { dev, prod }

/// Central accessor for build-time environment configuration.
///
/// Everything that differs between dev and prod (the Amplify config string,
/// the Sentry DSN) is read from `--dart-define` values through this class so
/// no source file needs to be edited to switch environments.
class AppEnvironment {
  AppEnvironment._();

  /// Raw `ENV` dart-define. Defaults to `dev` so a build without an explicit
  /// `ENV` never accidentally targets production.
  static const String _envName = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  /// The active environment. Anything other than an exact `prod` resolves to
  /// [AppEnv.dev] (safe default).
  static AppEnv get current =>
      _envName == 'prod' ? AppEnv.prod : AppEnv.dev;

  /// Whether the app is running against the production backend.
  static bool get isProd => current == AppEnv.prod;

  /// Human-readable environment name, e.g. for diagnostics/observability tags.
  static String get name => current == AppEnv.prod ? 'prod' : 'dev';

  /// The Amplify configuration string for the active environment.
  ///
  /// Selected at runtime from a build-time constant, so switching is a
  /// `--dart-define=ENV=...` change, not a file edit.
  static String get amplifyConfig => isProd ? amplifyconfigProd : amplifyconfig;

  /// Sentry DSN for crash reporting, supplied per build via
  /// `--dart-define=SENTRY_DSN=...`. Empty in local/dev builds disables
  /// Sentry (see `main.dart`).
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Backend endpoint that revokes the user's Sign in with Apple token on
  /// account deletion (App Store Guideline 5.1.1(v)), supplied per build via
  /// `--dart-define=APPLE_REVOKE_ENDPOINT=...`.
  ///
  /// Empty disables the revoke step entirely: the account deletion still
  /// completes, so a build without the define behaves exactly as before. The
  /// app never holds Apple secrets — it only forwards a short-lived Apple
  /// authorization code to this endpoint, which performs the actual revoke.
  static const String appleRevokeEndpoint = String.fromEnvironment(
    'APPLE_REVOKE_ENDPOINT',
  );
}
