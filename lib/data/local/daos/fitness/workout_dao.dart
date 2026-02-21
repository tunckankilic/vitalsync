/// VitalSync — Fitness Module DAOs.
///
/// Contains DAOs for all fitness-related database operations including
/// exercises, workout templates, sessions, sets, PRs, and achievements.
library;

import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/achievement_type.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/core/enums/workout_rating.dart';

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

  /// Update exercise order in template.
  Future<int> updateTemplateExerciseOrder(
    int templateId,
    int exerciseId,
    int orderIndex,
  ) {
    return (update(templateExercises)..where(
          (tbl) =>
              tbl.templateId.equals(templateId) &
              tbl.exerciseId.equals(exerciseId),
        ))
        .write(TemplateExercisesCompanion(orderIndex: Value(orderIndex)));
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

  /// End a session with optional notes and rating.
  Future<int> endSession(
    int id,
    DateTime endTime, {
    String? notes,
    int? rating,
  }) {
    return (update(workoutSessions)..where((tbl) => tbl.id.equals(id))).write(
      WorkoutSessionsCompanion(
        endTime: Value(endTime),
        notes: Value(notes),
        rating: Value(WorkoutRating.fromValue(rating!)),
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

  /// Delete a session and all its sets (CASCADE).
  Future<void> deleteSession(int sessionId) async {
    // First delete all sets for this session
    await (delete(
      workoutSets,
    )..where((tbl) => tbl.sessionId.equals(sessionId))).go();

    // Then delete the session itself
    await (delete(
      workoutSessions,
    )..where((tbl) => tbl.id.equals(sessionId))).go();
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

  /// Watch sets for a session.
  Stream<List<WorkoutSetData>> watchSessionSets(int sessionId) {
    return (select(workoutSets)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.completedAt)]))
        .watch();
  }

  /// Get list of workout dates.
  Future<List<DateTime>> getWorkoutDates({int days = 30}) {
    final start = DateTime.now().subtract(Duration(days: days));
    final query = select(workoutSessions)
      ..where((tbl) => tbl.startTime.isBiggerOrEqualValue(start))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startTime)]);

    return query.map((row) => row.startTime).get();
  }

  /// Inserts or updates a workout session from Firestore remote data.
  Future<void> upsertFromRemote(int id, Map<String, dynamic> data) async {
    await into(workoutSessions).insertOnConflictUpdate(
      WorkoutSessionsCompanion(
        id: Value(id),
        templateId: Value(data['templateId'] as int?),
        name: Value(data['name'] as String),
        startTime: Value(DateTime.parse(data['startTime'] as String)),
        endTime: Value(
          data['endTime'] != null
              ? DateTime.parse(data['endTime'] as String)
              : null,
        ),
        totalVolume: Value((data['totalVolume'] as num?)?.toDouble() ?? 0.0),
        notes: Value(data['notes'] as String?),
        rating: Value(WorkoutRating.fromValue(data['rating']! as int)),
        syncStatus: const Value(SyncStatus.synced),
        lastModifiedAt: Value(DateTime.parse(data['lastModifiedAt'] as String)),
        createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      ),
    );
  }

  /// Get a single workout set by ID.
  Future<WorkoutSetData?> getSetById(int id) {
    return (select(
      workoutSets,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Inserts or updates a workout set from Firestore remote data.
  Future<void> upsertSetFromRemote(int id, Map<String, dynamic> data) async {
    await into(workoutSets).insertOnConflictUpdate(
      WorkoutSetsCompanion(
        id: Value(id),
        sessionId: Value(data['sessionId'] as int),
        exerciseId: Value(data['exerciseId'] as int),
        setNumber: Value(data['setNumber'] as int),
        reps: Value(data['reps'] as int),
        weight: Value((data['weight'] as num).toDouble()),
        isWarmup: Value(data['isWarmup'] as bool? ?? false),
        isPR: Value(data['isPR'] as bool? ?? false),
        completedAt: Value(DateTime.parse(data['completedAt'] as String)),
      ),
    );
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

  /// Get personal record by ID.
  Future<PersonalRecordData?> getById(int id) {
    return (select(
      personalRecords,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Inserts or updates a personal record from Firestore remote data.
  Future<void> upsertFromRemote(int id, Map<String, dynamic> data) async {
    await into(personalRecords).insertOnConflictUpdate(
      PersonalRecordsCompanion(
        id: Value(id),
        exerciseId: Value(data['exerciseId'] as int),
        weight: Value((data['weight'] as num).toDouble()),
        reps: Value(data['reps'] as int),
        estimated1RM: Value((data['estimated1RM'] as num).toDouble()),
        achievedAt: Value(DateTime.parse(data['achievedAt'] as String)),
      ),
    );
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

  /// Get achievement by ID.
  Future<AchievementData?> getById(int id) {
    return (select(
      achievements,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Inserts or updates an achievement from Firestore remote data.
  Future<void> upsertFromRemote(int id, Map<String, dynamic> data) async {
    await into(achievements).insertOnConflictUpdate(
      AchievementsCompanion(
        id: Value(id),
        type: Value(AchievementType.fromDbValue(data['type'] as String)),
        title: Value(data['title'] as String),
        description: Value(data['description'] as String),
        requirement: Value(data['requirement'] as int),
        unlockedAt: Value(
          data['unlockedAt'] != null
              ? DateTime.parse(data['unlockedAt'] as String)
              : null,
        ),
        iconName: Value(data['iconName'] as String),
      ),
    );
  }
}
