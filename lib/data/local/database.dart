/// VitalSync — Drift AppDatabase.
///
/// Single database instance shared across all modules.
/// Includes tables from health, fitness, insights, and shared modules.
/// Provides data export (JSON) and data deletion methods for GDPR.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:vitalsync/core/enums/achievement_type.dart';
import 'package:vitalsync/core/enums/equipment.dart';
import 'package:vitalsync/core/enums/exercise_category.dart';
import 'package:vitalsync/core/enums/gender.dart';
import 'package:vitalsync/core/enums/insight_category.dart';
import 'package:vitalsync/core/enums/insight_priority.dart';
import 'package:vitalsync/core/enums/insight_type.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/core/enums/workout_rating.dart';
import 'package:vitalsync/data/local/daos/fitness/user_stats_dao.dart';
// DAO imports
import 'package:vitalsync/data/local/daos/fitness/workout_dao.dart';
import 'package:vitalsync/data/local/daos/health/medication_dao.dart';
import 'package:vitalsync/data/local/daos/insights/insight_dao.dart';
import 'package:vitalsync/data/local/daos/shared/user_profile_dao.dart';
import 'package:vitalsync/data/local/migrations.dart';
// Table imports - Fitness
import 'package:vitalsync/data/local/tables/fitness/achievements_table.dart';
import 'package:vitalsync/data/local/tables/fitness/exercises_table.dart';
import 'package:vitalsync/data/local/tables/fitness/personal_records_table.dart';
import 'package:vitalsync/data/local/tables/fitness/template_exercises_table.dart';
import 'package:vitalsync/data/local/tables/fitness/user_stats_table.dart';
import 'package:vitalsync/data/local/tables/fitness/workout_sessions_table.dart';
import 'package:vitalsync/data/local/tables/fitness/workout_sets_table.dart';
import 'package:vitalsync/data/local/tables/fitness/workout_templates_table.dart';
// Table imports - Health
import 'package:vitalsync/data/local/tables/health/medication_logs_table.dart';
import 'package:vitalsync/data/local/tables/health/medications_table.dart';
import 'package:vitalsync/data/local/tables/health/symptoms_table.dart';
// Table imports - Insights
import 'package:vitalsync/data/local/tables/insights/generated_insights_table.dart';
// Table imports - Shared
import 'package:vitalsync/data/local/tables/shared/gdpr_consent_log_table.dart';
import 'package:vitalsync/data/local/tables/shared/sync_queue_table.dart';
import 'package:vitalsync/data/local/tables/shared/user_profile_table.dart';

part 'database.g.dart';

/// VitalSync Application Database.
/// Central Drift database containing all application data.
/// Uses offline-first architecture where Drift is the primary data source
/// and Firestore serves as cloud backup.
@DriftDatabase(
  tables: [
    // Shared tables
    UserProfiles,
    GdprConsentLogs,
    SyncQueue,
    // Health module tables
    Medications,
    MedicationLogs,
    Symptoms,
    // Fitness module tables
    Exercises,
    WorkoutTemplates,
    TemplateExercises,
    WorkoutSessions,
    WorkoutSets,
    PersonalRecords,
    UserStats,
    Achievements,
    // Insights module table
    GeneratedInsights,
  ],
  daos: [
    // Shared DAOs
    UserDao,
    GdprDao,
    SyncDao,
    // Health DAOs
    MedicationDao,
    MedicationLogDao,
    SymptomDao,
    // Fitness DAOs
    ExerciseDao,
    WorkoutTemplateDao,
    WorkoutSessionDao,
    PersonalRecordDao,
    AchievementDao,
    UserStatsDao,
    // Insights DAO
    InsightDao,
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
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // Create all tables
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        await runMigrations(m, this, from, to);
      },
    );
  }

  /// Helper method to add items to sync queue.
  /// Call this whenever data is modified (created, updated, deleted).
  Future<void> addToSyncQueue(
    String tableName,
    int recordId,
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    await syncDao.addToQueue(
      SyncQueueCompanion.insert(
        targetTable: tableName,
        recordId: recordId,
        operation: operation,
        payload: jsonEncode(payload),
      ),
    );
  }

  /// Exports all user data as JSON for GDPR compliance.
  /// Returns a Map containing all user data from all tables.
  /// This fulfills the GDPR right to data portability.
  Future<Map<String, dynamic>> exportAllData() async {
    // Get current user
    final user = await userDao.getCurrentUser();

    // Export shared data
    final consentLogs = await gdprDao.getAllConsentLogs();

    // Export health data
    final medications = await medicationDao.getAll();
    final medicationLogs = await medicationLogDao.getByDateRange(
      DateTime(2000),
      DateTime.now(),
    );
    final symptoms = await symptomDao.getAll();

    // Export fitness data
    final exercises = await exerciseDao.getAll();
    final templates = await workoutTemplateDao.getAll();
    final sessions = await workoutSessionDao.getAll();
    final allSets = <WorkoutSetData>[];
    for (final session in sessions) {
      final sets = await workoutSessionDao.getSessionSets(session.id);
      allSets.addAll(sets);
    }
    final prs = await personalRecordDao.getAll();
    final achievements = await achievementDao.getAll();

    // Export insights
    final insights = await (select(
      generatedInsights,
    )..where((tbl) => tbl.isDismissed.equals(false))).get();

    return {
      'export_timestamp': DateTime.now().toIso8601String(),
      'database_version': schemaVersion,
      'user_profile': user?.toJson(),
      'gdpr_consent_logs': consentLogs.map(_consentLogToJson).toList(),
      'health': {
        'medications': medications.map(_medicationToJson).toList(),
        'medication_logs': medicationLogs.map(_medicationLogToJson).toList(),
        'symptoms': symptoms.map(_symptomToJson).toList(),
      },
      'fitness': {
        'exercises': exercises.map(_exerciseToJson).toList(),
        'workout_templates': templates.map(_templateToJson).toList(),
        'workout_sessions': sessions.map(_sessionToJson).toList(),
        'workout_sets': allSets.map(_setToJson).toList(),
        'personal_records': prs.map(_prToJson).toList(),
        'achievements': achievements.map(_achievementToJson).toList(),
      },
      'insights': insights.map(_insightToJson).toList(),
    };
  }

  /// Deletes all user data from the database for GDPR compliance.
  /// This fulfills the GDPR right to erasure.
  /// Cascading deletes should be configured in table definitions.
  Future<void> deleteAllData() async {
    await transaction(() async {
      // Delete insights
      await delete(generatedInsights).go();

      // Delete fitness data (respecting foreign keys)
      await delete(workoutSets).go();
      await delete(workoutSessions).go();
      await delete(templateExercises).go();
      await delete(workoutTemplates).go();
      await delete(personalRecords).go();
      await delete(exercises).go();
      await delete(userStats).go();
      await delete(achievements).go();

      // Delete health data (respecting foreign keys)
      await delete(medicationLogs).go();
      await delete(medications).go();
      await delete(symptoms).go();

      // Delete shared data
      await delete(syncQueue).go();
      await delete(gdprConsentLogs).go();
      await delete(userProfiles).go();
    });
  }

  /// Closes the database connection.
  /// Should be called when the app is shutting down or when
  /// reinitializing the database connection.
  Future<void> closeConnection() async {
    await close();
  }

  // Helper methods for JSON serialization
  Map<String, dynamic> _consentLogToJson(GdprConsentLogData data) => {
    'id': data.id,
    'consent_type': data.consentType,
    'granted': data.granted,
    'policy_version': data.policyVersion,
    'timestamp': data.timestamp.toIso8601String(),
  };

  Map<String, dynamic> _medicationToJson(MedicationData data) => {
    'id': data.id,
    'name': data.name,
    'dosage': data.dosage,
    'frequency': data.frequency.name,
    'times': data.times,
    'start_date': data.startDate.toIso8601String(),
    'end_date': data.endDate?.toIso8601String(),
    'notes': data.notes,
    'color': data.color,
    'is_active': data.isActive,
    'created_at': data.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _medicationLogToJson(MedicationLogData data) => {
    'id': data.id,
    'medication_id': data.medicationId,
    'scheduled_time': data.scheduledTime.toIso8601String(),
    'taken_time': data.takenTime?.toIso8601String(),
    'status': data.status.name,
    'notes': data.notes,
    'created_at': data.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _symptomToJson(SymptomData data) => {
    'id': data.id,
    'name': data.name,
    'severity': data.severity,
    'date': data.date.toIso8601String(),
    'notes': data.notes,
    'tags': data.tags,
    'created_at': data.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _exerciseToJson(ExerciseData data) => {
    'id': data.id,
    'name': data.name,
    'category': data.category.name,
    'muscle_group': data.muscleGroup,
    'equipment': data.equipment.name,
    'instructions': data.instructions,
    'is_custom': data.isCustom,
    'created_at': data.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _templateToJson(WorkoutTemplateData data) => {
    'id': data.id,
    'name': data.name,
    'description': data.description,
    'color': data.color,
    'estimated_duration': data.estimatedDuration,
    'is_default': data.isDefault,
    'created_at': data.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _sessionToJson(WorkoutSessionData data) => {
    'id': data.id,
    'template_id': data.templateId,
    'name': data.name,
    'start_time': data.startTime.toIso8601String(),
    'end_time': data.endTime?.toIso8601String(),
    'total_volume': data.totalVolume,
    'notes': data.notes,
    'rating': data.rating,
    'created_at': data.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _setToJson(WorkoutSetData data) => {
    'id': data.id,
    'session_id': data.sessionId,
    'exercise_id': data.exerciseId,
    'set_number': data.setNumber,
    'reps': data.reps,
    'weight': data.weight,
    'is_warmup': data.isWarmup,
    'is_pr': data.isPR,
    'completed_at': data.completedAt.toIso8601String(),
  };

  Map<String, dynamic> _prToJson(PersonalRecordData data) => {
    'id': data.id,
    'exercise_id': data.exerciseId,
    'weight': data.weight,
    'reps': data.reps,
    'estimated_1rm': data.estimated1RM,
    'achieved_at': data.achievedAt.toIso8601String(),
  };

  Map<String, dynamic> _achievementToJson(AchievementData data) => {
    'id': data.id,
    'type': data.type.name,
    'title': data.title,
    'description': data.description,
    'requirement': data.requirement,
    'unlocked_at': data.unlockedAt?.toIso8601String(),
    'icon_name': data.iconName,
  };

  Map<String, dynamic> _insightToJson(GeneratedInsightData data) => {
    'id': data.id,
    'insight_type': data.insightType.name,
    'category': data.category.name,
    'title': data.title,
    'message': data.message,
    'data': data.data,
    'priority': data.priority,
    'is_read': data.isRead,
    'is_dismissed': data.isDismissed,
    'valid_until': data.validUntil.toIso8601String(),
    'generated_at': data.generatedAt.toIso8601String(),
  };
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
