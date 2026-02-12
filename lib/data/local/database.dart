/// VitalSync — Drift AppDatabase.
///
/// Single database instance shared across all modules.
/// Includes tables from health, fitness, insights, and shared modules.
/// Provides data export (JSON) and data deletion methods for GDPR.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// TODO: Import table definitions when implemented in Prompt 2.1
// import 'tables/shared/user_profile_table.dart';
// import 'tables/health/medications_table.dart';

part 'database.g.dart';

/// VitalSync Application Database.
/// Central Drift database containing all application data.
/// Uses offline-first architecture where Drift is the primary data source
/// and Firestore serves as cloud backup.
/// Tables will be added in Prompt 2.1 as they are defined.
@DriftDatabase(
  tables: [
    // TODO: Add all table definitions here in Prompt 2.1
    // Shared: UserProfiles, GdprConsentLog
    // Health: Medications, MedicationLogs, Symptoms
    // Fitness: Exercises, WorkoutTemplates, TemplateExercises, WorkoutSessions,
    //          WorkoutSets, PersonalRecords, UserStats, Achievements
    // Insights: GeneratedInsights
    // Sync: SyncQueue
  ],
  daos: [
    // TODO: Add DAO definitions here in Prompt 2.1
    // HealthDao, FitnessDao, InsightsDao, SharedDao
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Factory constructor for creating the database instance.
  /// Opens a connection to the SQLite file in the app's documents directory.
  factory AppDatabase.connect() {
    return AppDatabase(_openConnection());
  }

  /// Database schema version.
  /// Increment this when making schema changes and provide migration logic.
  @override
  int get schemaVersion => 1;

  /// Database migration strategy.
  /// Currently set to OnCreate since no tables are defined yet.
  /// In Prompt 2.1, this will be updated to handle migrations properly.
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // TODO: Create all tables in Prompt 2.1
        // await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // TODO: Add migration logic when schema changes
        // Example:
        // if (from < 2) {
        //   await m.addColumn(medications, medications.newColumn);
        // }
      },
    );
  }

  /// Exports all user data as JSON for GDPR compliance.
  /// Returns a Map containing all user data from all tables.
  /// This fulfills the GDPR right to data portability.
  Future<Map<String, dynamic>> exportAllData() async {
    // TODO: Implement full data export in Prompt 2.1
    // Export data from all tables:
    // - user_profile
    // - medications, medication_logs, symptoms
    // - exercises, workout_sessions, workout_sets, personal_records, achievements
    // - generated_insights
    // - etc.

    return {
      'export_timestamp': DateTime.now().toIso8601String(),
      'database_version': schemaVersion,
      'note': 'Full data export will be implemented in Prompt 2.1',
      // 'user_profile': await userDao.exportData(),
      // 'medications': await healthDao.exportMedications(),
      // ... etc
    };
  }

  /// Deletes all user data from the database for GDPR compliance.
  /// This fulfills the GDPR right to erasure.
  /// Cascading deletes should be configured in table definitions.
  Future<void> deleteAllData() async {
    // TODO: Implement full data deletion in Prompt 2.1
    // Delete from all tables in proper order (respecting foreign keys)
    // Example:
    // await delete(medicationLogs).go();
    // await delete(medications).go();
    // await delete(symptoms).go();
    // ... etc

    print('Full data deletion will be implemented in Prompt 2.1');
  }

  /// Closes the database connection.
  /// Should be called when the app is shutting down or when
  /// reinitializing the database connection.
  Future<void> closeConnection() async {
    await close();
  }
}

/// Opens a connection to the SQLite database file.
/// The database file is stored in the application's documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'vitalsync.db'));

    return NativeDatabase(file);
  });
}
