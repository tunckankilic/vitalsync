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
        // Example migration v1 → v2:
        // await m.addColumn(db.medications, db.medications.someNewColumn);
        // await m.addColumn(db.workoutSessions, db.workoutSessions.newField);
        break;

      case 3:
        // Future migration v2 → v3:
        // await m.createTable(db.someNewTable);
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
