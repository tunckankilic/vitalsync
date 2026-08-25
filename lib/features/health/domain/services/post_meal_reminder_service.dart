/// VitalSync — Health Module: Post-Meal Measurement Reminder.
///
/// Schedules a single notification a fixed interval after a logged meal,
/// asking the user to add a measurement.
///
/// No comment, only measurement: the trigger is time and nothing else. No
/// reading is read, compared or evaluated here, and the reminder never says
/// what a measurement might show. It exists because a meal with no readings
/// around it is the first reason a meal comes out uncovered — see
/// `MealDataCoverageService`.
library;

import 'package:logger/logger.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../domain/repositories/health/meal_repository.dart';

class PostMealReminderService {
  PostMealReminderService({
    required NotificationService notificationService,
    required MealRepository mealRepository,
    bool Function()? areNotificationsEnabled,
    bool Function()? isReminderEnabled,
    DateTime Function()? now,
    Logger? logger,
  }) : _notificationService = notificationService,
       _mealRepository = mealRepository,
       _areNotificationsEnabled = areNotificationsEnabled ?? (() => true),
       _isReminderEnabled = isReminderEnabled ?? (() => true),
       _now = now ?? DateTime.now,
       _logger = logger ?? Logger();

  final NotificationService _notificationService;
  final MealRepository _mealRepository;

  /// Whether the user has notifications enabled at all. Gates everything:
  /// the per-feature switch cannot re-enable reminders while this is off.
  final bool Function() _areNotificationsEnabled;

  /// Whether the post-meal reminder itself is switched on (default on).
  final bool Function() _isReminderEnabled;

  /// Injected clock, so "already in the past" is testable.
  final DateTime Function() _now;
  final Logger _logger;

  /// Brings the scheduled reminder in line with the database after a meal
  /// was added, edited or removed.
  ///
  /// Cancels first in every path, so an edited meal time moves its reminder
  /// instead of leaving the old one pending. Nothing is scheduled when the
  /// meal is gone, when either switch is off, or when the reminder time has
  /// already passed (a meal logged after the fact must not fire instantly).
  ///
  /// Never throws: notification bookkeeping must not fail the meal write that
  /// triggered it.
  Future<void> syncReminderAfterChange(int mealId) async {
    try {
      await _notificationService.cancelPostMealGlucoseReminder(mealId);

      if (!_areNotificationsEnabled() || !_isReminderEnabled()) return;

      final meal = await _mealRepository.getById(mealId);
      if (meal == null) return;

      final remindAt = meal.eatenAt.add(
        const Duration(hours: AppConstants.postMealReminderDelayHours),
      );
      if (!remindAt.isAfter(_now())) return;

      await _notificationService.schedulePostMealGlucoseReminder(
        mealId: mealId,
        remindAt: remindAt,
      );
    } catch (e, stackTrace) {
      // The meal id is safe to log; the meal itself is not.
      _logger.e(
        'Failed to sync post-meal reminder (mealId=$mealId)',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Cancels the pending reminder for [mealId] without consulting the
  /// database. Never throws.
  Future<void> cancelReminder(int mealId) async {
    try {
      await _notificationService.cancelPostMealGlucoseReminder(mealId);
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to cancel post-meal reminder (mealId=$mealId)',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
