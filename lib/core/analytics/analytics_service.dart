/// VitalSync — Analytics Service (no-op).
///
/// AWS Pinpoint has been removed from the client. The engagement features it
/// backed are being shut down by AWS (2026-10-30), and the plugin threw
/// `ForbiddenException: Forbidden from accessing the Pinpoint resource` on
/// launch (before login), surfacing as an unhandled async error in the crash
/// reporting zone.
///
/// This service keeps its full public surface so every caller (settings, auth,
/// fitness/health/insights providers, screens, tests) compiles and behaves
/// exactly as before — but each method is now a guarded no-op: nothing is sent
/// anywhere and no Pinpoint/Amplify call can leak an exception.
///
/// The GDPR consent gate is preserved in [_track] so the privacy semantics and
/// the call shape stay intact. Re-introducing analytics later means swapping the
/// no-op sink in [_track] for a new backend; the call sites do not change.
library;

import '../gdpr/gdpr_manager.dart';

/// Analytics Service for VitalSync.
///
/// No-op wrapper retained for API stability after the AWS Pinpoint removal.
class AnalyticsService {
  AnalyticsService({required GDPRManager gdprManager})
    : _gdprManager = gdprManager;
  final GDPRManager _gdprManager;

  // ONBOARDING EVENTS

  /// Logs when user starts the onboarding flow.
  Future<void> logOnboardingStarted() async => _track();

  /// Logs when user completes the onboarding flow.
  Future<void> logOnboardingCompleted() async => _track();

  /// Logs when user skips the onboarding flow.
  Future<void> logOnboardingSkipped() async => _track();

  // HEALTH MODULE EVENTS

  /// Logs when a new medication is added.
  /// [frequency] - Medication frequency (daily, twice daily, etc.)
  Future<void> logMedicationAdded({String? frequency}) async => _track();

  /// Logs when a medication is marked as taken.
  /// [onTime] - Whether medication was taken on schedule
  Future<void> logMedicationTaken({bool? onTime}) async => _track();

  /// Logs when a medication is marked as skipped.
  Future<void> logMedicationSkipped() async => _track();

  /// Logs when a symptom is logged.
  /// [severity] - Symptom severity (1-5)
  /// [hasNotes] - Whether user added notes
  Future<void> logSymptomLogged({int? severity, bool? hasNotes}) async =>
      _track();

  /// Logs when health timeline is viewed.
  Future<void> logHealthTimelineViewed() async => _track();

  // FITNESS MODULE EVENTS

  /// Logs when a workout session is started
  /// [templateName] - Name of workout template (if using one)
  /// [isCustom] - Whether this is a custom workout
  Future<void> logWorkoutStarted({String? templateName, bool? isCustom}) async =>
      _track();

  /// Logs when a workout session is completed.
  /// [durationMinutes] - Workout duration in minutes
  /// [totalVolume] - Total volume lifted (kg or lbs)
  /// [exerciseCount] - Number of exercises performed
  Future<void> logWorkoutCompleted({
    int? durationMinutes,
    double? totalVolume,
    int? exerciseCount,
  }) async => _track();

  /// Logs when a workout session is cancelled.
  /// [durationMinutes] - How long before cancellation
  Future<void> logWorkoutCancelled({int? durationMinutes}) async => _track();

  /// Logs when a set is logged during workout.
  /// [exerciseName] - Name of the exercise
  /// [isPR] - Whether this set was a personal record
  Future<void> logSetLogged({String? exerciseName, bool? isPR}) async =>
      _track();

  /// Logs when a personal record is achieved.
  /// [exerciseName] - Name of the exercise
  /// [weight] - Weight lifted
  /// [reps] - Number of reps
  Future<void> logPRAchieved({
    required String exerciseName,
    double? weight,
    int? reps,
  }) async => _track();

  /// Logs when a custom exercise is created.
  /// [category] - Exercise category
  Future<void> logExerciseCreated({String? category}) async => _track();

  /// Logs when progress charts are viewed.
  /// [timeRange] - Time range selected (1W, 1M, 3M, etc.)
  Future<void> logProgressViewed({String? timeRange}) async => _track();

  /// Logs when achievements page is viewed.
  Future<void> logAchievementsViewed() async => _track();

  /// Logs when an achievement is unlocked.
  /// [achievementType] - Type of achievement (streak, volume, etc.)
  /// [achievementId] - Achievement identifier
  Future<void> logAchievementUnlocked({
    required String achievementType,
    required String achievementId,
  }) async => _track();

  // INSIGHT MODULE EVENTS

  /// Logs when an insight is viewed.
  /// [insightType] - Type of insight (correlation, trend, etc.)
  /// [category] - Category (health, fitness, crossModule)
  /// [priority] - Insight priority (1-5)
  Future<void> logInsightViewed({
    required String insightType,
    String? category,
    int? priority,
  }) async => _track();

  /// Logs when an insight is dismissed.
  /// [insightType] - Type of insight dismissed
  Future<void> logInsightDismissed({required String insightType}) async =>
      _track();

  /// Logs when weekly report is viewed.
  /// [complianceRate] - Weekly medication compliance rate
  /// [workoutCount] - Number of workouts this week
  Future<void> logWeeklyReportViewed({
    double? complianceRate,
    int? workoutCount,
  }) async => _track();

  /// Logs when user provides feedback on an insight.
  /// [insightType] - Type of insight
  /// [helpful] - Whether user found it helpful
  Future<void> logInsightFeedback({
    required String insightType,
    required bool helpful,
  }) async => _track();

  // ENGAGEMENT EVENTS

  /// Logs when app is opened.
  /// [streakCount] - Current workout streak days
  Future<void> logAppOpened({int? streakCount}) async => _track();

  /// Logs when a notification is tapped.
  /// [notificationType] - Type of notification (medication, workout, etc.)
  Future<void> logNotificationTapped({String? notificationType}) async =>
      _track();

  /// Logs when user exports their data.
  Future<void> logDataExported() async => _track();

  /// Logs when user deletes their data.
  Future<void> logDataDeleted() async => _track();

  /// Logs when user changes theme.
  /// [theme] - New theme (light, dark, highContrast)
  Future<void> logThemeChanged({required String theme}) async => _track();

  /// Logs when user changes locale/language.
  /// [locale] - New locale code (en, tr, de)
  Future<void> logLocaleChanged({required String locale}) async => _track();

  // GDPR EVENTS

  /// Logs when consent is granted.
  /// [consentType] - Type of consent granted
  Future<void> logConsentGranted({required String consentType}) async =>
      _track();

  /// Logs when consent is revoked.
  /// [consentType] - Type of consent revoked
  Future<void> logConsentRevoked({required String consentType}) async =>
      _track();

  // USER PROPERTIES

  /// Sets user locale property.
  Future<void> setUserLocale(String locale) async => _track();

  /// Sets user theme property.
  Future<void> setUserTheme(String theme) async => _track();

  /// Sets unit system property (metric/imperial).
  Future<void> setUnitSystem(String unitSystem) async => _track();

  // SCREEN VIEW TRACKING

  /// Logs screen view event.
  /// [screenName] - Name of the screen
  /// [screenClass] - Optional class name of the screen
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async => _track();

  // INTERNAL

  /// No-op analytics sink.
  ///
  /// Retains the GDPR consent gate so the privacy contract is unchanged: when
  /// consent is absent we return early, exactly as before. With Pinpoint removed
  /// there is nothing left to send, so this never touches the network and can
  /// never throw. Wire a replacement backend in here to re-enable analytics
  /// without changing any call site.
  void _track() {
    if (!_gdprManager.canTrackAnalytics()) return;
    // Pinpoint sink removed — intentionally does nothing.
  }
}
