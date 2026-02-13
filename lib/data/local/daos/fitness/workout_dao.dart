/// VitalSync — Fitness Module DAOs.
///
/// Contains DAOs for all fitness-related database operations including
/// exercises, workout templates, sessions, sets, PRs, and achievements.
library;

import 'package:drift/drift.dart';

import 'package:vitalsync/data/local/database.dart';
import '../../tables/fitness/achievements_table.dart';
import '../../tables/fitness/exercises_table.dart';
import '../../tables/fitness/personal_records_table.dart';
import '../../tables/fitness/template_exercises_table.dart';
import '../../tables/fitness/workout_sessions_table.dart';
import '../../tables/fitness/workout_sets_table.dart';
import '../../tables/fitness/workout_templates_table.dart';

part 'workout_dao.g.dart';

/// DAO for exercise operations.
@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  /// Get all exercises.
  Future<List<ExerciseData>> getAll() {
    return select(exercises).get();
  }

  /// Get exercise by ID.
  Future<ExerciseData?> getById(int id) {
    return (select(
      exercises,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get exercises by category.
  Future<List<ExerciseData>> getByCategory(String category) {
    return (select(
      exercises,
    )..where((tbl) => tbl.category.equals(category))).get();
  }

  /// Search exercises by name.
  Future<List<ExerciseData>> search(String query) {
    return (select(exercises)
          ..where((tbl) => tbl.name.like('%$query%'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }

  /// Insert a custom exercise.
  Future<int> insertCustom(ExercisesCompanion exercise) {
    return into(exercises).insert(exercise);
  }

  /// Delete a custom exercise.
  Future<int> deleteCustom(int id) {
    return (delete(
      exercises,
    )..where((tbl) => tbl.id.equals(id) & tbl.isCustom.equals(true))).go();
  }

  /// Watch all exercises.
  Stream<List<ExerciseData>> watchAll() {
    return select(exercises).watch();
  }
}

/// DAO for workout template operations.
@DriftAccessor(tables: [WorkoutTemplates, TemplateExercises])
class WorkoutTemplateDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutTemplateDaoMixin {
  WorkoutTemplateDao(super.db);

  /// Get all templates.
  Future<List<WorkoutTemplateData>> getAll() {
    return select(workoutTemplates).get();
  }

  /// Get template by ID.
  Future<WorkoutTemplateData?> getById(int id) {
    return (select(
      workoutTemplates,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new template.
  Future<int> insert(WorkoutTemplatesCompanion template) {
    return into(workoutTemplates).insert(template);
  }

  /// Update a template.
  Future<bool> updateTemplate(WorkoutTemplateData template) {
    return update(workoutTemplates).replace(template);
  }

  /// Delete a template.
  Future<int> deleteTemplate(int id) {
    return (delete(workoutTemplates)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Get exercises for a template.
  Future<List<TemplateExerciseData>> getTemplateExercises(int templateId) {
    return (select(templateExercises)
          ..where((tbl) => tbl.templateId.equals(templateId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.orderIndex)]))
        .get();
  }

  /// Add exercise to template.
  Future<int> addExerciseToTemplate(TemplateExercisesCompanion exercise) {
    return into(templateExercises).insert(exercise);
  }

  /// Remove exercise from template.
  Future<int> removeExerciseFromTemplate(int templateId, int exerciseId) {
    return (delete(templateExercises)..where(
          (tbl) =>
              tbl.templateId.equals(templateId) &
              tbl.exerciseId.equals(exerciseId),
        ))
        .go();
  }

  /// Watch all templates.
  Stream<List<WorkoutTemplateData>> watchAll() {
    return select(workoutTemplates).watch();
  }
}

/// DAO for workout session operations.
@DriftAccessor(tables: [WorkoutSessions, WorkoutSets])
class WorkoutSessionDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutSessionDaoMixin {
  WorkoutSessionDao(super.db);

  /// Get all sessions.
  Future<List<WorkoutSessionData>> getAll() {
    return (select(
      workoutSessions,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.startTime)])).get();
  }

  /// Get session by ID.
  Future<WorkoutSessionData?> getById(int id) {
    return (select(
      workoutSessions,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get sessions within a date range.
  Future<List<WorkoutSessionData>> getByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(workoutSessions)
          ..where(
            (tbl) =>
                tbl.startTime.isBiggerOrEqualValue(start) &
                tbl.startTime.isSmallerOrEqualValue(end),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.startTime)]))
        .get();
  }

  /// Get the last completed session.
  Future<WorkoutSessionData?> getLastSession() {
    return (select(workoutSessions)
          ..where((tbl) => tbl.endTime.isNotNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.endTime)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get the active session (no end time).
  Future<WorkoutSessionData?> getActiveSession() {
    return (select(
      workoutSessions,
    )..where((tbl) => tbl.endTime.isNull())).getSingleOrNull();
  }

  /// Start a new session.
  Future<int> startSession(WorkoutSessionsCompanion session) {
    return into(workoutSessions).insert(session);
  }

  /// End a session.
  Future<int> endSession(int id, DateTime endTime) {
    return (update(workoutSessions)..where((tbl) => tbl.id.equals(id))).write(
      WorkoutSessionsCompanion(
        endTime: Value(endTime),
        lastModifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Add a set to a session.
  Future<int> addSet(WorkoutSetsCompanion set) {
    return into(workoutSets).insert(set);
  }

  /// Update a set.
  Future<bool> updateSet(WorkoutSetData set) {
    return update(workoutSets).replace(set);
  }

  /// Delete a set.
  Future<int> deleteSet(int id) {
    return (delete(workoutSets)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Get sets for a session.
  Future<List<WorkoutSetData>> getSessionSets(int sessionId) {
    return (select(workoutSets)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.completedAt)]))
        .get();
  }

  /// Watch active session.
  Stream<WorkoutSessionData?> watchActiveSession() {
    return (select(
      workoutSessions,
    )..where((tbl) => tbl.endTime.isNull())).watchSingleOrNull();
  }

  /// Get list of workout dates.
  Future<List<DateTime>> getWorkoutDates({int days = 30}) {
    final start = DateTime.now().subtract(Duration(days: days));
    final query = select(workoutSessions)
      ..where((tbl) => tbl.startTime.isBiggerOrEqualValue(start))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startTime)]);

    return query.map((row) => row.startTime).get();
  }
}

/// DAO for personal record operations.
@DriftAccessor(tables: [PersonalRecords])
class PersonalRecordDao extends DatabaseAccessor<AppDatabase>
    with _$PersonalRecordDaoMixin {
  PersonalRecordDao(super.db);

  /// Get all personal records.
  Future<List<PersonalRecordData>> getAll() {
    return (select(
      personalRecords,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.achievedAt)])).get();
  }

  /// Get PR for a specific exercise.
  Future<PersonalRecordData?> getForExercise(int exerciseId) {
    return (select(personalRecords)
          ..where((tbl) => tbl.exerciseId.equals(exerciseId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.estimated1RM)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get recent PRs.
  Future<List<PersonalRecordData>> getRecent({int limit = 10}) {
    return (select(personalRecords)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.achievedAt)])
          ..limit(limit))
        .get();
  }

  /// Insert a new PR.
  Future<int> insert(PersonalRecordsCompanion pr) {
    return into(personalRecords).insert(pr);
  }

  /// Watch recent PRs.
  Stream<List<PersonalRecordData>> watchRecent({int limit = 10}) {
    return (select(personalRecords)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.achievedAt)])
          ..limit(limit))
        .watch();
  }
}

/// DAO for achievement operations.
@DriftAccessor(tables: [Achievements])
class AchievementDao extends DatabaseAccessor<AppDatabase>
    with _$AchievementDaoMixin {
  AchievementDao(super.db);

  /// Get all achievements.
  Future<List<AchievementData>> getAll() {
    return select(achievements).get();
  }

  /// Get unlocked achievements.
  Future<List<AchievementData>> getUnlocked() {
    return (select(
      achievements,
    )..where((tbl) => tbl.unlockedAt.isNotNull())).get();
  }

  /// Get locked achievements.
  Future<List<AchievementData>> getLocked() {
    return (select(
      achievements,
    )..where((tbl) => tbl.unlockedAt.isNull())).get();
  }

  /// Unlock an achievement.
  Future<int> unlock(int id) {
    return (update(achievements)..where((tbl) => tbl.id.equals(id))).write(
      AchievementsCompanion(unlockedAt: Value(DateTime.now())),
    );
  }

  /// Watch all achievements.
  Stream<List<AchievementData>> watchAll() {
    return select(achievements).watch();
  }
}
