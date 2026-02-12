/// VitalSync — Background Service.
/// WorkManager wrapper for background task scheduling.
/// Handles periodic medication reminder checks and sync operations.
library;

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

/// Background Service for VitalSync.
/// Manages background tasks using WorkManager for periodic operations
/// like medication reminder checks and data synchronization.
class BackgroundService {
  BackgroundService({required Workmanager workmanager})
    : _workmanager = workmanager;
  final Workmanager _workmanager;

  /// Initializes the background service.
  /// Registers the callback dispatcher for background tasks.
  /// Should be called once during app initialization.
  Future<void> initialize() async {
    // WorkManager callback is imported from notification_service.dart
    // since it needs to access notification scheduling logic
    await _workmanager.initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  /// Schedules periodic medication reminder checks.
  /// Runs every 15 minutes to check for upcoming medication reminders
  /// and schedule notifications accordingly.
  Future<void> scheduleMedicationReminderCheck() async {
    await _workmanager.registerPeriodicTask(
      'medicationReminderCheck',
      'medicationReminderCheck',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// Schedules periodic background sync.
  /// Syncs local data with Firestore when connected to WiFi.
  Future<void> scheduleBackgroundSync() async {
    await _workmanager.registerPeriodicTask(
      'syncTask',
      'syncTask',
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// Cancels all background tasks.
  Future<void> cancelAllTasks() async {
    await _workmanager.cancelAll();
  }

  /// Cancels a specific background task.
  Future<void> cancelTask(String taskName) async {
    await _workmanager.cancelByUniqueName(taskName);
  }
}

/// Callback dispatcher for WorkManager background tasks.
/// This must be a top-level function or static method.
/// Import from notification_service.dart where full implementation exists.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // TODO: Implement full background task logic
    // For now, this is a minimal placeholder
    print('Background task executed: $task');
    return Future.value(true);
  });
}
