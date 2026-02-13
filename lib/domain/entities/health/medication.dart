import '../../../core/enums/medication_frequency.dart';
import '../../../core/enums/sync_status.dart';

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    required this.color,
    required this.isActive,
    required this.lastModifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.endDate,
    this.notes,
    this.syncStatus = SyncStatus.synced,
  });
  final int id;
  final String name;
  final String dosage;
  final MedicationFrequency frequency;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final int color;
  final bool isActive;
  final SyncStatus syncStatus;
  final DateTime lastModifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    MedicationFrequency? frequency,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    int? color,
    bool? isActive,
    SyncStatus? syncStatus,
    DateTime? lastModifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Medication &&
        other.id == id &&
        other.name == name &&
        other.dosage == dosage &&
        other.frequency == frequency &&
        // List equality check
        other.times.length == times.length &&
        other.times.asMap().entries.every((e) => e.value == times[e.key]) &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.notes == notes &&
        other.color == color &&
        other.isActive == isActive &&
        other.syncStatus == syncStatus &&
        other.lastModifiedAt == lastModifiedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        dosage.hashCode ^
        frequency.hashCode ^
        times.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        notes.hashCode ^
        color.hashCode ^
        isActive.hashCode ^
        syncStatus.hashCode ^
        lastModifiedAt.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dosage: $dosage, frequency: $frequency, times: $times, startDate: $startDate, endDate: $endDate, notes: $notes, color: $color, isActive: $isActive, syncStatus: $syncStatus, lastModifiedAt: $lastModifiedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
