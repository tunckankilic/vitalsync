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

import 'package:workmanager/workmanager.dart';

import '../constants/app_constants.dart';

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
  /// items to Firestore.
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

    try {
      switch (task) {
        // ─── HEALTH: Check Missed Medications ───────────────────────
        case AppConstants.taskCheckMissedMedications:
          // In a full implementation, this would:
          // 1. Initialize the database
          // 2. Query today's active medications and their scheduled times
          // 3. Query today's medication logs
          // 4. Compare scheduled vs logged, identify missed medications
          // 5. Show a missed-medication notification for each gap
          log('Checking for missed medications...');
          // TODO: Wire up with database and notification service
          // when running in an isolate context.
          break;

        // ─── INSIGHTS: Generate Daily Insights ──────────────────────
        case AppConstants.taskGenerateInsights:
          // In a full implementation, this would:
          // 1. Initialize the database and repositories
          // 2. Run InsightEngine.generateAllInsights()
          // 3. Store new insights in the database
          // 4. Fire notification for any high-priority insights
          log('Generating daily insights...');
          break;

        // ─── SYNC: Push Pending Data ────────────────────────────────
        case AppConstants.taskSyncPendingData:
          // In a full implementation, this would:
          // 1. Initialize the database and Firestore
          // 2. Query the sync queue for pending items
          // 3. Push each item to Firestore
          // 4. Mark as completed or failed
          log('Syncing pending data...');
          break;

        // ─── HEALTH: Daily Summary ──────────────────────────────────
        case AppConstants.taskDailySummary:
          // In a full implementation, this would:
          // 1. Initialize the database
          // 2. Count today's taken, missed, and total medications
          // 3. Show a summary notification via NotificationService
          log('Generating daily summary notification...');
          break;

        // ─── FITNESS: Streak Warning ────────────────────────────────
        case AppConstants.taskStreakWarning:
          // In a full implementation, this would:
          // 1. Initialize the database
          // 2. Check current streak and whether user worked out today
          // 3. If streak > 0 and no workout today, show warning
          log('Checking streak warning conditions...');
          break;

        // ─── INSIGHTS: Weekly Report ────────────────────────────────
        case AppConstants.taskWeeklyReport:
          // In a full implementation, this would:
          // 1. Initialize the database and repositories
          // 2. Generate the weekly report via WeeklyReportService
          // 3. Show "Weekly Report Ready" notification
          // 4. Re-schedule itself for next Monday 07:00
          log('Generating weekly report...');

          // Re-schedule for next week
          await Workmanager().registerOneOffTask(
            AppConstants.taskWeeklyReport,
            AppConstants.taskWeeklyReport,
            initialDelay: const Duration(days: 7),
            constraints: Constraints(networkType: NetworkType.notRequired),
            existingWorkPolicy: ExistingWorkPolicy.replace,
            tag: 'insights',
          );
          break;

        default:
          log('Unknown background task: $task');
      }
    } catch (e, stackTrace) {
      log('Background task "$task" failed: $e\n$stackTrace');
      return false;
    }

    return true;
  });
}
