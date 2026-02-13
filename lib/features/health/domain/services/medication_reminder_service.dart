import 'package:vitalsync/core/notifications/notification_service.dart';
import 'package:vitalsync/domain/repositories/health/medication_repository.dart';

class MedicationReminderService {
  MedicationReminderService({
    required NotificationService notificationService,
    required MedicationRepository medicationRepository,
  }) : _notificationService = notificationService,
       _medicationRepository = medicationRepository;

  final NotificationService _notificationService;
  final MedicationRepository _medicationRepository;

  Future<void> scheduleMedicationReminders(int medicationId) async {
    // TODO: Implement logic
  }

  Future<void> cancelMedicationReminders(int medicationId) async {
    // TODO: Implement logic
  }

  Future<void> rescheduleAllReminders() async {
    // TODO: Implement logic
  }

  Future<void> checkUpcomingReminders() async {
    // TODO: Implement logic
  }
}
