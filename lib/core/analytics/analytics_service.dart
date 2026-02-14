/// VitalSync — Firebase Analytics Service (GDPR-aware).
///
/// GDPR consent check before firing any event.
/// Predefined event methods for onboarding, health, fitness,
/// insights, and engagement tracking.
/// User property setters and screen view tracking.
library;

import 'package:firebase_analytics/firebase_analytics.dart';

import '../constants/app_constants.dart';
import '../gdpr/gdpr_manager.dart';

/// Firebase Analytics Service for VitalSync.
/// Wrapper around Firebase Analytics that ensures GDPR compliance
/// by checking consent before logging any events.
class AnalyticsService {
  AnalyticsService({
    required FirebaseAnalytics analytics,
    required GDPRManager gdprManager,
  }) : _analytics = analytics,
       _gdprManager = gdprManager;
  final FirebaseAnalytics _analytics;
  final GDPRManager _gdprManager;

  // ONBOARDING EVENTS

  /// Logs when user starts the onboarding flow.
  Future<void> logOnboardingStarted() async {
    await _logEvent(AppConstants.analyticsOnboardingStarted);
  }

  /// Logs when user completes the onboarding flow.
  Future<void> logOnboardingCompleted() async {
    await _logEvent(AppConstants.analyticsOnboardingCompleted);
  }

  /// Logs when user skips the onboarding flow.
  Future<void> logOnboardingSkipped() async {
    await _logEvent(AppConstants.analyticsOnboardingSkipped);
  }

  // HEALTH MODULE EVENTS

  /// Logs when a new medication is added.
  /// [frequency] - Medication frequency (daily, twice daily, etc.)
  Future<void> logMedicationAdded({String? frequency}) async {
    await _logEvent(
      AppConstants.analyticsMedicationAdded,
      parameters: frequency != null ? {'frequency': frequency} : null,
    );
  }

  /// Logs when a medication is marked as taken.
  /// [onTime] - Whether medication was taken on schedule
  Future<void> logMedicationTaken({bool? onTime}) async {
    await _logEvent(
      AppConstants.analyticsMedicationTaken,
      parameters: onTime != null ? {'on_time': onTime} : null,
    );
  }

  /// Logs when a medication is marked as skipped.
  Future<void> logMedicationSkipped() async {
    await _logEvent(AppConstants.analyticsMedicationSkipped);
  }

  /// Logs when a symptom is logged.
  /// [severity] - Symptom severity (1-5)
  /// [hasNotes] - Whether user added notes
  Future<void> logSymptomLogged({int? severity, bool? hasNotes}) async {
    await _logEvent(
      AppConstants.analyticsSymptomLogged,
      parameters: {'severity': ?severity, 'has_notes': ?hasNotes},
    );
  }

  /// Logs when health timeline is viewed.
  Future<void> logHealthTimelineViewed() async {
    await _logEvent(AppConstants.analyticsHealthTimelineViewed);
  }

  // FITNESS MODULE EVENTS

  /// Logs when a workout session is started
  /// [templateName] - Name of workout template (if using one)
  /// [isCustom] - Whether this is a custom workout
  Future<void> logWorkoutStarted({String? templateName, bool? isCustom}) async {
    await _logEvent(
      AppConstants.analyticsWorkoutStarted,
      parameters: {'template_name': ?templateName, 'is_custom': ?isCustom},
    );
  }

  /// Logs when a workout session is completed.
  /// [durationMinutes] - Workout duration in minutes
  /// [totalVolume] - Total volume lifted (kg or lbs)
  /// [exerciseCount] - Number of exercises performed
  Future<void> logWorkoutCompleted({
    int? durationMinutes,
    double? totalVolume,
    int? exerciseCount,
  }) async {
    await _logEvent(
      AppConstants.analyticsWorkoutCompleted,
      parameters: {
        'duration_minutes': ?durationMinutes,
        'total_volume': ?totalVolume,
        'exercise_count': ?exerciseCount,
      },
    );
  }

  /// Logs when a workout session is cancelled.
  /// [durationMinutes] - How long before cancellation
  Future<void> logWorkoutCancelled({int? durationMinutes}) async {
    await _logEvent(
      AppConstants.analyticsWorkoutCancelled,
      parameters: durationMinutes != null
          ? {'duration_before_cancel': durationMinutes}
          : null,
    );
  }

  /// Logs when a set is logged during workout.
  /// [exerciseName] - Name of the exercise
  /// [isPR] - Whether this set was a personal record
  Future<void> logSetLogged({String? exerciseName, bool? isPR}) async {
    await _logEvent(
      AppConstants.analyticsSetLogged,
      parameters: {'exercise_name': ?exerciseName, 'is_pr': ?isPR},
    );
  }

  /// Logs when a personal record is achieved.
  /// [exerciseName] - Name of the exercise
  /// [weight] - Weight lifted
  /// [reps] - Number of reps
  Future<void> logPRAchieved({
    required String exerciseName,
    double? weight,
    int? reps,
  }) async {
    await _logEvent(
      AppConstants.analyticsPRAchieved,
      parameters: {
        'exercise_name': exerciseName,
        'weight': ?weight,
        'reps': ?reps,
      },
    );
  }

  /// Logs when a custom exercise is created.
  /// [category] - Exercise category
  Future<void> logExerciseCreated({String? category}) async {
    await _logEvent(
      AppConstants.analyticsExerciseCreated,
      parameters: category != null ? {'category': category} : null,
    );
  }

  /// Logs when progress charts are viewed.
  /// [timeRange] - Time range selected (1W, 1M, 3M, etc.)
  Future<void> logProgressViewed({String? timeRange}) async {
    await _logEvent(
      AppConstants.analyticsProgressViewed,
      parameters: timeRange != null ? {'time_range': timeRange} : null,
    );
  }

  /// Logs when achievements page is viewed.
  Future<void> logAchievementsViewed() async {
    await _logEvent(AppConstants.analyticsAchievementsViewed);
  }

  /// Logs when an achievement is unlocked.
  /// [achievementType] - Type of achievement (streak, volume, etc.)
  /// [achievementId] - Achievement identifier
  Future<void> logAchievementUnlocked({
    required String achievementType,
    required String achievementId,
  }) async {
    await _logEvent(
      AppConstants.analyticsAchievementUnlocked,
      parameters: {
        'achievement_type': achievementType,
        'achievement_id': achievementId,
      },
    );
  }

  // INSIGHT MODULE EVENTS

  /// Logs when an insight is viewed.
  /// [insightType] - Type of insight (correlation, trend, etc.)
  /// [category] - Category (health, fitness, crossModule)
  /// [priority] - Insight priority (1-5)
  Future<void> logInsightViewed({
    required String insightType,
    String? category,
    int? priority,
  }) async {
    await _logEvent(
      AppConstants.analyticsInsightViewed,
      parameters: {
        'insight_type': insightType,
        'category': ?category,
        'priority': ?priority,
      },
    );
  }

  /// Logs when an insight is dismissed.
  /// [insightType] - Type of insight dismissed
  Future<void> logInsightDismissed({required String insightType}) async {
    await _logEvent(
      AppConstants.analyticsInsightDismissed,
      parameters: {'insight_type': insightType},
    );
  }

  /// Logs when weekly report is viewed.
  /// [complianceRate] - Weekly medication compliance rate
  /// [workoutCount] - Number of workouts this week
  Future<void> logWeeklyReportViewed({
    double? complianceRate,
    int? workoutCount,
  }) async {
    await _logEvent(
      AppConstants.analyticsWeeklyReportViewed,
      parameters: {
        'compliance_rate': ?complianceRate,
        'workout_count': ?workoutCount,
      },
    );
  }

  /// Logs when user provides feedback on an insight.
  /// [insightType] - Type of insight
  /// [helpful] - Whether user found it helpful
  Future<void> logInsightFeedback({
    required String insightType,
    required bool helpful,
  }) async {
    await _logEvent(
      'insight_feedback',
      parameters: {'insight_type': insightType, 'helpful': helpful},
    );
  }

  // ENGAGEMENT EVENTS

  /// Logs when app is opened.
  /// [streakCount] - Current workout streak days
  Future<void> logAppOpened({int? streakCount}) async {
    await _logEvent(
      AppConstants.analyticsAppOpened,
      parameters: streakCount != null ? {'streak_count': streakCount} : null,
    );
  }

  /// Logs when a notification is tapped.
  /// [notificationType] - Type of notification (medication, workout, etc.)
  Future<void> logNotificationTapped({String? notificationType}) async {
    await _logEvent(
      AppConstants.analyticsNotificationTapped,
      parameters: notificationType != null
          ? {'notification_type': notificationType}
          : null,
    );
  }

  /// Logs when user exports their data.
  Future<void> logDataExported() async {
    await _logEvent(AppConstants.analyticsDataExported);
  }

  /// Logs when user deletes their data.
  Future<void> logDataDeleted() async {
    await _logEvent(AppConstants.analyticsDataDeleted);
  }

  /// Logs when user changes theme.
  /// [theme] - New theme (light, dark, highContrast)
  Future<void> logThemeChanged({required String theme}) async {
    await _logEvent(
      AppConstants.analyticsThemeChanged,
      parameters: {'theme': theme},
    );
  }

  /// Logs when user changes locale/language.
  /// [locale] - New locale code (en, tr, de)
  Future<void> logLocaleChanged({required String locale}) async {
    await _logEvent(
      AppConstants.analyticsLocaleChanged,
      parameters: {'locale': locale},
    );
  }

  // GDPR EVENTS

  /// Logs when consent is granted.
  /// [consentType] - Type of consent granted
  Future<void> logConsentGranted({required String consentType}) async {
    await _logEvent(
      AppConstants.analyticsConsentGranted,
      parameters: {'consent_type': consentType},
    );
  }

  /// Logs when consent is revoked.
  /// [consentType] - Type of consent revoked
  Future<void> logConsentRevoked({required String consentType}) async {
    await _logEvent(
      AppConstants.analyticsConsentRevoked,
      parameters: {'consent_type': consentType},
    );
  }

  // USER PROPERTIES

  /// Sets user locale property.
  Future<void> setUserLocale(String locale) async {
    if (!_gdprManager.canTrackAnalytics()) return;
    await _analytics.setUserProperty(name: 'locale', value: locale);
  }

  /// Sets user theme property.
  Future<void> setUserTheme(String theme) async {
    if (!_gdprManager.canTrackAnalytics()) return;
    await _analytics.setUserProperty(name: 'theme', value: theme);
  }

  /// Sets unit system property (metric/imperial).
  Future<void> setUnitSystem(String unitSystem) async {
    if (!_gdprManager.canTrackAnalytics()) return;
    await _analytics.setUserProperty(name: 'unit_system', value: unitSystem);
  }

  // SCREEN VIEW TRACKING

  /// Logs screen view event.
  /// [screenName] - Name of the screen
  /// [screenClass] - Optional class name of the screen
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_gdprManager.canTrackAnalytics()) return;

    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // INTERNAL HELPERS

  /// Internal method to log an event with GDPR consent check.
  /// All public log methods should use this internally.
  Future<void> _logEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    // GDPR check: only log if consent granted
    if (!_gdprManager.canTrackAnalytics()) {
      return; // Silent return, no error thrown
    }

    await _analytics.logEvent(name: eventName, parameters: parameters);
  }
}
