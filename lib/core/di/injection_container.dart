/// VitalSync — GetIt Dependency Injection Setup.
///
/// Registers all services, repositories, and external dependencies.
/// Lazy singleton pattern with async initialization.
/// DI = GetIt, State = Riverpod (separation of concerns).
///
/// Cloud provider abstracted via [CloudSyncClient] interface.
/// Uses [RestSyncClient] with AWS Lambda + DynamoDB.
library;

import 'dart:developer' show log;
import 'dart:ui' show Locale;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/local/database.dart';
import '../../data/local/seed_data.dart';
import '../../data/repositories/fitness/achievement_repository_impl.dart';
import '../../data/repositories/fitness/exercise_repository_impl.dart';
import '../../data/repositories/fitness/personal_record_repository_impl.dart';
import '../../data/repositories/fitness/streak_repository_impl.dart';
import '../../data/repositories/fitness/workout_session_repository_impl.dart';
import '../../data/repositories/fitness/workout_template_repository_impl.dart';
import '../../data/repositories/health/glucose_repository_impl.dart';
import '../../data/repositories/health/health_sample_repository_impl.dart';
import '../../data/repositories/health/meal_repository_impl.dart';
import '../../data/repositories/health/medication_log_repository_impl.dart';
// Repositories Implementations
import '../../data/repositories/health/medication_repository_impl.dart';
import '../../data/repositories/health/symptom_repository_impl.dart';
import '../../data/repositories/insights/insight_repository_impl.dart';
import '../../data/repositories/shared/calibration_metric_repository_impl.dart';
import '../../data/repositories/shared/cognito_auth_repository_impl.dart';
import '../../data/repositories/shared/sync_repository_impl.dart';
import '../../data/repositories/shared/user_repository_impl.dart';
import '../../domain/repositories/fitness/achievement_repository.dart';
import '../../domain/repositories/fitness/exercise_repository.dart';
import '../../domain/repositories/fitness/personal_record_repository.dart';
import '../../domain/repositories/fitness/streak_repository.dart';
import '../../domain/repositories/fitness/workout_session_repository.dart';
import '../../domain/repositories/fitness/workout_template_repository.dart';
import '../../domain/repositories/health/glucose_repository.dart';
import '../../domain/repositories/health/health_sample_repository.dart';
import '../../domain/repositories/health/meal_repository.dart';
import '../../domain/repositories/health/medication_log_repository.dart';
// Repository Interfaces
import '../../domain/repositories/health/medication_repository.dart';
import '../../domain/repositories/health/symptom_repository.dart';
import '../../domain/repositories/insights/insight_repository.dart';
import '../../domain/repositories/shared/auth_repository.dart';
import '../../domain/repositories/shared/calibration_metric_repository.dart';
import '../../domain/repositories/shared/sync_repository.dart';
import '../../domain/repositories/shared/user_repository.dart';
// Services
import '../../features/fitness/domain/services/achievement_service.dart';
import '../../features/fitness/domain/services/streak_service.dart';
import '../../features/health/domain/services/medication_reminder_service.dart';
import '../../features/insights/domain/insight_engine.dart';
import '../../features/insights/domain/weekly_report_service.dart';
import '../analytics/analytics_service.dart';
import '../auth/apple_token_revocation_service.dart';
import '../background/background_service.dart';
import '../config/app_environment.dart';
import '../constants/app_constants.dart';
import '../gdpr/gdpr_manager.dart';
import '../health/apple_health_data_source.dart';
import '../health/health_data_source.dart';
import '../health/health_import_service.dart';
import '../health/health_lifecycle_observer.dart';
import '../l10n/app_localizations.dart';
import '../network/connectivity_service.dart';
import '../notifications/notification_service.dart';
import '../sync/cloud_sync_client.dart';
import '../sync/rest_sync_client.dart';
import '../sync/sync_service.dart';

/// The GetIt service locator instance.
final getIt = GetIt.instance;

/// Initializes all dependencies asynchronously.
Future<void> initializeDependencies() async {
  // CORE DEPENDENCIES (External)

  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  getIt.registerLazySingleton<Connectivity>(Connectivity.new);
  getIt.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    FlutterLocalNotificationsPlugin.new,
  );
  getIt.registerLazySingleton<Workmanager>(Workmanager.new);

  // DATABASE

  getIt.registerSingleton<AppDatabase>(AppDatabase.connect());

  // Seed default data (exercises, default templates, achievements) on first
  // launch. Idempotent and non-critical: only runs when the exercises table is
  // empty, so existing users' data is never touched, and a seed failure is
  // logged rather than aborting app startup (graceful degrade). The same guard
  // also runs after every login (see AuthNotifier) to restore the catalogue
  // for a returning user whose local DB was wiped on sign-out.
  await seedDefaultDataIfEmpty(getIt<AppDatabase>());

  // CLOUD SYNC CLIENT (AWS REST API via Amplify)
  getIt.registerLazySingleton<CloudSyncClient>(RestSyncClient.new);

  // AUTH REPOSITORY (AWS Cognito via Amplify)
  //
  // The Apple token revocation service is injected so account deletion can
  // revoke the Sign in with Apple grant (App Store Guideline 5.1.1(v)). It is
  // inert unless APPLE_REVOKE_ENDPOINT is supplied at build time, so builds
  // without the dart-define keep the exact previous deletion behaviour.
  getIt.registerLazySingleton<AppleTokenRevocationService>(
    () => AppleTokenRevocationService(
      endpoint: AppEnvironment.appleRevokeEndpoint,
    ),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => CognitoAuthRepositoryImpl(
      revocationService: getIt<AppleTokenRevocationService>(),
    ),
  );

  // SHARED SERVICES

  getIt.registerLazySingleton<GDPRManager>(
    () => GDPRManager(
      prefs: getIt<SharedPreferences>(),
      cloudClient: getIt<CloudSyncClient>(),
      auth: getIt<AuthRepository>(),
      database: getIt<AppDatabase>(),
    ),
  );

  getIt.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService(gdprManager: getIt<GDPRManager>()),
  );

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(
      notifications: getIt<FlutterLocalNotificationsPlugin>(),
      analyticsService: getIt<AnalyticsService>(),
      resolveLocalizations: () => lookupAppLocalizations(
        Locale(
          getIt<SharedPreferences>().getString(AppConstants.prefKeyLocale) ??
              'en',
        ),
      ),
    ),
  );

  getIt.registerLazySingleton<BackgroundService>(
    () => BackgroundService(workmanager: getIt<Workmanager>()),
  );

  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(connectivity: getIt<Connectivity>()),
  );

  // HEALTH DATA IMPORT (Apple Health, read-only)

  getIt.registerLazySingleton<HealthDataSource>(AppleHealthDataSource.new);

  getIt.registerLazySingleton<HealthImportService>(
    () => HealthImportService(
      source: getIt<HealthDataSource>(),
      glucoseDao: getIt<AppDatabase>().glucoseDao,
      healthSampleDao: getIt<AppDatabase>().healthSampleDao,
    ),
  );

  getIt.registerLazySingleton<HealthLifecycleObserver>(
    () => HealthLifecycleObserver(
      importService: getIt<HealthImportService>(),
    ),
  );

  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      database: getIt<AppDatabase>(),
      cloudClient: getIt<CloudSyncClient>(),
      auth: getIt<AuthRepository>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  // SHARED REPOSITORIES

  getIt.registerLazySingleton<UserRepository>(
    () =>
        UserRepositoryImpl(getIt<AppDatabase>().userDao, getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(
      getIt<AppDatabase>().syncDao,
      getIt<CloudSyncClient>(),
      getIt<AppDatabase>(),
      getIt<AuthRepository>(),
    ),
  );

  // HEALTH MODULE - Repositories

  getIt.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(getIt<AppDatabase>().medicationDao),
  );

  getIt.registerLazySingleton<MedicationLogRepository>(
    () => MedicationLogRepositoryImpl(getIt<AppDatabase>().medicationLogDao),
  );

  getIt.registerLazySingleton<SymptomRepository>(
    () => SymptomRepositoryImpl(getIt<AppDatabase>().symptomDao),
  );

  getIt.registerLazySingleton<GlucoseRepository>(
    () => GlucoseRepositoryImpl(getIt<AppDatabase>().glucoseDao),
  );

  getIt.registerLazySingleton<MealRepository>(
    () => MealRepositoryImpl(getIt<AppDatabase>().mealDao),
  );

  getIt.registerLazySingleton<HealthSampleRepository>(
    () => HealthSampleRepositoryImpl(getIt<AppDatabase>().healthSampleDao),
  );

  getIt.registerLazySingleton<CalibrationMetricRepository>(
    () => CalibrationMetricRepositoryImpl(
      getIt<AppDatabase>().calibrationMetricDao,
    ),
  );

  // FITNESS MODULE - Repositories

  getIt.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(getIt<AppDatabase>().exerciseDao),
  );

  getIt.registerLazySingleton<WorkoutTemplateRepository>(
    () =>
        WorkoutTemplateRepositoryImpl(getIt<AppDatabase>().workoutTemplateDao),
  );

  getIt.registerLazySingleton<WorkoutSessionRepository>(
    () => WorkoutSessionRepositoryImpl(getIt<AppDatabase>().workoutSessionDao),
  );

  getIt.registerLazySingleton<PersonalRecordRepository>(
    () => PersonalRecordRepositoryImpl(getIt<AppDatabase>().personalRecordDao),
  );

  getIt.registerLazySingleton<StreakRepository>(
    () => StreakRepositoryImpl(
      getIt<AppDatabase>().userStatsDao,
      getIt<AppDatabase>().workoutSessionDao,
    ),
  );

  getIt.registerLazySingleton<AchievementRepository>(
    () => AchievementRepositoryImpl(getIt<AppDatabase>().achievementDao),
  );

  // INSIGHTS MODULE - Repository

  getIt.registerLazySingleton<InsightRepository>(
    () => InsightRepositoryImpl(getIt<AppDatabase>().insightDao),
  );

  // SERVICES (Dependent on Repositories)

  getIt.registerLazySingleton<MedicationReminderService>(
    () => MedicationReminderService(
      notificationService: getIt<NotificationService>(),
      medicationRepository: getIt<MedicationRepository>(),
      areNotificationsEnabled: () =>
          getIt<SharedPreferences>().getBool(
            AppConstants.prefKeyNotificationsEnabled,
          ) ??
          true,
    ),
  );

  getIt.registerLazySingleton<StreakService>(
    () => StreakService(
      streakRepository: getIt<StreakRepository>(),
      workoutRepository: getIt<WorkoutSessionRepository>(),
    ),
  );

  getIt.registerLazySingleton<AchievementService>(
    () => AchievementService(
      achievementRepository: getIt<AchievementRepository>(),
      workoutRepository: getIt<WorkoutSessionRepository>(),
      medicationLogRepository: getIt<MedicationLogRepository>(),
      notificationService: getIt<NotificationService>(),
      analyticsService: getIt<AnalyticsService>(),
    ),
  );

  getIt.registerLazySingleton<InsightEngine>(
    () => InsightEngine(
      medicationLogRepository: getIt<MedicationLogRepository>(),
      workoutRepository: getIt<WorkoutSessionRepository>(),
      symptomRepository: getIt<SymptomRepository>(),
      insightRepository: getIt<InsightRepository>(),
      personalRecordRepository: getIt<PersonalRecordRepository>(),
      streakRepository: getIt<StreakRepository>(),
      exerciseRepository: getIt<ExerciseRepository>(),
    ),
  );

  getIt.registerLazySingleton<WeeklyReportService>(
    () => WeeklyReportService(
      medicationLogRepository: getIt<MedicationLogRepository>(),
      workoutRepository: getIt<WorkoutSessionRepository>(),
      symptomRepository: getIt<SymptomRepository>(),
      insightRepository: getIt<InsightRepository>(),
      personalRecordRepository: getIt<PersonalRecordRepository>(),
      streakRepository: getIt<StreakRepository>(),
    ),
  );

  log(' All dependencies initialized successfully');
}

/// Seeds the default catalogue (exercises, templates, achievements) whenever
/// the local database is empty.
///
/// Invoked both at cold-start (above) and after every login (see
/// [AuthNotifier]); the post-login call restores the catalogue for a returning
/// user whose local database was wiped on sign-out (consent-gated) or lost to a
/// reinstall — without it the re-seed would only happen on the next cold start.
///
/// Idempotent: seeding runs solely when the exercises table is empty, so an
/// existing user's data is never re-seeded or overwritten, and a user who
/// deleted individual exercises keeps that choice. Non-critical: a failure is
/// logged and swallowed so it can never abort startup or a login.
Future<void> seedDefaultDataIfEmpty(AppDatabase db) async {
  try {
    final existing = await db.exerciseDao.getAll();
    if (existing.isEmpty) {
      await seedDatabase(db);
      log('Seeded default data (exercises, templates, achievements)');
    }
  } catch (e) {
    log('Default data seeding failed (non-critical): $e');
  }
}

Future<void> disposeDependencies() async {
  if (getIt.isRegistered<AppDatabase>()) {
    await getIt<AppDatabase>().closeConnection();
  }
  if (getIt.isRegistered<ConnectivityService>()) {
    await getIt<ConnectivityService>().dispose();
  }
  await getIt.reset();
  log(' All dependencies disposed');
}
