import '../../../core/enums/glucose_source.dart';
import '../../../core/enums/meal_context.dart';
import '../../../core/enums/sync_status.dart';

/// A single blood glucose measurement.
///
/// Holds the measurement and its provenance only — no reference range,
/// no rating, no derived value.
class GlucoseReading {
  const GlucoseReading({
    required this.id,
    required this.valueMgDl,
    required this.measuredAt,
    required this.source,
    required this.lastModifiedAt,
    required this.createdAt,
    this.externalId,
    this.mealContext,
    this.notes,
    this.syncStatus = SyncStatus.synced,
  });
  final int id;
  final double valueMgDl;
  final DateTime measuredAt;
  final GlucoseSource source;
  final String? externalId;
  final MealContext? mealContext;
  final String? notes;
  final SyncStatus syncStatus;
  final DateTime lastModifiedAt;
  final DateTime createdAt;

  GlucoseReading copyWith({
    int? id,
    double? valueMgDl,
    DateTime? measuredAt,
    GlucoseSource? source,
    String? externalId,
    MealContext? mealContext,
    String? notes,
    SyncStatus? syncStatus,
    DateTime? lastModifiedAt,
    DateTime? createdAt,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      valueMgDl: valueMgDl ?? this.valueMgDl,
      measuredAt: measuredAt ?? this.measuredAt,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      mealContext: mealContext ?? this.mealContext,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GlucoseReading &&
        other.id == id &&
        other.valueMgDl == valueMgDl &&
        other.measuredAt == measuredAt &&
        other.source == source &&
        other.externalId == externalId &&
        other.mealContext == mealContext &&
        other.notes == notes &&
        other.syncStatus == syncStatus &&
        other.lastModifiedAt == lastModifiedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        valueMgDl.hashCode ^
        measuredAt.hashCode ^
        source.hashCode ^
        externalId.hashCode ^
        mealContext.hashCode ^
        notes.hashCode ^
        syncStatus.hashCode ^
        lastModifiedAt.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'GlucoseReading(id: $id, valueMgDl: $valueMgDl, measuredAt: $measuredAt, source: $source, externalId: $externalId, mealContext: $mealContext, notes: $notes, syncStatus: $syncStatus, lastModifiedAt: $lastModifiedAt, createdAt: $createdAt)';
  }
}
