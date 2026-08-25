/// VitalSync — Health Sample DAO (Health Module).
library;

import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/health_data_source_kind.dart';
import 'package:vitalsync/core/enums/health_sample_type.dart';
import 'package:vitalsync/data/local/database.dart';

import '../../tables/health/health_samples_table.dart';

part 'health_sample_dao.g.dart';

/// DAO for imported activity and sleep sample operations.
///
/// Health samples are a local mirror of the platform health store and are not
/// pushed to the cloud, so there is no `syncStatus` handling here.
/// [upsertFromRemote] is kept for signature parity with the other DAOs.
@DriftAccessor(tables: [HealthSamples])
class HealthSampleDao extends DatabaseAccessor<AppDatabase>
    with _$HealthSampleDaoMixin {
  HealthSampleDao(super.db);

  /// Get all health samples, newest first.
  Future<List<HealthSampleData>> getAll() {
    return (select(
      healthSamples,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.startAt)])).get();
  }

  /// Get health samples within a date range, newest first.
  Future<List<HealthSampleData>> getByDateRange(DateTime start, DateTime end) {
    return (select(healthSamples)
          ..where(
            (tbl) =>
                tbl.startAt.isBiggerOrEqualValue(start) &
                tbl.startAt.isSmallerOrEqualValue(end),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.startAt)]))
        .get();
  }

  /// Get health samples of one type within a date range, newest first.
  Future<List<HealthSampleData>> getByTypeAndRange(
    HealthSampleType type,
    DateTime start,
    DateTime end,
  ) {
    return (select(healthSamples)
          ..where(
            (tbl) =>
                tbl.type.equalsValue(type) &
                tbl.startAt.isBiggerOrEqualValue(start) &
                tbl.startAt.isSmallerOrEqualValue(end),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.startAt)]))
        .get();
  }

  /// Returns a single health sample by ID, or null if not found.
  Future<HealthSampleData?> getById(int id) {
    return (select(
      healthSamples,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Whether a sample with the given external store ID already exists.
  /// Used to deduplicate repeated imports from the platform health store.
  Future<bool> existsByExternalId(String externalId) async {
    final row = await (select(
      healthSamples,
    )..where((tbl) => tbl.externalId.equals(externalId))).getSingleOrNull();
    return row != null;
  }

  /// Insert a new health sample.
  Future<int> insert(HealthSamplesCompanion sample) {
    return into(healthSamples).insert(sample);
  }

  /// Update an existing health sample.
  Future<bool> updateSample(HealthSampleData sample) {
    return update(healthSamples).replace(sample);
  }

  /// Delete a health sample by ID.
  Future<int> deleteSample(int id) {
    return (delete(healthSamples)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Watch recent health samples.
  Stream<List<HealthSampleData>> watchRecent({int limit = 20}) {
    return (select(healthSamples)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.startAt)])
          ..limit(limit))
        .watch();
  }

  /// Inserts or updates a health sample from a remote payload.
  Future<void> upsertFromRemote(int id, Map<String, dynamic> data) async {
    await into(healthSamples).insertOnConflictUpdate(
      HealthSamplesCompanion(
        id: Value(id),
        type: Value(
          HealthSampleType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => HealthSampleType.steps,
          ),
        ),
        startAt: Value(DateTime.parse(data['startAt'] as String)),
        endAt: Value(
          data['endAt'] != null
              ? DateTime.parse(data['endAt'] as String)
              : null,
        ),
        value: Value((data['value'] as num).toDouble()),
        unit: Value(data['unit'] as String),
        source: Value(
          HealthDataSourceKind.values.firstWhere(
            (e) => e.name == data['source'],
            orElse: () => HealthDataSourceKind.healthKit,
          ),
        ),
        externalId: Value(data['externalId'] as String?),
        metadata: Value(data['metadata'] as String?),
        lastModifiedAt: Value(DateTime.parse(data['lastModifiedAt'] as String)),
        createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      ),
    );
  }
}
