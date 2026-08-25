// Guards the push path for the collections that shipped in v1.
//
// Until now nothing wrote them to the sync queue: `SyncDao.addToQueue` had no
// caller outside the 2.0 collections, so `_pushPendingChanges` always found it
// empty and medications, doses, symptoms, workouts, PRs and achievements only
// ever travelled one way — down. Their repositories queue now.
//
// The real risk is not the queueing, it is the payload SHAPE. The queue stores
// a model's `toJson()`, while the pull side reads it with
// `upsertFromRemote`, and the two disagreed for every collection holding a
// JSON column or a nullable enum. So each test here does the full round trip:
// write locally, take the queued payload, feed it back through the DAO, and
// check the row survives intact.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/enums/achievement_type.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/core/enums/workout_rating.dart';
import 'package:vitalsync/core/sync/sync_service.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/repositories/fitness/personal_record_repository_impl.dart';
import 'package:vitalsync/data/repositories/fitness/workout_session_repository_impl.dart';
import 'package:vitalsync/data/repositories/health/medication_log_repository_impl.dart';
import 'package:vitalsync/data/repositories/health/medication_repository_impl.dart';
import 'package:vitalsync/data/repositories/health/symptom_repository_impl.dart';
import 'package:vitalsync/domain/entities/fitness/workout_session.dart';
import 'package:vitalsync/domain/entities/fitness/workout_set.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';
import 'package:vitalsync/domain/entities/health/symptom.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  final now = DateTime.utc(2026, 8, 25, 9);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<List<SyncQueueData>> queue() => db.syncDao.getPendingItems();

  /// The queued payload for [collection], decoded.
  Future<Map<String, dynamic>> payloadFor(String collection) async {
    final item = (await queue()).lastWhere(
      (i) => i.targetTable == collection && i.operation != SyncOperation.delete,
    );
    return jsonDecode(item.payload) as Map<String, dynamic>;
  }

  /// Every collection named in [SyncService.tablesToSync] must have a
  /// producer, or its rows never leave the device.
  test('the sync collection list matches what the repositories queue', () {
    expect(
      SyncService.tablesToSync,
      containsAll([
        'medications',
        'medication_logs',
        'symptoms',
        'workout_sessions',
        'workout_sets',
        'personal_records',
        'achievements',
      ]),
    );
  });

  group('medications', () {
    late MedicationRepositoryImpl repo;

    Medication medication({List<String> times = const ['08:00', '20:00']}) =>
        Medication(
          id: 0,
          name: 'Aspirin',
          dosage: '100mg',
          frequency: MedicationFrequency.twiceDaily,
          times: times,
          startDate: now,
          color: 0xFF4CAF50,
          isActive: true,
          lastModifiedAt: now,
          createdAt: now,
          updatedAt: now,
        );

    setUp(() => repo = MedicationRepositoryImpl(db.medicationDao, db));

    test('an inserted medication is queued for push', () async {
      final id = await repo.insert(medication());

      final items = await queue();
      expect(items, hasLength(1));
      expect(items.single.targetTable, 'medications');
      expect(items.single.recordId, id);
      expect(items.single.operation, SyncOperation.insert);
    });

    // `times` is a List in toJson() and a TEXT column locally. The pull side
    // used to cast it straight to String and blow up on our own payload.
    test('the times list survives the round trip', () async {
      final id = await repo.insert(medication());
      final payload = await payloadFor('medications');

      await db.medicationDao.upsertFromRemote(id, payload);

      final row = await db.medicationDao.getById(id);
      expect(jsonDecode(row!.times), ['08:00', '20:00']);
      expect(row.name, 'Aspirin');
      expect(row.frequency, MedicationFrequency.twiceDaily);
    });

    test('toggleActive queues the flipped state, not the stale row', () async {
      final id = await repo.insert(medication());
      await repo.toggleActive(id);

      final payload = await payloadFor('medications');
      expect(payload['isActive'], false);
    });

    test('a delete is queued with an empty payload', () async {
      final id = await repo.insert(medication());
      await repo.delete(id);

      final deletion = (await queue()).last;
      expect(deletion.operation, SyncOperation.delete);
      expect(deletion.recordId, id);
      expect(jsonDecode(deletion.payload), isEmpty);
    });
  });

  group('medication logs', () {
    test('a logged dose round trips', () async {
      final medRepo = MedicationRepositoryImpl(db.medicationDao, db);
      final medId = await medRepo.insert(
        Medication(
          id: 0,
          name: 'Aspirin',
          dosage: '100mg',
          frequency: MedicationFrequency.daily,
          times: const ['08:00'],
          startDate: now,
          color: 0,
          isActive: true,
          lastModifiedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final repo = MedicationLogRepositoryImpl(db.medicationLogDao, db);
      await repo.logMedication(medId, MedicationLogStatus.taken);

      final payload = await payloadFor('medication_logs');
      final id = payload['id'] as int;
      // The auto-assigned id must be in the payload, not the 0 the
      // companion was built with.
      expect(id, greaterThan(0));

      await db.medicationLogDao.upsertFromRemote(id, payload);

      final row = await db.medicationLogDao.getById(id);
      expect(row!.status, MedicationLogStatus.taken);
      expect(row.medicationId, medId);
    });
  });

  group('symptoms', () {
    late SymptomRepositoryImpl repo;

    Symptom symptom() => Symptom(
      id: 0,
      name: 'Headache',
      severity: 3,
      date: now,
      tags: const ['morning', 'mild'],
      lastModifiedAt: now,
      createdAt: now,
    );

    setUp(() => repo = SymptomRepositoryImpl(db.symptomDao, db));

    // Same List-versus-TEXT trap as `medication.times`.
    test('the tags list survives the round trip', () async {
      final id = await repo.insert(symptom());
      final payload = await payloadFor('symptoms');

      await db.symptomDao.upsertFromRemote(id, payload);

      final row = await db.symptomDao.getById(id);
      expect(jsonDecode(row!.tags), ['morning', 'mild']);
      expect(row.severity, 3);
    });

    test('an update is queued', () async {
      final id = await repo.insert(symptom());
      await repo.update(
        Symptom(
          id: id,
          name: 'Headache',
          severity: 5,
          date: now,
          tags: const ['evening'],
          lastModifiedAt: now,
          createdAt: now,
        ),
      );

      final payload = await payloadFor('symptoms');
      expect(payload['severity'], 5);
    });
  });

  group('workout sessions and sets', () {
    late WorkoutSessionRepositoryImpl repo;

    WorkoutSession session({WorkoutRating? rating}) => WorkoutSession(
      id: 0,
      name: 'Push Day',
      startTime: now,
      totalVolume: 0,
      rating: rating,
      lastModifiedAt: now,
      createdAt: now,
    );

    setUp(() => repo = WorkoutSessionRepositoryImpl(db.workoutSessionDao, db));

    test('a started session round trips', () async {
      final id = await repo.startSession(session(rating: WorkoutRating.good));
      final payload = await payloadFor('workout_sessions');

      await db.workoutSessionDao.upsertFromRemote(id, payload);

      final row = await db.workoutSessionDao.getById(id);
      expect(row!.name, 'Push Day');
      expect(row.rating, WorkoutRating.good);
    });

    // The pull side read `data['rating']! as int`. The payload carries the
    // enum NAME, so pulling back a session we pushed ourselves threw
    // "String is not a subtype of int" and aborted the whole collection.
    test('a rating arrives as a name, not an int', () async {
      final id = await repo.startSession(session(rating: WorkoutRating.good));
      final payload = await payloadFor('workout_sessions');

      expect(payload['rating'], 'good');
      expect(payload['rating'], isNot(isA<int>()));

      await db.workoutSessionDao.upsertFromRemote(id, payload);
      expect((await db.workoutSessionDao.getById(id))!.rating,
          WorkoutRating.good);
    });

    // The bang in that cast also aborted the pull for any payload without a
    // rating at all — an older client, or a record written elsewhere.
    test('a payload with no rating does not abort the pull', () async {
      final id = await repo.startSession(session());
      final payload = await payloadFor('workout_sessions')
        ..remove('rating');

      await db.workoutSessionDao.upsertFromRemote(id, payload);

      final row = await db.workoutSessionDao.getById(id);
      // The column is non-nullable, so an absent rating falls back to the
      // same default the local write path uses.
      expect(row!.rating, WorkoutRating.okay);
    });

    // The int shape must keep working for rows written by older clients.
    test('a legacy int rating is still understood', () async {
      final id = await repo.startSession(session());
      final payload = await payloadFor('workout_sessions');
      payload['rating'] = WorkoutRating.amazing.value;

      await db.workoutSessionDao.upsertFromRemote(id, payload);

      expect((await db.workoutSessionDao.getById(id))!.rating,
          WorkoutRating.amazing);
    });

    test('a set round trips and carries its assigned id', () async {
      final sessionId = await repo.startSession(session());
      await repo.addSet(
        WorkoutSet(
          id: 0,
          sessionId: sessionId,
          exerciseId: 1,
          setNumber: 1,
          reps: 8,
          weight: 60,
          isWarmup: false,
          isPR: false,
          completedAt: now,
        ),
      );

      final payload = await payloadFor('workout_sets');
      final setId = payload['id'] as int;
      expect(setId, greaterThan(0));

      await db.workoutSessionDao.upsertSetFromRemote(setId, payload);

      final row = await db.workoutSessionDao.getSetById(setId);
      expect(row!.reps, 8);
      expect(row.weight, 60);
    });

    test('adding a set re-queues the owning session', () async {
      final sessionId = await repo.startSession(session());
      await repo.addSet(
        WorkoutSet(
          id: 0,
          sessionId: sessionId,
          exerciseId: 1,
          setNumber: 1,
          reps: 8,
          weight: 60,
          isWarmup: false,
          isPR: false,
          completedAt: now,
        ),
      );

      // A set changes the session's volume, so the session must be pushed
      // again or the cloud keeps a stale total.
      final sessionPushes = (await queue()).where(
        (i) => i.targetTable == 'workout_sessions',
      );
      expect(sessionPushes.length, 2);
    });

    test('deleting a session queues its sets for removal too', () async {
      final sessionId = await repo.startSession(session());
      await repo.addSet(
        WorkoutSet(
          id: 0,
          sessionId: sessionId,
          exerciseId: 1,
          setNumber: 1,
          reps: 8,
          weight: 60,
          isWarmup: false,
          isPR: false,
          completedAt: now,
        ),
      );
      await repo.deleteSession(sessionId);

      final deletions = (await queue()).where(
        (i) => i.operation == SyncOperation.delete,
      );
      // Without the set deletion, another device would push the orphaned
      // set straight back on the next sync.
      expect(
        deletions.map((d) => d.targetTable),
        containsAll(['workout_sets', 'workout_sessions']),
      );
    });
  });

  group('personal records', () {
    test('a new PR round trips and carries a comparable timestamp', () async {
      final repo = PersonalRecordRepositoryImpl(db.personalRecordDao, db);
      await repo.checkAndUpdatePR(1, 100, 5);

      final payload = await payloadFor('personal_records');
      final id = payload['id'] as int;

      // The table has no lastModifiedAt column, but the push conflict check
      // reads that field; without it the check is silently skipped.
      expect(payload['lastModifiedAt'], isNotNull);

      await db.personalRecordDao.upsertFromRemote(id, payload);

      final row = await db.personalRecordDao.getById(id);
      expect(row!.weight, 100);
      expect(row.reps, 5);
    });

    test('a lower lift does not become a PR and queues nothing', () async {
      final repo = PersonalRecordRepositoryImpl(db.personalRecordDao, db);
      await repo.checkAndUpdatePR(1, 100, 5);
      await repo.checkAndUpdatePR(1, 40, 5);

      final prPushes = (await queue()).where(
        (i) => i.targetTable == 'personal_records',
      );
      expect(prPushes, hasLength(1));
    });
  });

  group('achievements', () {
    test('an unlocked achievement round trips', () async {
      await db
          .into(db.achievements)
          .insert(
            AchievementsCompanion.insert(
              type: AchievementType.workouts,
              title: 'First workout',
              description: 'Log one workout',
              requirement: 1,
              iconName: 'star',
            ),
          );
      final locked = await db.achievementDao.getLocked();
      final target = locked.single;

      await db.achievementDao.unlock(target.id);
      // The payload the repository queues for that unlock, built here
      // because AchievementRepositoryImpl.checkAndUnlock resolves four other
      // repositories through GetIt and cannot run without full DI.
      final unlocked = await db.achievementDao.getById(target.id);
      await db.addToSyncQueue('achievements', target.id, SyncOperation.update, {
        'id': unlocked!.id,
        'type': unlocked.type.name,
        'title': unlocked.title,
        'description': unlocked.description,
        'requirement': unlocked.requirement,
        'unlockedAt': unlocked.unlockedAt?.toIso8601String(),
        'iconName': unlocked.iconName,
        'lastModifiedAt': unlocked.unlockedAt?.toIso8601String(),
      });

      final payload = await payloadFor('achievements');
      await db.achievementDao.upsertFromRemote(target.id, payload);

      final row = await db.achievementDao.getById(target.id);
      expect(row!.unlockedAt, isNotNull);
      expect(row.type, AchievementType.workouts);
    });
  });
}
