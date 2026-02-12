import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/enums/sync_status.dart';
import '../../../domain/entities/health/symptom.dart';
import '../../local/database.dart';

/// Symptom Model.
class SymptomModel extends Symptom {
  const SymptomModel({
    required super.id,
    required super.name,
    required super.severity,
    required super.date,
    required super.tags,
    required super.lastModifiedAt,
    required super.createdAt,
    super.notes,
    super.syncStatus,
  });

  factory SymptomModel.fromJson(Map<String, dynamic> json) {
    return SymptomModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      severity: json['severity'] as int,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      tags: (json['tags'] as List).cast<String>(),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory SymptomModel.fromEntity(Symptom entity) {
    return SymptomModel(
      id: entity.id,
      name: entity.name,
      severity: entity.severity,
      date: entity.date,
      notes: entity.notes,
      tags: entity.tags,
      syncStatus: entity.syncStatus,
      lastModifiedAt: entity.lastModifiedAt,
      createdAt: entity.createdAt,
    );
  }

  factory SymptomModel.fromDrift(SymptomData data) {
    return SymptomModel(
      id: data.id,
      name: data.name,
      severity: data.severity,
      date: data.date,
      notes: data.notes,
      tags: jsonDecode(data.tags).cast<String>(),
      syncStatus: data.syncStatus,
      lastModifiedAt: data.lastModifiedAt,
      createdAt: data.createdAt,
    );
  }

  Symptom toEntity() {
    return Symptom(
      id: id,
      name: name,
      severity: severity,
      date: date,
      notes: notes,
      tags: tags,
      syncStatus: syncStatus,
      lastModifiedAt: lastModifiedAt,
      createdAt: createdAt,
    );
  }

  SymptomsCompanion toCompanion() {
    return SymptomsCompanion(
      id: Value(id),
      name: Value(name),
      severity: Value(severity),
      date: Value(date),
      notes: Value(notes),
      tags: Value(jsonEncode(tags)),
      syncStatus: Value(syncStatus),
      lastModifiedAt: Value(lastModifiedAt),
      createdAt: Value(createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'severity': severity,
      'date': date.toIso8601String(),
      'notes': notes,
      'tags': tags,
      'syncStatus': syncStatus.name,
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
