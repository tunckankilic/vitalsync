// Unlock rules for achievements.
//
// These were untestable until the four repositories `checkAndUnlock` consults
// moved from `getIt<...>` calls inside the method to constructor parameters:
// exercising one rule used to mean booting the whole service locator.
//
// The tests below pin each rule to its own seeded description, because that
// is the contract the user is shown.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/enums/achievement_type.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/repositories/fitness/achievement_repository_impl.dart';
import 'package:vitalsync/domain/entities/fitness/personal_record.dart';
import 'package:vitalsync/domain/entities/fitness/workout_session.dart';
import 'package:vitalsync/domain/repositories/fitness/personal_record_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/streak_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';
import 'package:vitalsync/domain/repositories/health/medication_log_repository.dart';

class _MockStreakRepository extends Mock implements StreakRepository {}

class _MockWorkoutSessionRepository extends Mock
    implements WorkoutSessionRepository {}

class _MockPersonalRecordRepository extends Mock
    implements PersonalRecordRepository {}

class _MockMedicationLogRepository extends Mock
    implements MedicationLogRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _MockStreakRepository streakRepository;
  late _MockWorkoutSessionRepository workoutRepository;
  late _MockPersonalRecordRepository personalRecordRepository;
  late _MockMedicationLogRepository medicationLogRepository;
  late AchievementRepositoryImpl repo;

  final now = DateTime.utc(2026, 8, 25, 9);

  /// Inserts one locked achievement and returns its id.
  Future<int> seedAchievement(AchievementType type, int requirement) async {
    return db
        .into(db.achievements)
        .insert(
          AchievementsCompanion.insert(
            type: type,
            title: '$type $requirement',
            description: 'seeded',
            requirement: requirement,
            iconName: 'icon',
          ),
        );
  }

  Future<bool> isUnlocked(int id) async {
    final row = await db.achievementDao.getById(id);
    return row?.unlockedAt != null;
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    streakRepository = _MockStreakRepository();
    workoutRepository = _MockWorkoutSessionRepository();
    personalRecordRepository = _MockPersonalRecordRepository();
    medicationLogRepository = _MockMedicationLogRepository();

    // Neutral defaults: nothing unlocks unless a test says so.
    when(streakRepository.getCurrentStreak).thenAnswer((_) async => 0);
    when(
      () => workoutRepository.getTotalVolume(days: any(named: 'days')),
    ).thenAnswer((_) async => 0);
    when(workoutRepository.getAll).thenAnswer((_) async => []);
    when(personalRecordRepository.getAll).thenAnswer((_) async => []);
    when(
      () => medicationLogRepository.getOverallComplianceRate(
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => 0);

    repo = AchievementRepositoryImpl(
      db.achievementDao,
      db,
      streakRepository: streakRepository,
      workoutRepository: workoutRepository,
      personalRecordRepository: personalRecordRepository,
      medicationLogRepository: medicationLogRepository,
    );
  });

  tearDown(() async => db.close());

  group('streak', () {
    test('unlocks once the streak reaches the requirement', () async {
      final id = await seedAchievement(AchievementType.streak, 7);
      when(streakRepository.getCurrentStreak).thenAnswer((_) async => 7);

      await repo.checkAndUnlock();

      expect(await isUnlocked(id), isTrue);
    });

    test('stays locked one day short', () async {
      final id = await seedAchievement(AchievementType.streak, 7);
      when(streakRepository.getCurrentStreak).thenAnswer((_) async => 6);

      await repo.checkAndUnlock();

      expect(await isUnlocked(id), isFalse);
    });
  });

  group('workouts and volume', () {
    test('workout count unlocks at the requirement', () async {
      final id = await seedAchievement(AchievementType.workouts, 2);
      when(workoutRepository.getAll).thenAnswer(
        (_) async => [
          WorkoutSession(
            id: 1,
            name: 'a',
            startTime: now,
            lastModifiedAt: now,
            createdAt: now,
          ),
          WorkoutSession(
            id: 2,
            name: 'b',
            startTime: now,
            lastModifiedAt: now,
            createdAt: now,
          ),
        ],
      );

      await repo.checkAndUnlock();

      expect(await isUnlocked(id), isTrue);
    });

    test('total volume unlocks at the requirement', () async {
      final id = await seedAchievement(AchievementType.volume, 1000);
      when(
        () => workoutRepository.getTotalVolume(days: any(named: 'days')),
      ).thenAnswer((_) async => 1000);

      await repo.checkAndUnlock();

      expect(await isUnlocked(id), isTrue);
    });
  });

  test('PR count unlocks at the requirement', () async {
    final id = await seedAchievement(AchievementType.pr, 1);
    when(personalRecordRepository.getAll).thenAnswer(
      (_) async => [
        PersonalRecord(
          id: 1,
          exerciseId: 1,
          weight: 100,
          reps: 5,
          estimated1RM: 112.5,
          achievedAt: now,
        ),
      ],
    );

    await repo.checkAndUnlock();

    expect(await isUnlocked(id), isTrue);
  });

  group('medication compliance', () {
    // The window used to be hardcoded to 7 days and gated on
    // `requirement <= 7`.
    test('the compliance window matches the requirement in days', () async {
      await seedAchievement(AchievementType.medicationCompliance, 30);
      when(
        () => medicationLogRepository.getOverallComplianceRate(days: 30),
      ).thenAnswer((_) async => 1);

      await repo.checkAndUnlock();

      verify(
        () => medicationLogRepository.getOverallComplianceRate(days: 30),
      ).called(1);
    });

    // "Health Hero" — 100% compliance for 30 days — could never unlock,
    // because 30 <= 7 is false whatever the user did.
    test('the 30-day achievement is reachable', () async {
      final id = await seedAchievement(AchievementType.medicationCompliance, 30);
      when(
        () => medicationLogRepository.getOverallComplianceRate(days: 30),
      ).thenAnswer((_) async => 1);

      await repo.checkAndUnlock();

      expect(await isUnlocked(id), isTrue);
    });

    // "Perfect Day" asks for one compliant day, and used to need a full
    // compliant week because the window ignored the requirement.
    test('the 1-day achievement reads a 1-day window', () async {
      final id = await seedAchievement(AchievementType.medicationCompliance, 1);
      when(
        () => medicationLogRepository.getOverallComplianceRate(days: 1),
      ).thenAnswer((_) async => 1);

      await repo.checkAndUnlock();

      expect(await isUnlocked(id), isTrue);
    });

    test('anything short of full compliance stays locked', () async {
      final id = await seedAchievement(AchievementType.medicationCompliance, 7);
      when(
        () => medicationLogRepository.getOverallComplianceRate(days: 7),
      ).thenAnswer((_) async => 0.99);

      await repo.checkAndUnlock();

      expect(await isUnlocked(id), isFalse);
    });

    test('a user with no logs at all unlocks nothing', () async {
      final id = await seedAchievement(AchievementType.medicationCompliance, 1);
      // getOverallComplianceRate returns 0 for an empty log set.

      await repo.checkAndUnlock();

      expect(await isUnlocked(id), isFalse);
    });
  });

  group('consistency', () {
    // Documents current behaviour, which reads the requirement as streak
    // days for all three seeded achievements — see the note in the source.
    test('needs both 90% compliance and a streak at the requirement',
        () async {
      final id = await seedAchievement(AchievementType.consistency, 30);
      when(
        () => medicationLogRepository.getOverallComplianceRate(days: 7),
      ).thenAnswer((_) async => 0.9);
      when(streakRepository.getCurrentStreak).thenAnswer((_) async => 30);

      await repo.checkAndUnlock();

      expect(await isUnlocked(id), isTrue);
    });

    test('a long streak without compliance stays locked', () async {
      final id = await seedAchievement(AchievementType.consistency, 30);
      when(streakRepository.getCurrentStreak).thenAnswer((_) async => 50);

      await repo.checkAndUnlock();

      expect(await isUnlocked(id), isFalse);
    });
  });

  group('bookkeeping', () {
    test('an unlock is queued for the cloud', () async {
      final id = await seedAchievement(AchievementType.streak, 1);
      when(streakRepository.getCurrentStreak).thenAnswer((_) async => 1);

      await repo.checkAndUnlock();

      final queued = (await db.syncDao.getPendingItems())
          .where((i) => i.targetTable == 'achievements')
          .toList();
      expect(queued, hasLength(1));
      expect(queued.single.recordId, id);
      expect(queued.single.operation, SyncOperation.update);
    });

    test('an already unlocked achievement is not re-unlocked', () async {
      final id = await seedAchievement(AchievementType.streak, 1);
      when(streakRepository.getCurrentStreak).thenAnswer((_) async => 1);

      await repo.checkAndUnlock();
      final firstUnlockedAt = (await db.achievementDao.getById(id))!.unlockedAt;

      await repo.checkAndUnlock();

      // getLocked() no longer returns it, so nothing is queued twice.
      expect((await db.achievementDao.getById(id))!.unlockedAt,
          firstUnlockedAt);
      expect(
        (await db.syncDao.getPendingItems())
            .where((i) => i.targetTable == 'achievements'),
        hasLength(1),
      );
    });

    test('no locked achievements means no repository reads at all', () async {
      await repo.checkAndUnlock();

      verifyNever(streakRepository.getCurrentStreak);
      verifyNever(workoutRepository.getAll);
      verifyNever(personalRecordRepository.getAll);
    });
  });
}
