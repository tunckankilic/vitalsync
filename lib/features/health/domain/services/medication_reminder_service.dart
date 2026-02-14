import 'package:vitalsync/core/notifications/notification_service.dart';
import 'package:vitalsync/domain/repositories/health/medication_repository.dart';

import '../../../../core/enums/medication_frequency.dart';
import '../../../../domain/entities/health/medication.dart';

class MedicationReminderService {
  MedicationReminderService({
    required NotificationService notificationService,
    required MedicationRepository medicationRepository,
  }) : _notificationService = notificationService,
       _medicationRepository = medicationRepository;

  final NotificationService _notificationService;
  final MedicationRepository _medicationRepository;

  Future<void> scheduleMedicationReminders(int medicationId) async {
    final medication = await _medicationRepository.getById(medicationId);
    if (medication == null || !medication.isActive) return;

    // Cancel existing reminders first to avoid duplicates
    await cancelMedicationReminders(medicationId);

    switch (medication.frequency) {
      case MedicationFrequency.daily:
        await _notificationService.scheduleDailyMedicationReminders(medication);
      case MedicationFrequency.weekly:
        await _notificationService.scheduleWeeklyMedicationReminders(
          medication,
        );
      case MedicationFrequency.twiceDaily:
      case MedicationFrequency.threeTimesDaily:
        // These are handled as multiple daily reminders by the daily scheduler
        // assuming the 'times' list is populated correctly.
        await _notificationService.scheduleDailyMedicationReminders(medication);
      case MedicationFrequency.asNeeded:
        // No scheduled reminders for as-needed medications
        break;
      case MedicationFrequency.monthly:
        await _scheduleNextMonthlyReminder(medication);
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

  Future<void> _scheduleNextMonthlyReminder(Medication med) async {
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
    );
  }
}
