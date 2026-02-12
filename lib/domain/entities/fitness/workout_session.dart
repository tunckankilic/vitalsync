import '../../../core/enums/sync_status.dart';
import '../../../core/enums/workout_rating.dart';

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.name,
    required this.startTime,
    required this.lastModifiedAt,
    required this.createdAt,
    this.templateId,
    this.endTime,
    this.totalVolume = 0.0,
    this.notes,
    this.rating,
    this.syncStatus = SyncStatus.synced,
  });
  final int id;
  final int? templateId;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalVolume;
  final String? notes;
  final WorkoutRating? rating;
  final SyncStatus syncStatus;
  final DateTime lastModifiedAt;
  final DateTime createdAt;

  WorkoutSession copyWith({
    int? id,
    int? templateId,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    double? totalVolume,
    String? notes,
    WorkoutRating? rating,
    SyncStatus? syncStatus,
    DateTime? lastModifiedAt,
    DateTime? createdAt,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalVolume: totalVolume ?? this.totalVolume,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutSession &&
        other.id == id &&
        other.templateId == templateId &&
        other.name == name &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.totalVolume == totalVolume &&
        other.notes == notes &&
        other.rating == rating &&
        other.syncStatus == syncStatus &&
        other.lastModifiedAt == lastModifiedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        templateId.hashCode ^
        name.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        totalVolume.hashCode ^
        notes.hashCode ^
        rating.hashCode ^
        syncStatus.hashCode ^
        lastModifiedAt.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'WorkoutSession(id: $id, templateId: $templateId, name: $name, startTime: $startTime, endTime: $endTime, totalVolume: $totalVolume, notes: $notes, rating: $rating, syncStatus: $syncStatus, lastModifiedAt: $lastModifiedAt, createdAt: $createdAt)';
  }
}
