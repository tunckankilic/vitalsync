/// VitalSync — Settings Riverpod Providers.
///
/// themeProvider (dark/light/system/highContrast)
/// localeProvider (en/tr/de)
/// notificationEnabledProvider
/// gdprConsentProvider
/// unitSystemProvider (metric/imperial)
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics_service.dart';
import '../constants/app_constants.dart';
import '../di/injection_container.dart';

part 'settings_provider.g.dart';

/// Provider for SharedPreferences instance
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  return getIt<SharedPreferences>();
}

/// Provider for AnalyticsService instance
@Riverpod(keepAlive: true)
AnalyticsService settingsAnalyticsService(Ref ref) {
  return getIt<AnalyticsService>();
}

/// Theme mode provider with SharedPreferences persistence
@riverpod
class ThemeSetting extends _$ThemeSetting {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeModeString = prefs.getString(AppConstants.prefKeyThemeMode);

    if (themeModeString == null) {
      return ThemeMode.system;
    }

    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  /// Update theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final analytics = ref.read(settingsAnalyticsServiceProvider);

    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
      case ThemeMode.dark:
        modeString = 'dark';
      case ThemeMode.system:
        modeString = 'system';
    }

    await prefs.setString(AppConstants.prefKeyThemeMode, modeString);

    // Fire analytics event
    await analytics.logThemeChanged(theme: modeString);

    // Update user property
    await analytics.setUserTheme(modeString);

    state = mode;
  }
}

/// Material You enable/disable provider with SharedPreferences persistence
@riverpod
class MaterialYouSetting extends _$MaterialYouSetting {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    // Default to true for supported devices
    return prefs.getBool(AppConstants.prefKeyMaterialYouEnabled) ?? true;
  }

  /// Toggle Material You
  Future<void> setEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final analytics = ref.read(settingsAnalyticsServiceProvider);

    await prefs.setBool(AppConstants.prefKeyMaterialYouEnabled, enabled);

    // Fire analytics event (using theme changed event with a parameter)
    await analytics.logThemeChanged(
      theme: enabled ? 'material_you' : 'default',
    );

    state = enabled;
  }
}

/// Locale provider with SharedPreferences persistence
@riverpod
class LocaleSetting extends _$LocaleSetting {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final localeString = prefs.getString(AppConstants.prefKeyLocale) ?? 'en';

    return Locale(localeString);
  }

  /// Update locale
  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final analytics = ref.read(settingsAnalyticsServiceProvider);

    await prefs.setString(AppConstants.prefKeyLocale, locale.languageCode);

    // Fire analytics event
    await analytics.logLocaleChanged(locale: locale.languageCode);

    // Update user property
    await analytics.setUserLocale(locale.languageCode);
    state = locale;
  }
}

/// Notification enabled provider with SharedPreferences persistence
@riverpod
class NotificationSetting extends _$NotificationSetting {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(AppConstants.prefKeyNotificationsEnabled) ?? true;
  }

  /// Toggle notification enabled status
  Future<void> setEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);

    await prefs.setBool(AppConstants.prefKeyNotificationsEnabled, enabled);

    state = enabled;
  }
}

/// GDPR consent provider with SharedPreferences persistence
@riverpod
class GdprConsentSetting extends _$GdprConsentSetting {
  @override
  Map<String, bool> build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    return {
      AppConstants.gdprConsentTypeAnalytics:
          prefs.getBool(AppConstants.prefKeyAnalyticsConsent) ?? false,
      AppConstants.gdprConsentTypeHealthData:
          prefs.getBool(AppConstants.prefKeyHealthDataConsent) ?? false,
      AppConstants.gdprConsentTypeFitnessData:
          prefs.getBool(AppConstants.prefKeyFitnessDataConsent) ?? false,
      AppConstants.gdprConsentTypeCloudBackup:
          prefs.getBool(AppConstants.prefKeyCloudBackupConsent) ?? false,
    };
  }

  /// Update consent for a specific type
  Future<void> setConsent(String consentType, bool granted) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final analytics = ref.read(settingsAnalyticsServiceProvider);

    // Map consent type to SharedPreferences key
    String prefKey;
    switch (consentType) {
      case AppConstants.gdprConsentTypeAnalytics:
        prefKey = AppConstants.prefKeyAnalyticsConsent;
      case AppConstants.gdprConsentTypeHealthData:
        prefKey = AppConstants.prefKeyHealthDataConsent;
      case AppConstants.gdprConsentTypeFitnessData:
        prefKey = AppConstants.prefKeyFitnessDataConsent;
      case AppConstants.gdprConsentTypeCloudBackup:
        prefKey = AppConstants.prefKeyCloudBackupConsent;
      default:
        throw ArgumentError('Unknown consent type: $consentType');
    }

    await prefs.setBool(prefKey, granted);

    // Fire analytics event (if analytics consent is granted)
    if (granted) {
      await analytics.logConsentGranted(consentType: consentType);
    } else {
      await analytics.logConsentRevoked(consentType: consentType);
    }

    // Update state
    state = {...state, consentType: granted};
  }

  /// Update all consents at once
  Future<void> setAllConsents(Map<String, bool> consents) async {
    final prefs = ref.read(sharedPreferencesProvider);

    for (final entry in consents.entries) {
      String prefKey;
      switch (entry.key) {
        case AppConstants.gdprConsentTypeAnalytics:
          prefKey = AppConstants.prefKeyAnalyticsConsent;
        case AppConstants.gdprConsentTypeHealthData:
          prefKey = AppConstants.prefKeyHealthDataConsent;
        case AppConstants.gdprConsentTypeFitnessData:
          prefKey = AppConstants.prefKeyFitnessDataConsent;
        case AppConstants.gdprConsentTypeCloudBackup:
          prefKey = AppConstants.prefKeyCloudBackupConsent;
        default:
          continue;
      }

      await prefs.setBool(prefKey, entry.value);
    }

    state = consents;
  }
}

/// Unit system enum
enum UnitSystem { metric, imperial }

/// Unit system provider with SharedPreferences persistence
@riverpod
class UnitSystemSetting extends _$UnitSystemSetting {
  @override
  UnitSystem build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final unitSystemString = prefs.getString(AppConstants.prefKeyUnitSystem);

    if (unitSystemString == 'imperial') {
      return UnitSystem.imperial;
    }

    return UnitSystem.metric;
  }

  /// Update unit system
  Future<void> setUnitSystem(UnitSystem unitSystem) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final analytics = ref.read(settingsAnalyticsServiceProvider);

    final unitSystemString = unitSystem == UnitSystem.imperial
        ? 'imperial'
        : 'metric';

    await prefs.setString(AppConstants.prefKeyUnitSystem, unitSystemString);

    // Update user property
    await analytics.setUnitSystem(unitSystemString);

    state = unitSystem;
  }
}
