import 'package:logger/logger.dart';
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/notifications/notification_service.dart';
import 'package:vitalsync/domain/repositories/health/medication_repository.dart';

import '../../../../core/enums/medication_frequency.dart';
import '../../../../domain/entities/health/medication.dart';

class MedicationReminderService {
  MedicationReminderService({
    required NotificationService notificationService,
    required MedicationRepository medicationRepository,
    bool Function()? areNotificationsEnabled,
    Logger? logger,
  }) : _notificationService = notificationService,
       _medicationRepository = medicationRepository,
       _areNotificationsEnabled = areNotificationsEnabled ?? (() => true),
       _logger = logger ?? Logger();

  final NotificationService _notificationService;
  final MedicationRepository _medicationRepository;

  /// Whether the user has notifications enabled in settings.
  /// Gates follow-up scheduling (requirement: no follow-ups when disabled).
  final bool Function() _areNotificationsEnabled;
  final Logger _logger;

  Future<void> scheduleMedicationReminders(int medicationId) async {
    final medication = await _medicationRepository.getById(medicationId);
    if (medication == null || !medication.isActive) return;

    // Cancel existing reminders first to avoid duplicates
    await cancelMedicationReminders(medicationId);

    final withFollowUps = _areNotificationsEnabled();

    switch (medication.frequency) {
      case MedicationFrequency.daily:
        await _notificationService.scheduleDailyMedicationReminders(
          medication,
          withFollowUps: withFollowUps,
        );
      case MedicationFrequency.weekly:
        await _notificationService.scheduleWeeklyMedicationReminders(
          medication,
          withFollowUps: withFollowUps,
        );
      case MedicationFrequency.twiceDaily:
      case MedicationFrequency.threeTimesDaily:
        // These are handled as multiple daily reminders by the daily scheduler
        // assuming the 'times' list is populated correctly.
        await _notificationService.scheduleDailyMedicationReminders(
          medication,
          withFollowUps: withFollowUps,
        );
      case MedicationFrequency.asNeeded:
        // No scheduled reminders for as-needed medications
        break;
      case MedicationFrequency.monthly:
        await _scheduleNextMonthlyReminder(
          medication,
          withFollowUp: withFollowUps,
        );
    }
  }

  /// Brings scheduled notifications in line with the database after a CRUD
  /// change (add/update/delete/toggle): cancels reminders when the
  /// medication no longer exists or is inactive, (re)schedules them
  /// otherwise.
  ///
  /// Never throws: a notification bookkeeping failure must not fail the
  /// CRUD operation that triggered it.
  Future<void> syncRemindersAfterChange(int medicationId) async {
    try {
      final medication = await _medicationRepository.getById(medicationId);
      if (medication == null || !medication.isActive) {
        await _notificationService.cancelMedicationReminders(medicationId);
        return;
      }
      await scheduleMedicationReminders(medicationId);
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sync reminders after medication change '
        '(medicationId=$medicationId)',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Called when the user logs a dose (taken or skipped).
  ///
  /// Cancels the pending follow-up notification for the dose slot closest
  /// to now, then re-arms it for the next occurrence (recurring follow-ups
  /// are removed entirely by `cancel`, so the recurrence must be restored —
  /// starting after today so the user isn't nagged for a dose they logged).
  ///
  /// Never throws: a follow-up bookkeeping failure must not fail the log.
  Future<void> handleDoseLogged(int medicationId) async {
    try {
      final medication = await _medicationRepository.getById(medicationId);
      if (medication == null) {
        await _notificationService.cancelMedicationFollowUps(medicationId);
        return;
      }

      final slotIndex = _nearestSlotIndex(medication.times, DateTime.now());
      if (slotIndex == null) return;

      await _notificationService.cancelMedicationFollowUp(
        medicationId,
        slotIndex,
      );

      if (!medication.isActive || !_areNotificationsEnabled()) return;

      await _rearmFollowUp(medication, slotIndex);
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update follow-up after dose log '
        '(medicationId=$medicationId)',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelMedicationReminders(int medicationId) async {
    await _notificationService.cancelMedicationReminders(medicationId);
  }

  Future<void> rescheduleAllReminders() async {
    await _notificationService.cancelAllNotifications();
    final activeMedications = await _medicationRepository.getActive();
    for (final medication in activeMedications) {
      await scheduleMedicationReminders(medication.id);
    }
  }

  Future<void> checkUpcomingReminders() async {
    // This is primarily for debugging as NotificationService handles the queue.
    // This is primarily for debugging as NotificationService handles the queue.
    // Logic to log or inspect upcoming times could go here.
    // For now multiple specific checks aren't exposed by flutter_local_notifications easily
    // without keeping local state.
  }

  Future<void> _scheduleNextMonthlyReminder(
    Medication med, {
    bool withFollowUp = false,
  }) async {
    // Simple implementation: Find the next occurrence of the day-of-month and time
    // and schedule a one-shot reminder.
    // NOTE: This requires re-scheduling after the notification fires.

    if (med.times.isEmpty) return;

    // Use the first time slot for the monthly reminder for now
    final timeParts = med.times[0].split(':');
    if (timeParts.length != 2) return;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return;

    final now = DateTime.now();
    // Assuming start date's day is the anchor day for monthly
    final dayOfMonth = med.startDate.day;

    var nextDate = DateTime(now.year, now.month, dayOfMonth, hour, minute);

    if (nextDate.isBefore(now)) {
      nextDate = DateTime(now.year, now.month + 1, dayOfMonth, hour, minute);
    }

    await _notificationService.scheduleMedicationReminder(
      med: med,
      time: nextDate,
      withFollowUp: withFollowUp,
    );
  }

  /// Re-schedules the recurring follow-up for [slotIndex] with its first
  /// instance after today, so the recurrence survives the cancellation
  /// without re-creating a pending follow-up for the dose just logged.
  Future<void> _rearmFollowUp(Medication med, int slotIndex) async {
    final slot = _parseSlot(med.times[slotIndex]);
    if (slot == null) return;

    final int daysAhead;
    switch (med.frequency) {
      case MedicationFrequency.daily:
      case MedicationFrequency.twiceDaily:
      case MedicationFrequency.threeTimesDaily:
        daysAhead = 1;
      case MedicationFrequency.weekly:
        daysAhead = 7;
      case MedicationFrequency.monthly:
      case MedicationFrequency.asNeeded:
        // Monthly follow-ups are one-shot (like their reminders) and
        // as-needed medications have none — nothing to re-arm.
        return;
    }

    final now = DateTime.now();
    final nextDose = DateTime(
      now.year,
      now.month,
      now.day,
      slot.hour,
      slot.minute,
    ).add(Duration(days: daysAhead));

    await _notificationService.scheduleMedicationFollowUp(
      med: med,
      followUpTime: nextDose.add(
        const Duration(minutes: AppConstants.medicationFollowUpGraceMinutes),
      ),
      timeIndex: slotIndex,
    );
  }

  /// Returns the index of the time slot closest to [now], or null when no
  /// slot can be parsed. A log entry isn't tied to a slot, so the nearest
  /// slot is the best estimate of which dose the user just logged.
  int? _nearestSlotIndex(List<String> times, DateTime now) {
    int? nearestIndex;
    Duration? nearestDiff;

    for (var i = 0; i < times.length; i++) {
      final slot = _parseSlot(times[i]);
      if (slot == null) continue;

      final slotTime = DateTime(
        now.year,
        now.month,
        now.day,
        slot.hour,
        slot.minute,
      );
      final diff = now.difference(slotTime).abs();
      if (nearestDiff == null || diff < nearestDiff) {
        nearestDiff = diff;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  /// Parses an "HH:mm" time slot string.
  ({int hour, int minute})? _parseSlot(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return (hour: hour, minute: minute);
  }
}
