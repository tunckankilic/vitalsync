/// VitalSync — Database Migration Helper.
///
/// Manages schema migrations for the Drift database.
///
/// Migration Best Practices:
/// - Every new column MUST be nullable or have a default value
///   (existing rows won't have data for the new column).
/// - Prefer adding columns over dropping/recreating tables
///   (data preservation is critical).
/// - Migrations run sequentially: 1→2→3, never 1→3 directly.
///   Each version upgrade step must be self-contained.
/// - Always test migrations with data in the old schema before
///   deploying (use the migration test helper below).
/// - Never rename tables — instead, create a new table and migrate data.
/// - For column type changes, add a new column + migrate data + drop old.
library;

import 'dart:developer' show log;

import 'package:drift/drift.dart';

import 'database.dart';

/// Runs all migrations from [from] to [to] sequentially.
///
/// Called by [AppDatabase.migration.onUpgrade].
/// Each case handles exactly one version bump.
Future<void> runMigrations(
  Migrator m,
  AppDatabase db,
  int from,
  int to,
) async {
  log('Running migrations from v$from to v$to');

  for (var target = from + 1; target <= to; target++) {
    log('Applying migration to v$target...');

    switch (target) {
      case 2:
        // v1 → v2: the 2.0 measurement layer.
        // Additive only — no existing table is touched.
        await m.createTable(db.glucoseReadings);
        await m.createTable(db.meals);
        await m.createTable(db.healthSamples);
        await m.createTable(db.calibrationMetrics);
        await m.create(db.idxGlucoseReadingsExternalId);
        await m.create(db.idxHealthSamplesExternalId);
        break;

      case 3:
        // v2 → v3: correct the three cross-module achievement descriptions.
        //
        // Data-only; the schema is unchanged. The seeded descriptions each
        // named a different measure (workouts in a week, streak days, total
        // workouts) while AchievementRepositoryImpl checks one rule for all
        // three — 90%+ compliance over the past week plus a streak of
        // `requirement` days. Seeding only runs on an empty database, so
        // fixing seed_data.dart alone would leave every existing install
        // showing goals the app never evaluates.
        //
        // The literals below are frozen copies, deliberately not references
        // to seed_data.dart: a migration has to keep describing the same
        // v2 → v3 step even if the seed text changes again later.
        await _rewriteAchievementDescription(
          db,
          iconName: 'cross_balance_master',
          from: 'Achieve 100% medication compliance and 4 workouts in the '
              'same week',
          to: 'Keep 90%+ medication compliance this week and a 1-day '
              'workout streak',
        );
        await _rewriteAchievementDescription(
          db,
          iconName: 'cross_synced_up',
          from: 'Maintain both medication compliance and workout streak for '
              '30 days',
          to: 'Keep 90%+ medication compliance this week and a 30-day '
              'workout streak',
        );
        await _rewriteAchievementDescription(
          db,
          iconName: 'cross_wellness_warrior',
          from: 'Complete 50 workouts with 90%+ medication compliance',
          to: 'Keep 90%+ medication compliance this week and a 50-day '
              'workout streak',
        );
        break;

      default:
        throw Exception(
          'Unknown migration target version: $target. '
          'Did you forget to add a migration case?',
        );
    }

    log('Migration to v$target completed');
  }

  log('All migrations completed (v$from → v$to)');
}

/// Replaces one seeded achievement description, matched on [iconName].
///
/// Guarded on the old text so the update is idempotent and so a row that
/// already carries the corrected wording — or anything else — is left alone.
/// Only the description column is written: `unlockedAt` and every other
/// column stay untouched, so an achievement a user has already earned keeps
/// its unlock.
Future<void> _rewriteAchievementDescription(
  AppDatabase db, {
  required String iconName,
  required String from,
  required String to,
}) async {
  await (db.update(db.achievements)..where(
        (a) => a.iconName.equals(iconName) & a.description.equals(from),
      ))
      .write(AchievementsCompanion(description: Value(to)));
}
