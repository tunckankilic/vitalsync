import 'package:drift/drift.dart';

import '../../../core/enums/medication_log_status.dart';
import '../../../core/enums/sync_status.dart';
import '../../../domain/entities/health/medication_log.dart';
import '../../local/database.dart';

/// MedicationLog Model.
class MedicationLogModel extends MedicationLog {
  const MedicationLogModel({
    required super.id,
    required super.medicationId,
    required super.scheduledTime,
    required super.lastModifiedAt,
    required super.createdAt,
    super.takenTime,
    super.status,
    super.notes,
    super.syncStatus,
  });
  factory MedicationLogModel.fromJson(Map<String, dynamic> json) {
    return MedicationLogModel(
      id: json['id'] as int? ?? 0,
      medicationId: json['medicationId'] as int,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      takenTime: json['takenTime'] != null
          ? DateTime.parse(json['takenTime'] as String)
          : null,
      status: MedicationLogStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MedicationLogStatus.pending,
      ),
      notes: json['notes'] as String?,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory MedicationLogModel.fromEntity(MedicationLog entity) {
    return MedicationLogModel(
      id: entity.id,
      medicationId: entity.medicationId,
      scheduledTime: entity.scheduledTime,
      takenTime: entity.takenTime,
      status: entity.status,
      notes: entity.notes,
      syncStatus: entity.syncStatus,
      lastModifiedAt: entity.lastModifiedAt,
      createdAt: entity.createdAt,
    );
  }

  factory MedicationLogModel.fromDrift(MedicationLogData data) {
    return MedicationLogModel(
      id: data.id,
      medicationId: data.medicationId,
      scheduledTime: data.scheduledTime,
      takenTime: data.takenTime,
      status: data.status,
      notes: data.notes,
      syncStatus: data.syncStatus,
      lastModifiedAt: data.lastModifiedAt,
      createdAt: data.createdAt,
    );
  }

  MedicationLog toEntity() {
    return MedicationLog(
      id: id,
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      takenTime: takenTime,
      status: status,
      notes: notes,
      syncStatus: syncStatus,
      lastModifiedAt: lastModifiedAt,
      createdAt: createdAt,
    );
  }

  MedicationLogsCompanion toCompanion() {
    return MedicationLogsCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      scheduledTime: Value(scheduledTime),
      takenTime: Value(takenTime),
      status: Value(status),
      notes: Value(notes),
      syncStatus: Value(syncStatus),
      lastModifiedAt: Value(lastModifiedAt),
      createdAt: Value(createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'syncStatus': syncStatus.name,
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
