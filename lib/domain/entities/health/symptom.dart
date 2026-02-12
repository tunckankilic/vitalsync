import '../../../core/enums/sync_status.dart';

class Symptom {
  const Symptom({
    required this.id,
    required this.name,
    required this.severity,
    required this.date,
    required this.tags,
    required this.lastModifiedAt,
    required this.createdAt,
    this.notes,
    this.syncStatus = SyncStatus.synced,
  });
  final int id;
  final String name;
  final int severity;
  final DateTime date;
  final String? notes;
  final List<String> tags;
  final SyncStatus syncStatus;
  final DateTime lastModifiedAt;
  final DateTime createdAt;

  Symptom copyWith({
    int? id,
    String? name,
    int? severity,
    DateTime? date,
    String? notes,
    List<String>? tags,
    SyncStatus? syncStatus,
    DateTime? lastModifiedAt,
    DateTime? createdAt,
  }) {
    return Symptom(
      id: id ?? this.id,
      name: name ?? this.name,
      severity: severity ?? this.severity,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Symptom &&
        other.id == id &&
        other.name == name &&
        other.severity == severity &&
        other.date == date &&
        other.notes == notes &&
        other.tags.length == tags.length &&
        other.tags.asMap().entries.every((e) => e.value == tags[e.key]) &&
        other.syncStatus == syncStatus &&
        other.lastModifiedAt == lastModifiedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        severity.hashCode ^
        date.hashCode ^
        notes.hashCode ^
        tags.hashCode ^
        syncStatus.hashCode ^
        lastModifiedAt.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Symptom(id: $id, name: $name, severity: $severity, date: $date, notes: $notes, tags: $tags, syncStatus: $syncStatus, lastModifiedAt: $lastModifiedAt, createdAt: $createdAt)';
  }
}
