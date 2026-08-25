/// VitalSync — Health Import Service.
///
/// Source-agnostic import flow: pulls samples from a [HealthDataSource],
/// deduplicates them by external ID and writes them into the local database.
/// Knows nothing about HealthKit — see [AppleHealthDataSource] for that.
library;

import 'dart:convert';
import 'dart:developer' show log;

import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/daos/health/glucose_dao.dart';
import '../../data/local/daos/health/health_sample_dao.dart';
import '../../data/local/database.dart';
import '../constants/app_constants.dart';
import '../enums/glucose_source.dart';
import '../enums/health_data_source_kind.dart';
import '../enums/health_sample_type.dart';
import '../errors/exceptions.dart';
import 'health_data_source.dart';

/// Result of one import run.
///
/// Counts only — how many rows were written and how many were already known.
/// Nothing here interprets the imported values.
class HealthImportResult {
  const HealthImportResult({
    required this.glucoseImported,
    required this.samplesImported,
    required this.duplicatesSkipped,
  });

  final int glucoseImported;
  final int samplesImported;
  final int duplicatesSkipped;

  int get totalImported => glucoseImported + samplesImported;

  @override
  String toString() {
    return 'HealthImportResult(glucose: $glucoseImported, '
        'samples: $samplesImported, duplicates: $duplicatesSkipped)';
  }
}

/// Imports platform health samples into the local database.
class HealthImportService {
  HealthImportService({
    required HealthDataSource source,
    required GlucoseDao glucoseDao,
    required HealthSampleDao healthSampleDao,
  }) : _source = source,
       _glucoseDao = glucoseDao,
       _healthSampleDao = healthSampleDao;

  final HealthDataSource _source;
  final GlucoseDao _glucoseDao;
  final HealthSampleDao _healthSampleDao;

  /// How far back a first-ever import reaches.
  /// Bounded so the initial run cannot pull years of samples in one pass.
  static const Duration initialLookback = Duration(days: 30);

  /// Asks the platform for read access.
  ///
  /// Throws [HealthDataException] when the user declines, so the caller can
  /// tell "declined" apart from "granted but nothing new to read".
  Future<void> requestPermissions() async {
    final granted = await _source.requestPermissions();
    if (!granted) {
      throw const HealthDataException('Health data read access was declined');
    }
  }

  /// Whether the app currently holds read access.
  Future<bool> isAuthorized() => _source.isAuthorized();

  /// Imports every supported sample recorded since the last successful run.
  ///
  /// Records the run timestamp only on success, so a failed import is retried
  /// over the same window instead of silently leaving a gap.
  Future<HealthImportResult> import() async {
    final prefs = await SharedPreferences.getInstance();
    final since = _lastImportFrom(prefs);
    final result = await importSince(since);
    await prefs.setString(
      AppConstants.prefKeyLastHealthImport,
      DateTime.now().toIso8601String(),
    );
    return result;
  }

  /// Imports every supported sample recorded at or after [since].
  ///
  /// Partial authorization is tolerated: kinds the platform withholds are
  /// simply absent from the read, and the rest still land. Throws
  /// [HealthDataException] only when no access is held at all.
  Future<HealthImportResult> importSince(DateTime since) async {
    if (!await _source.isAuthorized()) {
      throw const HealthDataException(
        'Health data read access has not been granted',
      );
    }

    final samples = await _source.readSamples(
      kinds: HealthSampleKind.values,
      since: since,
    );

    var glucoseImported = 0;
    var samplesImported = 0;
    var duplicatesSkipped = 0;

    for (final sample in samples) {
      final externalId = sample.externalId;
      final dedupe = externalId != null;

      if (sample.kind.isGlucose) {
        if (dedupe && await _glucoseDao.existsByExternalId(externalId)) {
          duplicatesSkipped++;
          continue;
        }
        await _glucoseDao.insert(
          GlucoseReadingsCompanion.insert(
            valueMgDl: sample.value,
            measuredAt: sample.startAt,
            source: GlucoseSource.healthKit,
            externalId: Value(externalId),
          ),
        );
        glucoseImported++;
        continue;
      }

      if (dedupe && await _healthSampleDao.existsByExternalId(externalId)) {
        duplicatesSkipped++;
        continue;
      }
      await _healthSampleDao.insert(
        HealthSamplesCompanion.insert(
          type: _sampleTypeOf(sample.kind),
          startAt: sample.startAt,
          endAt: Value(sample.endAt),
          value: sample.value,
          unit: sample.unit,
          source: HealthDataSourceKind.healthKit,
          externalId: Value(externalId),
          metadata: Value(
            sample.metadata == null ? null : jsonEncode(sample.metadata),
          ),
        ),
      );
      samplesImported++;
    }

    // Counts only — no imported value is logged.
    final result = HealthImportResult(
      glucoseImported: glucoseImported,
      samplesImported: samplesImported,
      duplicatesSkipped: duplicatesSkipped,
    );
    log('Health import completed: $result');
    return result;
  }

  /// Releases the app's access to the platform health store and forgets the
  /// last-import marker, so re-connecting starts from a clean window.
  Future<void> disconnect() async {
    await _source.disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefKeyLastHealthImport);
  }

  DateTime _lastImportFrom(SharedPreferences prefs) {
    final stored = prefs.getString(AppConstants.prefKeyLastHealthImport);
    if (stored == null) {
      return DateTime.now().subtract(initialLookback);
    }
    final parsed = DateTime.tryParse(stored);
    if (parsed == null) {
      log('Unparseable last health import marker, falling back to lookback');
      return DateTime.now().subtract(initialLookback);
    }
    return parsed;
  }

  /// [HealthSampleKind.bloodGlucose] never reaches here — it is written to
  /// the glucose table instead.
  HealthSampleType _sampleTypeOf(HealthSampleKind kind) {
    switch (kind) {
      case HealthSampleKind.steps:
        return HealthSampleType.steps;
      case HealthSampleKind.activeEnergy:
        return HealthSampleType.activeEnergy;
      case HealthSampleKind.workout:
        return HealthSampleType.workout;
      case HealthSampleKind.sleep:
        return HealthSampleType.sleep;
      case HealthSampleKind.bloodGlucose:
        throw const HealthDataException(
          'Glucose samples are stored as glucose readings, not health samples',
        );
    }
  }
}
