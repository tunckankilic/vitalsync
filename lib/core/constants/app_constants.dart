/// VitalSync — Application-wide constants.
///
/// Contains app metadata, API endpoints, SharedPreferences keys,
/// notification channel IDs, default values, achievement thresholds,
/// insight rule thresholds, and analytics event names.
library;

/// Application-wide constants for VitalSync.
///
/// Provides centralized configuration for all app modules including
/// metadata, Firebase settings, notifications, achievements, and analytics.
abstract class AppConstants {
  // ═══════════════════════════════════════════════════════════════════════
  // APP METADATA
  // ═══════════════════════════════════════════════════════════════════════

  /// Application name
  static const String appName = 'VitalSynch';

  /// Application version (semantic versioning)
  static const String appVersion = '1.0.0';

  /// Build number
  static const int buildNumber = 1;

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED PREFERENCES KEYS
  // ═══════════════════════════════════════════════════════════════════════

  /// User preferences key prefix
  static const String prefKeyPrefix = 'vitalsync_';

  /// First launch flag (for onboarding)
  static const String keyFirstLaunch = '${prefKeyPrefix}first_launch';

  /// Onboarding completion flag
  static const String prefKeyOnboardingCompleted =
      '${prefKeyPrefix}onboarding_completed';

  /// Current theme mode (light/dark/system/highContrast)
  static const String prefKeyThemeMode = '${prefKeyPrefix}theme_mode';

  /// Material You enabled flag (Android 12+)
  static const String prefKeyMaterialYouEnabled =
      '${prefKeyPrefix}material_you_enabled';

  /// Current locale (en/tr/de)
  static const String prefKeyLocale = '${prefKeyPrefix}locale';

  /// Notifications enabled flag
  static const String prefKeyNotificationsEnabled =
      '${prefKeyPrefix}notifications_enabled';

  /// Unit system (metric/imperial)
  static const String prefKeyUnitSystem = '${prefKeyPrefix}unit_system';

  /// GDPR consent version accepted
  static const String prefKeyGdprConsentVersion =
      '${prefKeyPrefix}gdpr_consent_version';

  /// GDPR consent timestamp
  static const String prefKeyGdprConsentTimestamp =
      '${prefKeyPrefix}gdpr_consent_timestamp';

  /// Analytics consent granted
  static const String prefKeyAnalyticsConsent =
      '${prefKeyPrefix}analytics_consent';

  /// Health data consent granted
  static const String prefKeyHealthDataConsent =
      '${prefKeyPrefix}health_data_consent';

  /// Fitness data consent granted
  static const String prefKeyFitnessDataConsent =
      '${prefKeyPrefix}fitness_data_consent';

  /// Cloud backup consent granted
  static const String prefKeyCloudBackupConsent =
      '${prefKeyPrefix}cloud_backup_consent';

  /// Last sync timestamp
  static const String prefKeyLastSyncTimestamp =
      '${prefKeyPrefix}last_sync_timestamp';

  /// User ID (Firebase UID)
  static const String prefKeyUserId = '${prefKeyPrefix}user_id';

  // NOTIFICATION CHANNEL IDs

  /// Medication reminder notification channel ID
  static const String notificationChannelMedication = 'medication_reminders';

  /// Medication reminder channel name
  static const String notificationChannelMedicationName =
      'Medication Reminders';

  /// Workout reminder notification channel ID
  static const String notificationChannelWorkout = 'workout_reminders';

  /// Workout reminder channel name
  static const String notificationChannelWorkoutName = 'Workout Reminders';

  /// Achievement unlocked notification channel ID
  static const String notificationChannelAchievement = 'achievements';

  /// Achievement channel name
  static const String notificationChannelAchievementName = 'Achievements';

  /// Weekly report notification channel ID
  static const String notificationChannelWeeklyReport = 'weekly_reports';

  /// Weekly report channel name
  static const String notificationChannelWeeklyReportName = 'Weekly Reports';

  /// Insight notification channel ID
  static const String notificationChannelInsight = 'insights';

  /// Insight channel name
  static const String notificationChannelInsightName = 'Insights';

  /// General notification channel ID
  static const String notificationChannelGeneral = 'general';

  /// General notification channel name
  static const String notificationChannelGeneralName = 'General Notifications';

  // DEFAULT WORKOUT VALUES

  /// Default rest time between sets (seconds)
  static const int defaultRestTimeSeconds = 90;

  /// Default number of sets per exercise
  static const int defaultSetsCount = 3;

  /// Default number of reps per set
  static const int defaultRepsCount = 10;

  /// Default weight increment (kg)
  static const double defaultWeightIncrementKg = 2.5;

  /// Default weight increment (lbs)
  static const double defaultWeightIncrementLbs = 5.0;

  /// Minimum workout duration to count as valid (minutes)
  static const int minWorkoutDurationMinutes = 5;

  /// Maximum realistic 1RM weight (kg) - safety check
  static const double maxRealistic1RMKg = 500.0;

  /// Maximum realistic 1RM weight (lbs) - safety check
  static const double maxRealistic1RMLbs = 1100.0;

  // ACHIEVEMENT THRESHOLDS

  /// Streak achievements (days)
  static const Map<String, int> achievementStreakThresholds = {
    'first_step': 1,
    'week_warrior': 7,
    'monthly_master': 30,
    'iron_will': 100,
    'legendary': 365,
  };

  /// Volume achievements (kg)
  static const Map<String, int> achievementVolumeThresholds = {
    'ton_club': 1000,
    'heavy_lifter': 10000,
    'powerhouse': 100000,
    'titan': 1000000,
  };

  /// Workout count achievements
  static const Map<String, int> achievementWorkoutThresholds = {
    'beginner': 1,
    'consistent': 10,
    'dedicated': 50,
    'gym_rat': 100,
    'elite': 500,
  };

  /// Personal record achievements
  static const Map<String, int> achievementPRThresholds = {
    'first_pr': 1,
    'record_breaker': 10,
    'champion': 50,
    'legend': 100,
  };

  /// Medication compliance achievements (consecutive days at 100%)
  static const Map<String, int> achievementComplianceThresholds = {
    'perfect_day': 1,
    'week_of_wellness': 7,
    'health_hero': 30,
    'medicine_master': 90,
  };

  /// Cross-module achievements (special combinations)
  static const Map<String, Map<String, int>> achievementCrossModuleThresholds =
      {
        'balance_master': {
          'min_compliance_percent': 100,
          'min_workouts_per_week': 4,
          'consecutive_weeks': 1,
        },
        'synced_up': {
          'min_compliance_percent': 90,
          'min_workouts_per_week': 3,
          'consecutive_weeks': 4,
        },
      };

  // INSIGHT RULE THRESHOLDS

  /// Minimum sample size for correlation analysis
  static const int insightCorrelationMinSampleSize = 14;

  /// Correlation strength threshold (0.0 - 1.0)
  static const double insightCorrelationMinStrength = 0.5;

  /// Trend analysis window (days)
  static const int insightTrendWindowDays = 30;

  /// Minimum data points for trend detection
  static const int insightTrendMinDataPoints = 7;

  /// Anomaly detection threshold (standard deviations)
  static const double insightAnomalyThresholdStdDev = 2.0;

  /// Insight validity duration (days)
  static const int insightValidityDurationDays = 7;

  /// Maximum active insights to show
  static const int insightMaxActiveCount = 10;

  /// Compliance rate threshold for positive insights (percentage)
  static const double insightComplianceThresholdGood = 85.0;

  /// Compliance rate threshold for warning insights (percentage)
  static const double insightComplianceThresholdWarning = 60.0;

  /// Volume increase threshold for progress insights (percentage)
  static const double insightVolumeIncreaseThreshold = 10.0;

  /// Volume decrease threshold for rest suggestion (percentage)
  static const double insightVolumeDecreaseThreshold = 15.0;

  // ANALYTICS EVENT NAMES

  // --- Onboarding Events ---
  /// User started onboarding flow
  static const String analyticsOnboardingStarted = 'onboarding_started';

  /// User completed onboarding
  static const String analyticsOnboardingCompleted = 'onboarding_completed';

  /// User skipped onboarding
  static const String analyticsOnboardingSkipped = 'onboarding_skipped';

  // --- Health Events ---
  /// User added a new medication
  static const String analyticsMedicationAdded = 'medication_added';

  /// User marked medication as taken
  static const String analyticsMedicationTaken = 'medication_taken';

  /// User marked medication as skipped
  static const String analyticsMedicationSkipped = 'medication_skipped';

  /// User logged a symptom
  static const String analyticsSymptomLogged = 'symptom_logged';

  /// User viewed health timeline
  static const String analyticsHealthTimelineViewed = 'health_timeline_viewed';

  // --- Fitness Events ---
  /// User started a workout session
  static const String analyticsWorkoutStarted = 'workout_started';

  /// User completed a workout session
  static const String analyticsWorkoutCompleted = 'workout_completed';

  /// User cancelled a workout session
  static const String analyticsWorkoutCancelled = 'workout_cancelled';

  /// User logged a set
  static const String analyticsSetLogged = 'set_logged';

  /// User achieved a personal record
  static const String analyticsPRAchieved = 'pr_achieved';

  /// User created custom exercise
  static const String analyticsExerciseCreated = 'exercise_created';

  /// User viewed progress charts
  static const String analyticsProgressViewed = 'progress_viewed';

  /// User viewed achievement list
  static const String analyticsAchievementsViewed = 'achievements_viewed';

  /// User unlocked an achievement
  static const String analyticsAchievementUnlocked = 'achievement_unlocked';

  // --- Insight Events ---
  /// User viewed an insight
  static const String analyticsInsightViewed = 'insight_viewed';

  /// User dismissed an insight
  static const String analyticsInsightDismissed = 'insight_dismissed';

  /// User viewed weekly report
  static const String analyticsWeeklyReportViewed = 'weekly_report_viewed';

  // --- Engagement Events ---
  /// User opened the app
  static const String analyticsAppOpened = 'app_opened';

  /// User tapped a notification
  static const String analyticsNotificationTapped = 'notification_tapped';

  /// User exported their data
  static const String analyticsDataExported = 'data_exported';

  /// User deleted their data
  static const String analyticsDataDeleted = 'data_deleted';

  /// User changed theme
  static const String analyticsThemeChanged = 'theme_changed';

  /// User changed locale
  static const String analyticsLocaleChanged = 'locale_changed';

  // --- GDPR Events ---
  /// User granted consent
  static const String analyticsConsentGranted = 'consent_granted';

  /// User revoked consent
  static const String analyticsConsentRevoked = 'consent_revoked';

  // GDPR

  /// Current GDPR privacy policy version
  static const String gdprPolicyVersion = '1.0.0';

  /// GDPR consent types
  static const String gdprConsentTypeAnalytics = 'analytics';
  static const String gdprConsentTypeHealthData = 'health_data';
  static const String gdprConsentTypeFitnessData = 'fitness_data';
  static const String gdprConsentTypeCloudBackup = 'cloud_backup';

  // SYNC & NETWORK

  /// Sync retry limit
  static const int syncMaxRetries = 3;

  /// Sync retry delay (seconds)
  static const int syncRetryDelaySeconds = 5;

  /// Sync batch size (records per batch)
  static const int syncBatchSize = 50;

  /// Network request timeout (seconds)
  static const int networkTimeoutSeconds = 30;

  // NOTIFICATION SCHEDULING

  /// Snooze duration for medication reminders (minutes)
  static const int snoozeDurationMinutes = 15;

  /// Daily summary notification hour (24h)
  static const int dailySummaryHour = 21;

  /// Insight generation hour (24h)
  static const int insightGenerationHour = 6;

  /// Weekly report day of week (DateTime.monday = 1)
  static const int weeklyReportDayOfWeek = DateTime.monday;

  /// Weekly report notification hour (24h)
  static const int weeklyReportHour = 7;

  /// Streak warning notification hour (24h)
  static const int streakWarningHour = 20;

  // WORKMANAGER TASK NAMES

  /// Background task: check missed medications (hourly)
  static const String taskCheckMissedMedications =
      'com.vitalsync.checkMissedMedications';

  /// Background task: generate insights (daily at 06:00)
  static const String taskGenerateInsights = 'com.vitalsync.generateInsights';

  /// Background task: sync pending data (every 15 min)
  static const String taskSyncPendingData = 'com.vitalsync.syncPendingData';

  /// Background task: weekly report generation (Monday 07:00)
  static const String taskWeeklyReport = 'com.vitalsync.weeklyReport';

  /// Background task: daily summary notification (21:00)
  static const String taskDailySummary = 'com.vitalsync.dailySummary';

  /// Background task: streak warning check (20:00)
  static const String taskStreakWarning = 'com.vitalsync.streakWarning';

  // UI CONSTANTS

  /// Default animation duration (milliseconds)
  static const int defaultAnimationDurationMs = 300;

  /// Page transition duration (milliseconds)
  static const int pageTransitionDurationMs = 250;

  /// Snackbar duration (seconds)
  static const int snackbarDurationSeconds = 3;

  /// Bottom sheet border radius
  static const double bottomSheetBorderRadius = 24.0;

  /// Card border radius
  static const double cardBorderRadius = 16.0;

  /// Button border radius
  static const double buttonBorderRadius = 12.0;

  /// Default padding
  static const double defaultPadding = 16.0;

  /// Small padding
  static const double smallPadding = 8.0;

  /// Large padding
  static const double largePadding = 24.0;
}
