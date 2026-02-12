/// VitalSync — GetIt Dependency Injection Setup.
///
/// Registers all services, repositories, and external dependencies.
/// Lazy singleton pattern with async initialization.
/// DI = GetIt, State = Riverpod (separation of concerns).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/local/database.dart';
import '../../data/repositories/fitness/workout_repository_impl.dart';
import '../../data/repositories/health/medication_repository_impl.dart';
import '../../data/repositories/insights/insight_repository_impl.dart';
import '../../data/repositories/shared/user_repository_impl.dart';
import '../../domain/repositories/fitness/workout_repository.dart';
import '../../domain/repositories/health/medication_repository.dart';
import '../../domain/repositories/insights/insight_repository.dart';
import '../../domain/repositories/shared/user_repository.dart';
import '../../features/fitness/domain/services/achievement_service.dart';
import '../../features/fitness/domain/services/streak_service.dart';
import '../../features/health/domain/services/medication_reminder_service.dart';
import '../../features/insights/domain/insight_engine.dart';
import '../../features/insights/domain/weekly_report_service.dart';
import '../analytics/analytics_service.dart';
import '../background/background_service.dart';
import '../gdpr/gdpr_manager.dart';
import '../network/connectivity_service.dart';
import '../notifications/notification_service.dart';
import '../sync/sync_service.dart';

/// The GetIt service locator instance.
final getIt = GetIt.instance;

/// Initializes all dependencies asynchronously.
///
/// Must be called once before running the app, typically in main().
/// Registers all services, repositories, and external dependencies
/// in the correct order (dependencies before dependents).
///
/// Returns a Future that completes when initialization is done.
Future<void> initializeDependencies() async {
  // ========================================================================
  // CORE DEPENDENCIES (External)
  // ========================================================================

  // SharedPreferences - Async singleton
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Firebase instances - Lazy singletons
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<FirebaseAnalytics>(
    () => FirebaseAnalytics.instance,
  );

  // Connectivity - Lazy singleton
  getIt.registerLazySingleton<Connectivity>(Connectivity.new);

  // FlutterLocalNotificationsPlugin - Lazy singleton
  getIt.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    FlutterLocalNotificationsPlugin.new,
  );

  // Workmanager - Lazy singleton
  getIt.registerLazySingleton<Workmanager>(Workmanager.new);

  // ========================================================================
  // DATABASE
  // ========================================================================

  // Drift AppDatabase - Singleton
  // Database is created immediately to ensure it's ready for use
  getIt.registerSingleton<AppDatabase>(AppDatabase.connect());

  // ========================================================================
  // SHARED SERVICES
  // ========================================================================

  // GDPRManager - Lazy singleton
  getIt.registerLazySingleton<GDPRManager>(
    () => GDPRManager(
      prefs: getIt<SharedPreferences>(),
      firestore: getIt<FirebaseFirestore>(),
      auth: getIt<FirebaseAuth>(),
    ),
  );

  // AnalyticsService - Lazy singleton
  getIt.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService(
      analytics: getIt<FirebaseAnalytics>(),
      gdprManager: getIt<GDPRManager>(),
    ),
  );

  // NotificationService - Lazy singleton
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(
      notifications: getIt<FlutterLocalNotificationsPlugin>(),
    ),
  );

  // BackgroundService - Lazy singleton
  getIt.registerLazySingleton<BackgroundService>(
    () => BackgroundService(workmanager: getIt<Workmanager>()),
  );

  // ConnectivityService - Lazy singleton
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(connectivity: getIt<Connectivity>()),
  );

  // SyncService - Lazy singleton
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
      auth: getIt<FirebaseAuth>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  // ========================================================================
  // SHARED REPOSITORIES
  // ========================================================================

  // AuthRepository - Lazy singleton
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      auth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // UserRepository - Lazy singleton
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
      auth: getIt<FirebaseAuth>(),
      gdprManager: getIt<GDPRManager>(),
    ),
  );

  // ========================================================================
  // HEALTH MODULE - Repositories
  // ========================================================================

  // MedicationRepository - Lazy singleton
  getIt.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // MedicationLogRepository - Lazy singleton
  getIt.registerLazySingleton<MedicationLogRepository>(
    () => MedicationLogRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // SymptomRepository - Lazy singleton
  getIt.registerLazySingleton<SymptomRepository>(
    () => SymptomRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // ========================================================================
  // HEALTH MODULE - Services
  // ========================================================================

  // MedicationReminderService - Lazy singleton
  getIt.registerLazySingleton<MedicationReminderService>(
    () => MedicationReminderService(
      notificationService: getIt<NotificationService>(),
      medicationRepository:
          getIt<MedicationRepository>() as MedicationRepositoryImpl,
    ),
  );

  // ========================================================================
  // FITNESS MODULE - Repositories
  // ========================================================================

  // ExerciseRepository - Lazy singleton
  getIt.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // WorkoutTemplateRepository - Lazy singleton
  getIt.registerLazySingleton<WorkoutTemplateRepository>(
    () => WorkoutTemplateRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // WorkoutSessionRepository - Lazy singleton
  getIt.registerLazySingleton<WorkoutSessionRepository>(
    () => WorkoutSessionRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // PersonalRecordRepository - Lazy singleton
  getIt.registerLazySingleton<PersonalRecordRepository>(
    () => PersonalRecordRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // StreakRepository - Lazy singleton
  getIt.registerLazySingleton<StreakRepository>(
    () => StreakRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // AchievementRepository - Lazy singleton
  getIt.registerLazySingleton<AchievementRepository>(
    () => AchievementRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // ========================================================================
  // FITNESS MODULE - Services
  // ========================================================================

  // StreakService - Lazy singleton
  getIt.registerLazySingleton<StreakService>(
    () => StreakService(
      streakRepository: getIt<StreakRepository>() as StreakRepositoryImpl,
      workoutRepository:
          getIt<WorkoutSessionRepository>() as WorkoutSessionRepositoryImpl,
    ),
  );

  // AchievementService - Lazy singleton
  getIt.registerLazySingleton<AchievementService>(
    () => AchievementService(
      achievementRepository:
          getIt<AchievementRepository>() as AchievementRepositoryImpl,
      workoutRepository:
          getIt<WorkoutSessionRepository>() as WorkoutSessionRepositoryImpl,
      medicationLogRepository:
          getIt<MedicationLogRepository>() as MedicationLogRepositoryImpl,
      notificationService: getIt<NotificationService>(),
      analyticsService: getIt<AnalyticsService>(),
    ),
  );

  // ========================================================================
  // INSIGHTS MODULE - Repository
  // ========================================================================

  // InsightRepository - Lazy singleton
  getIt.registerLazySingleton<InsightRepository>(
    () => InsightRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // ========================================================================
  // INSIGHTS MODULE - Services
  // ========================================================================

  // InsightEngine - Lazy singleton
  getIt.registerLazySingleton<InsightEngine>(
    () => InsightEngine(
      medicationLogRepository:
          getIt<MedicationLogRepository>() as MedicationLogRepositoryImpl,
      workoutRepository:
          getIt<WorkoutSessionRepository>() as WorkoutSessionRepositoryImpl,
      symptomRepository: getIt<SymptomRepository>() as SymptomRepositoryImpl,
      insightRepository: getIt<InsightRepository>() as InsightRepositoryImpl,
    ),
  );

  // WeeklyReportService - Lazy singleton
  getIt.registerLazySingleton<WeeklyReportService>(
    () => WeeklyReportService(
      medicationLogRepository:
          getIt<MedicationLogRepository>() as MedicationLogRepositoryImpl,
      workoutRepository:
          getIt<WorkoutSessionRepository>() as WorkoutSessionRepositoryImpl,
      symptomRepository: getIt<SymptomRepository>() as SymptomRepositoryImpl,
      insightRepository: getIt<InsightRepository>() as InsightRepositoryImpl,
    ),
  );

  print('✅ All dependencies initialized successfully');
}

/// Disposes all registered dependencies.
///
/// Useful for testing or when reinitializing the DI container.
Future<void> disposeDependencies() async {
  // Close database connection
  if (getIt.isRegistered<AppDatabase>()) {
    await getIt<AppDatabase>().closeConnection();
  }

  // Stop connectivity service listening
  if (getIt.isRegistered<ConnectivityService>()) {
    await getIt<ConnectivityService>().dispose();
  }

  // Reset GetIt
  await getIt.reset();

  print('✅ All dependencies disposed');
}
