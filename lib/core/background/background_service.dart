/// VitalSync — Background Service.
///
/// WorkManager wrapper for scheduling and executing background tasks:
/// - Periodic: checkMissedMedications (hourly)
/// - Periodic: generateInsights (daily at 06:00)
/// - Periodic: syncPendingData (every 15 min, network required)
/// - Periodic: dailySummary (daily at 21:00)
/// - Periodic: streakWarning (daily at 20:00)
/// - OneTime: weeklyReportGeneration (Monday 07:00, self-re-scheduling)
library;

import 'dart:developer' show log;

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/local/database.dart';
import '../../data/repositories/fitness/exercise_repository_impl.dart';
import '../../data/repositories/fitness/personal_record_repository_impl.dart';
import '../../data/repositories/fitness/streak_repository_impl.dart';
import '../../data/repositories/fitness/workout_session_repository_impl.dart';
import '../../data/repositories/health/glucose_repository_impl.dart';
import '../../data/repositories/health/health_sample_repository_impl.dart';
import '../../data/repositories/health/meal_repository_impl.dart';
import '../../data/repositories/health/medication_log_repository_impl.dart';
import '../../data/repositories/health/medication_repository_impl.dart';
import '../../data/repositories/health/symptom_repository_impl.dart';
import '../../data/repositories/insights/insight_repository_impl.dart';
import '../../data/repositories/shared/calibration_metric_repository_impl.dart';
import '../../data/repositories/shared/cognito_auth_repository_impl.dart';
import '../../domain/repositories/shared/auth_repository.dart';
import '../../features/fitness/domain/services/streak_service.dart';
import '../../features/health/domain/services/calibration_metrics_service.dart';
import '../../features/health/domain/services/meal_data_coverage_service.dart';
import '../../features/insights/domain/insight_engine.dart';
import '../../features/insights/domain/weekly_report_service.dart';
import '../config/app_environment.dart';
import '../constants/app_constants.dart';
import '../enums/insight_priority.dart';
import '../enums/medication_log_status.dart';
import '../errors/exceptions.dart';
import '../health/apple_health_data_source.dart';
import '../health/health_import_service.dart';
import '../network/connectivity_service.dart';
import '../sync/cloud_sync_client.dart';
import '../sync/rest_sync_client.dart';
import '../sync/sync_service.dart';

/// Background Service for VitalSync.
///
/// Manages all background tasks using WorkManager for periodic operations
/// like medication checks, insight generation, data sync, daily summaries,
/// streak warnings, and weekly report generation.
class BackgroundService {
  BackgroundService({required Workmanager workmanager})
    : _workmanager = workmanager;

  final Workmanager _workmanager;

  /// Initializes the background service.
  ///
  /// Registers the callback dispatcher for background tasks.
  /// Should be called once during app initialization.
  Future<void> initialize() async {
    await _workmanager.initialize(callbackDispatcher);
    log('BackgroundService initialized');
  }

  /// Schedules all periodic background tasks.
  ///
  /// Convenience method to register every recurring task at once.
  /// Should be called after [initialize].
  Future<void> scheduleAllPeriodicTasks() async {
    await scheduleCheckMissedMedications();
    await scheduleGenerateInsights();
    await scheduleSyncPendingData();
    await scheduleDailySummary();
    await scheduleStreakWarning();
    await scheduleWeeklyReport();
    await scheduleImportHealthData();
    log('All periodic background tasks scheduled');
  }

  // HEALTH: Missed Medication Checks

  /// Schedules periodic check for missed medications.
  ///
  /// Runs every **1 hour**. No network required.
  /// The callback queries the local database for today's medications,
  /// compares with logged doses, and fires a missed-notification for each gap.
  Future<void> scheduleCheckMissedMedications() async {
    await _workmanager.registerPeriodicTask(
      AppConstants.taskCheckMissedMedications,
      AppConstants.taskCheckMissedMedications,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      tag: 'health',
    );
  }

  // INSIGHTS: Daily Insight Generation

  /// Schedules daily insight generation.
  ///
  /// Runs every **24 hours** with an initial delay calculated to start
  /// at the next occurrence of 06:00 local time.
  Future<void> scheduleGenerateInsights() async {
    final initialDelay = _delayUntilNextHour(
      AppConstants.insightGenerationHour,
    );

    await _workmanager.registerPeriodicTask(
      AppConstants.taskGenerateInsights,
      AppConstants.taskGenerateInsights,
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      tag: 'insights',
    );
  }

  // SYNC: Pending Data Sync

  /// Schedules periodic data synchronization.
  ///
  /// Runs every **15 minutes** when online. Pushes pending sync queue
  /// items to cloud.
  Future<void> scheduleSyncPendingData() async {
    await _workmanager.registerPeriodicTask(
      AppConstants.taskSyncPendingData,
      AppConstants.taskSyncPendingData,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      tag: 'sync',
    );
  }

  // HEALTH: Daily Summary

  /// Schedules the daily summary notification.
  ///
  /// Runs every **24 hours** with an initial delay to fire at 21:00.
  Future<void> scheduleDailySummary() async {
    final initialDelay = _delayUntilNextHour(AppConstants.dailySummaryHour);

    await _workmanager.registerPeriodicTask(
      AppConstants.taskDailySummary,
      AppConstants.taskDailySummary,
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      tag: 'health',
    );
  }

  // FITNESS: Streak Warning

  /// Schedules the daily streak warning check.
  ///
  /// Runs every **24 hours** with an initial delay to fire at 20:00.
  /// If the user has a streak and hasn't worked out today, fires a warning.
  Future<void> scheduleStreakWarning() async {
    final initialDelay = _delayUntilNextHour(AppConstants.streakWarningHour);

    await _workmanager.registerPeriodicTask(
      AppConstants.taskStreakWarning,
      AppConstants.taskStreakWarning,
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      tag: 'fitness',
    );
  }

  // INSIGHTS: Weekly Report Generation

  /// Schedules a one-time weekly report generation task.
  ///
  /// Fires at the next **Monday 07:00**. The callback should re-schedule
  /// itself after execution to create a recurring pattern.
  Future<void> scheduleWeeklyReport() async {
    final initialDelay = _delayUntilNextDayAndHour(
      AppConstants.weeklyReportDayOfWeek,
      AppConstants.weeklyReportHour,
    );

    await _workmanager.registerOneOffTask(
      AppConstants.taskWeeklyReport,
      AppConstants.taskWeeklyReport,
      initialDelay: initialDelay,
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      tag: 'insights',
    );
  }

  // HEALTH: Apple Health Import

  /// Schedules the periodic Apple Health import.
  ///
  /// Runs every **3 hours**. No network required — the platform health store
  /// is local. Complements the foreground import in `HealthLifecycleObserver`
  /// so a user who rarely opens the app still accumulates samples.
  Future<void> scheduleImportHealthData() async {
    await _workmanager.registerPeriodicTask(
      AppConstants.taskImportHealthData,
      AppConstants.taskImportHealthData,
      frequency: const Duration(hours: 3),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      tag: 'health',
    );
  }

  // TASK CANCELLATION

  /// Cancels all background tasks.
  Future<void> cancelAllTasks() async {
    await _workmanager.cancelAll();
    log('All background tasks cancelled');
  }

  /// Cancels a specific background task by its unique name.
  Future<void> cancelTask(String taskName) async {
    await _workmanager.cancelByUniqueName(taskName);
  }

  /// Cancels all tasks with the given tag.
  Future<void> cancelTasksByTag(String tag) async {
    await _workmanager.cancelByTag(tag);
  }

  // INTERNAL HELPERS

  /// Calculates the duration from now until the next occurrence of [hour]:00.
  Duration _delayUntilNextHour(int hour) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour);

    if (target.isBefore(now) || target.isAtSameMomentAs(now)) {
      target = target.add(const Duration(days: 1));
    }

    return target.difference(now);
  }

  /// Calculates the duration from now until the next [dayOfWeek] at [hour]:00.
  ///
  /// [dayOfWeek] uses Dart's DateTime constants (Monday = 1, Sunday = 7).
  Duration _delayUntilNextDayAndHour(int dayOfWeek, int hour) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour);

    // Find the next occurrence of the target day
    var daysUntilTarget = dayOfWeek - now.weekday;
    if (daysUntilTarget < 0) {
      daysUntilTarget += 7;
    } else if (daysUntilTarget == 0 && target.isBefore(now)) {
      daysUntilTarget = 7;
    }

    target = target.add(Duration(days: daysUntilTarget));
    return target.difference(now);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Background Dependency Container
// ═════════════════════════════════════════════════════════════════════════════

/// Lightweight dependency container for the background isolate.
///
/// Since WorkManager tasks run in an isolated context without access to
/// the main app's GetIt container, this class bootstraps only the
/// minimal dependencies needed for each background task.
///
/// Uses [_BackgroundNotificationHelper] instead of the full
/// [NotificationService] to avoid pulling in analytics and
/// GDPRManager, which aren't available in the background isolate.
class _BackgroundDeps {
  _BackgroundDeps._(this.db, this.notifications);

  final AppDatabase db;
  final _BackgroundNotificationHelper notifications;

  /// Creates a new [_BackgroundDeps] with a fresh database connection
  /// and a pre-initialized notification helper.
  /// Also configures Amplify for the background isolate if needed.
  static Future<_BackgroundDeps> init() async {
    final db = AppDatabase.connect();
    final notifHelper = await _BackgroundNotificationHelper.init();

    // Configure Amplify for background isolate (sync task needs it)
    if (!Amplify.isConfigured) {
      try {
        await Amplify.addPlugins([AmplifyAuthCognito(), AmplifyAPI()]);
        await Amplify.configure(AppEnvironment.amplifyConfig);
      } catch (e) {
        log('Amplify configuration in background isolate: $e');
      }
    }

    return _BackgroundDeps._(db, notifHelper);
  }

  /// Releases resources. Must be called when the task finishes.
  Future<void> dispose() async {
    await db.close();
  }
}

/// A minimal notification helper for background tasks.
///
/// Provides only the notification methods needed by the background task
/// handlers, using [FlutterLocalNotificationsPlugin] directly.
/// This avoids depending on [AnalyticsService] / [GDPRManager],
/// none of which are available in the WorkManager isolate.
class _BackgroundNotificationHelper {
  _BackgroundNotificationHelper._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<_BackgroundNotificationHelper> init() async {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await plugin.initialize(settings: initSettings);

    return _BackgroundNotificationHelper._(plugin);
  }

  // ── Notification details ──────────────────────────────────────────────

  NotificationDetails _medicationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_channel',
        'Medication Reminders',
        channelDescription: 'Notifications for medication reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  NotificationDetails _insightDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'insight_channel',
        'Insights',
        channelDescription: 'Health and fitness insights',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  NotificationDetails _workoutDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'workout_channel',
        'Workout',
        channelDescription: 'Workout and fitness notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // ── Notification methods matching the NotificationService API ─────────

  Future<void> showMissedMedicationNotification({
    required int medicationId,
    required String medicationName,
    required String scheduledTime,
  }) async {
    final notifId = 50000 + medicationId;
    await _plugin.show(
      id: notifId,
      title: 'Missed Medication ⚠️',
      body: 'You missed $medicationName scheduled at $scheduledTime',
      notificationDetails: _medicationDetails(),
      payload: 'medication:$medicationId',
    );
  }

  Future<void> showDailySummary({
    required int taken,
    required int missed,
    required int total,
  }) async {
    final percentage = total > 0 ? ((taken / total) * 100).round() : 0;
    final emoji = percentage == 100
        ? '🎉'
        : percentage >= 80
        ? '👍'
        : '📋';

    await _plugin.show(
      id: 90000,
      title: 'Daily Summary $emoji',
      body:
          'Medications: $taken/$total taken ($percentage%). '
          '${missed > 0 ? '$missed missed.' : 'Perfect compliance!'}',
      notificationDetails: _insightDetails(),
      payload: 'daily_summary',
    );
  }

  Future<void> showStreakWarning(int currentStreak) async {
    if (currentStreak <= 0) return;

    await _plugin.show(
      id: 70000,
      title: 'Streak at Risk! 🔥',
      body:
          'Your $currentStreak-day streak is about to break. '
          'Log a workout today to keep it going!',
      notificationDetails: _workoutDetails(),
      payload: 'streak:$currentStreak',
    );
  }

  Future<void> showWeeklyReportReady() async {
    await _plugin.show(
      id: 80000,
      title: 'Weekly Report Ready 📊',
      body:
          'Your health & fitness summary for last week is ready. '
          'Tap to view your progress!',
      notificationDetails: _insightDetails(),
      payload: 'weekly_report',
    );
  }

  Future<void> showImportantInsight({
    required int insightId,
    required String title,
    required String message,
    required InsightPriority priority,
  }) async {
    if (priority.value < InsightPriority.high.value) return;

    final notifId = 81000 + insightId.abs() % 1000;
    final emoji = priority == InsightPriority.critical ? '🚨' : '💡';

    await _plugin.show(
      id: notifId,
      title: '$emoji $title',
      body: message,
      notificationDetails: _insightDetails(),
      payload: 'insight:$insightId',
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WorkManager Callback Dispatcher (top-level function)
// ═════════════════════════════════════════════════════════════════════════════

/// Top-level callback dispatcher for WorkManager background tasks.
///
/// This function is called by the OS when a background task fires.
/// It must be a top-level function or static method.
///
/// Each task case initializes only the minimal dependencies it needs
/// to perform its work. Heavy operations (insight generation, sync)
/// should be performed efficiently since background execution time
/// is limited by the OS.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log('Background task executing: $task');

    _BackgroundDeps? deps;

    try {
      // Bootstrap shared dependencies (database + notification service)
      deps = await _BackgroundDeps.init();

      switch (task) {
        // ─── HEALTH: Check Missed Medications ───────────────────────
        case AppConstants.taskCheckMissedMedications:
          await _handleCheckMissedMedications(deps);
          break;

        // ─── INSIGHTS: Generate Daily Insights ──────────────────────
        case AppConstants.taskGenerateInsights:
          await _handleGenerateInsights(deps);
          break;

        // ─── SYNC: Push Pending Data ────────────────────────────────
        case AppConstants.taskSyncPendingData:
          await _handleSyncPendingData(deps);
          break;

        // ─── HEALTH: Daily Summary ──────────────────────────────────
        case AppConstants.taskDailySummary:
          await _handleDailySummary(deps);
          break;

        // ─── FITNESS: Streak Warning ────────────────────────────────
        case AppConstants.taskStreakWarning:
          await _handleStreakWarning(deps);
          break;

        // ─── INSIGHTS: Weekly Report ────────────────────────────────
        case AppConstants.taskWeeklyReport:
          await _handleWeeklyReport(deps);
          break;

        // ─── HEALTH: Apple Health Import ────────────────────────────
        case AppConstants.taskImportHealthData:
          await _handleImportHealthData(deps);
          break;

        default:
          log('Unknown background task: $task');
      }
    } catch (e, stackTrace) {
      log('Background task "$task" failed: $e\n$stackTrace');
      return false;
    } finally {
      await deps?.dispose();
    }

    return true;
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// Task Handlers
// ═════════════════════════════════════════════════════════════════════════════

/// Checks for missed medications and sends notifications for each gap.
///
/// 1. Fetches today's active medications and their scheduled times
/// 2. Fetches today's medication logs
/// 3. For each medication whose scheduled time has passed without a
///    corresponding "taken" log, fires a missed-medication notification
Future<void> _handleCheckMissedMedications(_BackgroundDeps deps) async {
  log('Checking for missed medications...');

  final medRepo = MedicationRepositoryImpl(deps.db.medicationDao);
  final logRepo = MedicationLogRepositoryImpl(deps.db.medicationLogDao);

  // Get active medications
  final activeMeds = await medRepo.getActive();
  if (activeMeds.isEmpty) {
    log('No active medications, skipping missed check');
    return;
  }

  // Get today's logs
  final todayLogs = await logRepo.getTodayLogs();

  // Build a set of medication IDs that have been taken today
  final takenMedIds = <int>{};
  for (final logEntry in todayLogs) {
    if (logEntry.status == MedicationLogStatus.taken) {
      takenMedIds.add(logEntry.medicationId);
    }
  }

  final now = DateTime.now();

  // Check each active medication
  for (final med in activeMeds) {
    // Skip if already taken today
    if (takenMedIds.contains(med.id)) continue;

    // Check if any scheduled time has passed
    for (final scheduledTime in med.times) {
      // Parse the time string (expected format: "HH:mm")
      final parts = scheduledTime.split(':');
      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Only notify if the scheduled time has passed (with 30-min grace)
      final gracePeriod = scheduledDateTime.add(const Duration(minutes: 30));
      if (now.isAfter(gracePeriod)) {
        await deps.notifications.showMissedMedicationNotification(
          medicationId: med.id,
          medicationName: med.name,
          scheduledTime: scheduledTime,
        );
        log(
          'Missed medication notification sent: ${med.name} at $scheduledTime',
        );
        // Only notify once per medication (first missed slot)
        break;
      }
    }
  }
}

/// Generates daily insights and notifies the user of important ones.
///
/// 1. Builds the InsightEngine with all required repositories
/// 2. Runs all insight generation rules
/// 3. Fires a notification for any high/critical priority insights
Future<void> _handleGenerateInsights(_BackgroundDeps deps) async {
  log('Generating daily insights...');

  final medLogRepo = MedicationLogRepositoryImpl(deps.db.medicationLogDao);
  final workoutRepo = WorkoutSessionRepositoryImpl(deps.db.workoutSessionDao);
  final symptomRepo = SymptomRepositoryImpl(deps.db.symptomDao);
  final insightRepo = InsightRepositoryImpl(deps.db.insightDao);
  final prRepo = PersonalRecordRepositoryImpl(deps.db.personalRecordDao);
  final streakRepo = StreakRepositoryImpl(
    deps.db.userStatsDao,
    deps.db.workoutSessionDao,
  );
  final exerciseRepo = ExerciseRepositoryImpl(deps.db.exerciseDao);

  final engine = InsightEngine(
    medicationLogRepository: medLogRepo,
    workoutRepository: workoutRepo,
    symptomRepository: symptomRepo,
    insightRepository: insightRepo,
    personalRecordRepository: prRepo,
    streakRepository: streakRepo,
    exerciseRepository: exerciseRepo,
  );

  final newInsights = await engine.generateAllInsights();
  log('Generated ${newInsights.length} new insights');

  // Notify user about high/critical priority insights
  for (final insight in newInsights) {
    if (insight.priority.value >= InsightPriority.high.value) {
      await deps.notifications.showImportantInsight(
        insightId: insight.id,
        title: insight.title,
        message: insight.message,
        priority: insight.priority,
      );
    }
  }
}

/// Syncs pending local changes to the cloud.
///
/// 1. Creates a SyncService with cloud client and connectivity dependencies
/// 2. Calls sync() which handles push/pull logic internally
///
/// NOTE: Background isolate cannot access GetIt, so we create instances
/// directly here. Uses RestSyncClient (AWS) and CognitoAuthRepositoryImpl.
Future<void> _handleSyncPendingData(_BackgroundDeps deps) async {
  log('Syncing pending data...');

  final connectivity = ConnectivityService(connectivity: Connectivity());

  // Create cloud sync client and auth repo for background isolate
  final CloudSyncClient cloudClient = RestSyncClient();
  final AuthRepository authRepo = CognitoAuthRepositoryImpl();

  final syncService = SyncService(
    database: deps.db,
    cloudClient: cloudClient,
    auth: authRepo,
    connectivity: connectivity,
  );

  try {
    await syncService.sync();
    log('Data sync completed successfully');
  } finally {
    await connectivity.dispose();
  }
}

/// Generates and shows the daily medication summary notification.
///
/// 1. Fetches today's medication logs
/// 2. Counts taken, missed, and total medications
/// 3. Shows a summary notification with adherence stats
Future<void> _handleDailySummary(_BackgroundDeps deps) async {
  log('Generating daily summary notification...');

  final logRepo = MedicationLogRepositoryImpl(deps.db.medicationLogDao);
  final todayLogs = await logRepo.getTodayLogs();

  if (todayLogs.isEmpty) {
    log('No medication logs today, skipping daily summary');
    return;
  }

  final taken = todayLogs
      .where((l) => l.status == MedicationLogStatus.taken)
      .length;
  final missed = todayLogs
      .where(
        (l) =>
            l.status == MedicationLogStatus.missed ||
            l.status == MedicationLogStatus.skipped,
      )
      .length;
  final total = todayLogs.length;

  await deps.notifications.showDailySummary(
    taken: taken,
    missed: missed,
    total: total,
  );
  log('Daily summary sent: $taken/$total taken, $missed missed');
}

/// Checks if the user's fitness streak is at risk and warns them.
///
/// 1. Uses StreakService to check if user has worked out today
/// 2. If they have a streak > 0 but haven't worked out, sends a warning
Future<void> _handleStreakWarning(_BackgroundDeps deps) async {
  log('Checking streak warning conditions...');

  final streakRepo = StreakRepositoryImpl(
    deps.db.userStatsDao,
    deps.db.workoutSessionDao,
  );
  final workoutRepo = WorkoutSessionRepositoryImpl(deps.db.workoutSessionDao);

  final streakService = StreakService(
    streakRepository: streakRepo,
    workoutRepository: workoutRepo,
  );

  final isActive = await streakService.isStreakActiveToday();
  if (isActive) {
    log('Streak is active today, no warning needed');
    return;
  }

  final currentStreak = await streakService.getCurrentStreak();
  if (currentStreak <= 0) {
    log('No active streak, skipping warning');
    return;
  }

  // User has a streak but hasn't worked out today — warn them
  await deps.notifications.showStreakWarning(currentStreak);
  log('Streak warning sent: $currentStreak-day streak at risk');
}

/// Imports new Apple Health samples into the local database.
///
/// Builds its own [HealthImportService] because the WorkManager isolate has no
/// access to GetIt. A missing authorization is the expected quiet case: the
/// import throws [HealthDataException], which is logged and swallowed so the
/// task is not reported as failed and rescheduled aggressively.
Future<void> _handleImportHealthData(_BackgroundDeps deps) async {
  log('Importing Apple Health samples...');

  final importService = HealthImportService(
    source: AppleHealthDataSource(),
    glucoseDao: deps.db.glucoseDao,
    healthSampleDao: deps.db.healthSampleDao,
  );

  try {
    final result = await importService.import();
    log('Apple Health import completed: $result');
  } on HealthDataException catch (e) {
    log('Apple Health import skipped: $e');
  }
}

/// Generates the weekly report and sends a notification.
///
/// 1. Builds the WeeklyReportService with all repositories
/// 2. Generates the current week's report
/// 3. Shows a "report ready" notification
/// 4. Re-schedules itself for next Monday
Future<void> _handleWeeklyReport(_BackgroundDeps deps) async {
  log('Generating weekly report...');

  final medLogRepo = MedicationLogRepositoryImpl(deps.db.medicationLogDao);
  final workoutRepo = WorkoutSessionRepositoryImpl(deps.db.workoutSessionDao);
  final symptomRepo = SymptomRepositoryImpl(deps.db.symptomDao);
  final insightRepo = InsightRepositoryImpl(deps.db.insightDao);
  final prRepo = PersonalRecordRepositoryImpl(deps.db.personalRecordDao);
  final streakRepo = StreakRepositoryImpl(
    deps.db.userStatsDao,
    deps.db.workoutSessionDao,
  );

  final mealRepo = MealRepositoryImpl(deps.db.mealDao, deps.db);
  final glucoseRepo = GlucoseRepositoryImpl(deps.db.glucoseDao, deps.db);
  final coverageService = MealDataCoverageService(
    mealRepository: mealRepo,
    glucoseRepository: glucoseRepo,
    healthSampleRepository: HealthSampleRepositoryImpl(
      deps.db.healthSampleDao,
    ),
  );

  final reportService = WeeklyReportService(
    medicationLogRepository: medLogRepo,
    workoutRepository: workoutRepo,
    symptomRepository: symptomRepo,
    insightRepository: insightRepo,
    personalRecordRepository: prRepo,
    streakRepository: streakRepo,
    mealRepository: mealRepo,
    glucoseRepository: glucoseRepo,
    coverageService: coverageService,
    exerciseRepository: ExerciseRepositoryImpl(deps.db.exerciseDao),
  );

  await reportService.generateCurrentWeekReport();
  log('Weekly report generated successfully');

  // Opt-in calibration counters ride along with the weekly task. Isolated
  // so a failure here cannot cost the user their report or the
  // re-scheduling below.
  try {
    await _collectCalibrationMetrics(deps, mealRepo, glucoseRepo, coverageService);
  } catch (e) {
    log('Calibration metrics collection skipped: $e');
  }

  // Notify user
  await deps.notifications.showWeeklyReportReady();

  // Re-schedule for next week
  await Workmanager().registerOneOffTask(
    AppConstants.taskWeeklyReport,
    AppConstants.taskWeeklyReport,
    initialDelay: const Duration(days: 7),
    constraints: Constraints(networkType: NetworkType.notRequired),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    tag: 'insights',
  );
  log('Weekly report re-scheduled for next week');
}

/// Collects the opt-in calibration counters for the week that just ended.
///
/// The week is the completed one, not the current partial week: the task
/// fires mid-week and a partial tally would misstate how much was recorded.
/// Re-running is safe — the service upserts by week start.
///
/// Consent is read straight from preferences here. [GDPRManager] is not
/// available in this isolate (it needs the cloud client, auth and the app's
/// database), but the flag it writes is just a bool in the same store.
Future<void> _collectCalibrationMetrics(
  _BackgroundDeps deps,
  MealRepositoryImpl mealRepo,
  GlucoseRepositoryImpl glucoseRepo,
  MealDataCoverageService coverageService,
) async {
  final prefs = await SharedPreferences.getInstance();
  final consented =
      prefs.getBool(AppConstants.prefKeyCalibrationMetricsConsent) ?? false;

  final metricsService = CalibrationMetricsService(
    coverageService: coverageService,
    mealRepository: mealRepo,
    glucoseRepository: glucoseRepo,
    metricRepository: CalibrationMetricRepositoryImpl(
      deps.db.calibrationMetricDao,
      deps.db,
    ),
    isConsentGranted: () => consented,
    appVersion: AppConstants.appVersion,
  );

  final weekStart = _startOfWeek(
    DateTime.now(),
  ).subtract(const Duration(days: 7));

  final metric = await metricsService.collectForWeek(weekStart);
  if (metric == null) {
    log('Calibration metrics consent is off, nothing collected');
    return;
  }
  // Counts only — the row itself is never logged.
  log('Calibration metrics collected for week starting $weekStart');
}

/// Monday of the week [date] falls in, at midnight local time.
DateTime _startOfWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}
