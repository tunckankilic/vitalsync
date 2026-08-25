/// VitalSync — Apple Health (HealthKit) data source.
///
/// The **only** file that knows HealthKit types exist. Everything above it
/// speaks [HealthSampleKind] / [HealthSampleDto], so adding Google Health
/// Connect later means adding a sibling of this class and nothing else.
library;

import 'dart:developer' show log;

import 'package:health/health.dart';

import '../errors/exceptions.dart';
import 'health_data_source.dart';

/// Reads blood glucose, activity and sleep samples from Apple Health.
///
/// **Read-only.** Every authorization request below passes
/// [HealthDataAccess.READ]; the app never asks for, and cannot perform,
/// HealthKit writes.
class AppleHealthDataSource implements HealthDataSource {
  AppleHealthDataSource({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  /// HealthKit type for each kind VitalSync reads.
  ///
  /// This map is the entire platform coupling. Nothing outside this file may
  /// reference [HealthDataType].
  static const Map<HealthSampleKind, HealthDataType> _typeOf = {
    HealthSampleKind.bloodGlucose: HealthDataType.BLOOD_GLUCOSE,
    HealthSampleKind.steps: HealthDataType.STEPS,
    HealthSampleKind.activeEnergy: HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthSampleKind.workout: HealthDataType.WORKOUT,
    HealthSampleKind.sleep: HealthDataType.SLEEP_ASLEEP,
  };

  /// Canonical unit requested per kind.
  ///
  /// Glucose is pinned to mg/dL so the value written to the database is
  /// already in the canonical unit and no conversion is needed downstream.
  static const Map<HealthDataType, HealthDataUnit> _preferredUnits = {
    HealthDataType.BLOOD_GLUCOSE: HealthDataUnit.MILLIGRAM_PER_DECILITER,
  };

  static List<HealthDataType> get _allTypes => _typeOf.values.toList();

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      return await _health.requestAuthorization(
        _allTypes,
        // READ for every type. Never READ_WRITE — see the class doc.
        permissions: List<HealthDataAccess>.filled(
          _allTypes.length,
          HealthDataAccess.READ,
        ),
      );
    } catch (e) {
      throw HealthDataException(
        'Requesting Apple Health read access failed',
        cause: e,
      );
    }
  }

  @override
  Future<bool> isAuthorized() async {
    try {
      await _ensureConfigured();
      final granted = await _health.hasPermissions(
        _allTypes,
        permissions: List<HealthDataAccess>.filled(
          _allTypes.length,
          HealthDataAccess.READ,
        ),
      );
      // HealthKit returns null when it will not disclose read status.
      return granted ?? false;
    } catch (e) {
      throw HealthDataException(
        'Reading Apple Health authorization status failed',
        cause: e,
      );
    }
  }

  @override
  Future<List<HealthSampleDto>> readSamples({
    required List<HealthSampleKind> kinds,
    required DateTime since,
  }) async {
    await _ensureConfigured();
    final now = DateTime.now();
    if (!since.isBefore(now)) return const [];

    final samples = <HealthSampleDto>[];

    // Query one kind at a time so a type the user withheld only costs that
    // type. A single multi-type query would lose everything on one refusal.
    for (final kind in kinds) {
      final type = _typeOf[kind];
      if (type == null) continue;

      try {
        final points = await _health.getHealthDataFromTypes(
          types: [type],
          preferredUnits: _preferredUnits,
          startTime: since,
          endTime: now,
        );
        for (final point in points) {
          final dto = _toDto(kind, point);
          if (dto != null) samples.add(dto);
        }
      } catch (e) {
        // Partial authorization is the expected case, not an error: the user
        // may have granted glucose and withheld sleep. Skip and continue.
        log('Apple Health read skipped for ${kind.name}: $e');
      }
    }

    return samples;
  }

  @override
  Future<void> disconnect() async {
    try {
      await _ensureConfigured();
      await _health.revokePermissions();
    } catch (e) {
      throw HealthDataException(
        'Disconnecting from Apple Health failed',
        cause: e,
      );
    }
  }

  /// Converts one HealthKit point to the platform-neutral DTO.
  ///
  /// Returns null for a point whose value shape is not understood, so one odd
  /// sample cannot abort an entire import.
  HealthSampleDto? _toDto(HealthSampleKind kind, HealthDataPoint point) {
    final value = point.value;
    final double numeric;
    Map<String, dynamic>? metadata;

    switch (value) {
      case NumericHealthValue():
        numeric = value.numericValue.toDouble();
      case WorkoutHealthValue():
        // A workout's "value" is its duration in minutes; the activity name
        // is kept as metadata so the UI can label it without a second query.
        numeric = point.dateTo.difference(point.dateFrom).inMinutes.toDouble();
        metadata = {'activityType': value.workoutActivityType.name};
      default:
        log('Apple Health sample with unsupported value type skipped: $kind');
        return null;
    }

    return HealthSampleDto(
      kind: kind,
      startAt: point.dateFrom,
      endAt: point.dateTo,
      value: numeric,
      unit: kind == HealthSampleKind.workout ? 'min' : point.unit.name,
      externalId: point.uuid.isEmpty ? null : point.uuid,
      metadata: metadata,
    );
  }
}
