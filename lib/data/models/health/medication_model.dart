import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/enums/medication_frequency.dart';
import '../../../core/enums/sync_status.dart';
import '../../../domain/entities/health/medication.dart';
import '../../local/database.dart';

/// Medication Model.
class MedicationModel extends Medication {
  const MedicationModel({
    required super.id,
    required super.name,
    required super.dosage,
    required super.frequency,
    required super.times,
    required super.startDate,
    required super.color,
    required super.isActive,
    required super.lastModifiedAt,
    required super.createdAt,
    required super.updatedAt,
    super.endDate,
    super.notes,
    super.syncStatus,
  });
  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: MedicationFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
      ),
      times: (json['times'] as List).cast<String>(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      notes: json['notes'] as String?,
      color: json['color'] as int,
      isActive: json['isActive'] as bool,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory MedicationModel.fromEntity(Medication entity) {
    return MedicationModel(
      id: entity.id,
      name: entity.name,
      dosage: entity.dosage,
      frequency: entity.frequency,
      times: entity.times,
      startDate: entity.startDate,
      endDate: entity.endDate,
      notes: entity.notes,
      color: entity.color,
      isActive: entity.isActive,
      syncStatus: entity.syncStatus,
      lastModifiedAt: entity.lastModifiedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory MedicationModel.fromDrift(MedicationData data) {
    return MedicationModel(
      id: data.id,
      name: data.name,
      dosage: data.dosage,
      frequency: data.frequency,
      times: jsonDecode(data.times).cast<String>(),
      startDate: data.startDate,
      endDate: data.endDate,
      notes: data.notes,
      color: data.color,
      isActive: data.isActive,
      syncStatus: data.syncStatus,
      lastModifiedAt: data.lastModifiedAt,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  Medication toEntity() {
    return Medication(
      id: id,
      name: name,
      dosage: dosage,
      frequency: frequency,
      times: times,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
      color: color,
      isActive: isActive,
      syncStatus: syncStatus,
      lastModifiedAt: lastModifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  MedicationsCompanion toCompanion() {
    return MedicationsCompanion(
      id: Value(id),
      name: Value(name),
      dosage: Value(dosage),
      frequency: Value(frequency),
      times: Value(jsonEncode(times)),
      startDate: Value(startDate),
      endDate: Value(endDate),
      notes: Value(notes),
      color: Value(color),
      isActive: Value(isActive),
      syncStatus: Value(syncStatus),
      lastModifiedAt: Value(lastModifiedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency.name,
      'times': times,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'color': color,
      'isActive': isActive,
      'syncStatus': syncStatus.name,
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
