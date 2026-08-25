import '../../../core/enums/sync_status.dart';

/// A meal logged by the user.
///
/// Photo-free by design: time, name, tags and an optional note.
class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.eatenAt,
    required this.tags,
    required this.lastModifiedAt,
    required this.createdAt,
    this.notes,
    this.syncStatus = SyncStatus.synced,
  });
  final int id;
  final String name;
  final DateTime eatenAt;
  final String? notes;
  final List<String> tags;
  final SyncStatus syncStatus;
  final DateTime lastModifiedAt;
  final DateTime createdAt;

  Meal copyWith({
    int? id,
    String? name,
    DateTime? eatenAt,
    String? notes,
    List<String>? tags,
    SyncStatus? syncStatus,
    DateTime? lastModifiedAt,
    DateTime? createdAt,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      eatenAt: eatenAt ?? this.eatenAt,
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

    return other is Meal &&
        other.id == id &&
        other.name == name &&
        other.eatenAt == eatenAt &&
        other.notes == notes &&
        other.tags.length == tags.length &&
        other.tags.asMap().entries.every((e) => e.value == tags[e.key]) &&
        other.syncStatus == syncStatus &&
        other.lastModifiedAt == lastModifiedAt &&
        other.createdAt == createdAt;
  }

  /// Hashes [tags] by its contents, matching how [operator ==] compares it.
  /// `List.hashCode` is identity-based, so hashing it directly would let two
  /// equal meals carry different hashes and break every `Set` and `Map` they
  /// are put into.
  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        eatenAt.hashCode ^
        notes.hashCode ^
        Object.hashAll(tags) ^
        syncStatus.hashCode ^
        lastModifiedAt.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Meal(id: $id, name: $name, eatenAt: $eatenAt, notes: $notes, tags: $tags, syncStatus: $syncStatus, lastModifiedAt: $lastModifiedAt, createdAt: $createdAt)';
  }
}
