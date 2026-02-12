import '../../../core/enums/medication_log_status.dart';
import '../../../core/enums/sync_status.dart';

class MedicationLog {
  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.scheduledTime,
    required this.lastModifiedAt,
    required this.createdAt,
    this.takenTime,
    this.status = MedicationLogStatus.pending,
    this.notes,
    this.syncStatus = SyncStatus.synced,
  });
  final int id;
  final int medicationId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final MedicationLogStatus status;
  final String? notes;
  final SyncStatus syncStatus;
  final DateTime lastModifiedAt;
  final DateTime createdAt;

  MedicationLog copyWith({
    int? id,
    int? medicationId,
    DateTime? scheduledTime,
    DateTime? takenTime,
    MedicationLogStatus? status,
    String? notes,
    SyncStatus? syncStatus,
    DateTime? lastModifiedAt,
    DateTime? createdAt,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicationLog &&
        other.id == id &&
        other.medicationId == medicationId &&
        other.scheduledTime == scheduledTime &&
        other.takenTime == takenTime &&
        other.status == status &&
        other.notes == notes &&
        other.syncStatus == syncStatus &&
        other.lastModifiedAt == lastModifiedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        medicationId.hashCode ^
        scheduledTime.hashCode ^
        takenTime.hashCode ^
        status.hashCode ^
        notes.hashCode ^
        syncStatus.hashCode ^
        lastModifiedAt.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'MedicationLog(id: $id, medicationId: $medicationId, scheduledTime: $scheduledTime, takenTime: $takenTime, status: $status, notes: $notes, syncStatus: $syncStatus, lastModifiedAt: $lastModifiedAt, createdAt: $createdAt)';
  }
}
