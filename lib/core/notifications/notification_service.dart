/// VitalSync — Notification Service.
/// Local notifications via flutter_local_notifications.
/// Background scheduling via WorkManager.
/// Medication reminders and workout reminders.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../constants/app_constants.dart';

/// Notification Service for VitalSync.
/// Handles local notifications for medication reminders, workout reminders,
/// and other app notifications using flutter_local_notifications.
/// Background tasks are scheduled via WorkManager.
class NotificationService {
  NotificationService({
    required FlutterLocalNotificationsPlugin notifications,
    Logger? logger,
  }) : _notifications = notifications,
       _logger = logger ?? Logger();
  final FlutterLocalNotificationsPlugin _notifications;
  final Logger _logger;

  /// Initializes the notification service.
  ///
  /// Sets up notification channels for Android and requests permissions.
  /// Must be called before using any notification features.
  Future<void> initialize() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Requests notification permissions from the user.
  ///
  /// Returns true if permissions are granted, false otherwise.
  Future<bool> requestPermissions() async {
    // iOS/macOS: Request permissions
    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+: Permissions are handled via AndroidManifest
    return iosResult ?? true;
  }

  // MEDICATION REMINDERS

  /// Schedules a medication reminder notification.
  ///
  /// [id] - Unique notification ID
  /// [medicationName] - Name of the medication
  /// [scheduledTime] - When to show the notification
  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
  }) async {
    await _notifications.zonedSchedule(
      id: id,
      title: 'Medication Reminder',
      body: 'Time to take: $medicationName',
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: _medicationNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'medication:$id',
    );
  }

  /// Cancels a medication reminder notification.
  Future<void> cancelMedicationReminder(int id) async {
    await _notifications.cancel(id: id);
  }

  /// Cancels all medication reminders.
  Future<void> cancelAllMedicationReminders() async {
    // TODO: Implement selective cancellation of medication notifications
    // For now, this is a placeholder
    await _notifications.cancelAll();
  }

  // WORKOUT REMINDERS

  /// Schedules a workout reminder notification.
  ///
  /// [id] - Unique notification ID
  /// [workoutName] - Name of the workout
  /// [scheduledTime] - When to show the notification
  Future<void> scheduleWorkoutReminder({
    required int id,
    required String workoutName,
    required DateTime scheduledTime,
  }) async {
    await _notifications.zonedSchedule(
      id: id,
      title: 'Workout Reminder',
      body: 'Time for: $workoutName',
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: _workoutNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'workout:$id',
    );
  }

  /// Cancels a workout reminder notification.
  Future<void> cancelWorkoutReminder(int id) async {
    await _notifications.cancel(id: id);
  }

  // GENERAL NOTIFICATIONS

  /// Shows an immediate notification.
  ///
  /// [id] - Unique notification ID
  /// [title] - Notification title
  /// [body] - Notification body
  /// [payload] - Optional payload data
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _defaultNotificationDetails(),
      payload: payload,
    );
  }

  /// Cancels a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // INTERNAL HELPERS

  /// Creates notification channels for Android.
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Medication channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelMedication,
        'Medication Reminders',
        description: 'Notifications for medication reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Workout channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelWorkout,
        'Workout Reminders',
        description: 'Notifications for workout reminders',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    // General channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelGeneral,
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    );
  }

  /// Returns notification details for medication reminders.
  NotificationDetails _medicationNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelMedication,
        'Medication Reminders',
        channelDescription: 'Notifications for medication reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Returns notification details for workout reminders.
  NotificationDetails _workoutNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelWorkout,
        'Workout Reminders',
        channelDescription: 'Notifications for workout reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Returns default notification details.
  NotificationDetails _defaultNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelGeneral,
        'General Notifications',
        channelDescription: 'General app notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Handles notification tap events.
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Implement navigation based on payload
    // This will be completed when implementing the router
    final payload = response.payload;
    if (payload != null) {
      _logger.d('Notification tapped with payload: $payload');
      // Navigate to appropriate screen based on payload
      // Example: medication:123 -> navigate to medication detail
      // Example: workout:456 -> navigate to workout detail
    }
  }
}

/// Background task callback for WorkManager.
///
/// This function is called by WorkManager to execute background tasks.
/// It must be a top-level function or static method.
@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // TODO: Implement background task logic
    // This will be completed in later prompts when medication
    // reminder logic is fully implemented

    final logger = Logger();

    switch (task) {
      case 'medicationReminderCheck':
        // Check for upcoming medication reminders
        // Schedule notifications as needed
        logger.d('Executing medication reminder check');
        break;
      case 'syncTask':
        // Perform background sync
        logger.d('Executing background sync');
        break;
      default:
        logger.w('Unknown task: $task');
    }

    return Future.value(true);
  });
}
