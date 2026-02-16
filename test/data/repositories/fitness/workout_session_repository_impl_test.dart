import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/domain/entities/fitness/workout_session.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';

class MockWorkoutSessionRepository extends Mock
    implements WorkoutSessionRepository {}

void main() {
  late MockWorkoutSessionRepository mockRepo;

  final now = DateTime.now();

  WorkoutSession createSession({
    required int id,
    required String name,
    required DateTime startTime,
    DateTime? endTime,
    double totalVolume = 0.0,
    String? notes,
    int? rating,
  }) {
    return WorkoutSession(
      id: id,
      name: name,
      startTime: startTime,
      endTime: endTime,
      totalVolume: totalVolume,
      notes: notes,
      lastModifiedAt: now,
      createdAt: now,
    );
  }

  setUpAll(() {
    registerFallbackValue(WorkoutSession(
      id: 0,
      name: '',
      startTime: DateTime(2024),
      totalVolume: 0,
      lastModifiedAt: DateTime(2024),
      createdAt: DateTime(2024),
    ));
  });

  setUp(() {
    mockRepo = MockWorkoutSessionRepository();
  });

  group('Workout Session lifecycle', () {
    test('startSession returns new session id', () async {
      final session = createSession(id: 0, name: 'Push Day', startTime: now);
      when(() => mockRepo.startSession(any())).thenAnswer((_) async => 1);

      final id = await mockRepo.startSession(session);

      expect(id, 1);
    });

    test('endSession with notes and rating', () async {
      when(
        () => mockRepo.endSession(1, notes: 'Great!', rating: 5),
      ).thenAnswer((_) async {});

      await mockRepo.endSession(1, notes: 'Great!', rating: 5);

      verify(
        () => mockRepo.endSession(1, notes: 'Great!', rating: 5),
      ).called(1);
    });

    test('endSession without optional params', () async {
      when(() => mockRepo.endSession(1)).thenAnswer((_) async {});

      await mockRepo.endSession(1);

      verify(() => mockRepo.endSession(1)).called(1);
    });

    test('deleteSession removes session', () async {
      when(() => mockRepo.deleteSession(1)).thenAnswer((_) async {});

      await mockRepo.deleteSession(1);

      verify(() => mockRepo.deleteSession(1)).called(1);
    });
  });

  group('Workout volume and counting', () {
    test('getTotalVolume returns 0 when no sessions', () async {
      when(() => mockRepo.getTotalVolume()).thenAnswer((_) async => 0.0);

      final volume = await mockRepo.getTotalVolume();

      expect(volume, 0.0);
    });

    test('getTotalVolume sums across sessions', () async {
      when(() => mockRepo.getTotalVolume()).thenAnswer((_) async => 6500.0);

      final volume = await mockRepo.getTotalVolume();

      expect(volume, 6500.0);
    });

    test('getTotalVolume filters by days', () async {
      when(
        () => mockRepo.getTotalVolume(days: 7),
      ).thenAnswer((_) async => 3000.0);

      final volume = await mockRepo.getTotalVolume(days: 7);

      expect(volume, 3000.0);
    });

    test('getWorkoutCount returns 0 when empty', () async {
      when(() => mockRepo.getWorkoutCount()).thenAnswer((_) async => 0);

      final count = await mockRepo.getWorkoutCount();

      expect(count, 0);
    });

    test('getWorkoutCount with days filter', () async {
      when(() => mockRepo.getWorkoutCount(days: 7)).thenAnswer((_) async => 3);

      final count = await mockRepo.getWorkoutCount(days: 7);

      expect(count, 3);
    });

    test('getWorkoutDates returns date list', () async {
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 5),
      ];
      when(
        () => mockRepo.getWorkoutDates(days: 30),
      ).thenAnswer((_) async => dates);

      final result = await mockRepo.getWorkoutDates(days: 30);

      expect(result.length, 3);
    });
  });

  group('Workout session queries', () {
    test('getById returns null when not found', () async {
      when(() => mockRepo.getById(99)).thenAnswer((_) async => null);

      final result = await mockRepo.getById(99);

      expect(result, isNull);
    });

    test('getById returns session when found', () async {
      final session = createSession(
        id: 1,
        name: 'Push Day',
        startTime: DateTime(2024, 1, 15),
        totalVolume: 2500.0,
      );
      when(() => mockRepo.getById(1)).thenAnswer((_) async => session);

      final result = await mockRepo.getById(1);

      expect(result, isNotNull);
      expect(result!.name, 'Push Day');
      expect(result.totalVolume, 2500.0);
    });

    test('getLastSession returns most recent', () async {
      final session = createSession(
        id: 5,
        name: 'Leg Day',
        startTime: DateTime(2024, 1, 20),
      );
      when(() => mockRepo.getLastSession()).thenAnswer((_) async => session);

      final result = await mockRepo.getLastSession();

      expect(result, isNotNull);
      expect(result!.name, 'Leg Day');
    });

    test('getByDateRange returns filtered sessions', () async {
      final sessions = [
        createSession(id: 1, name: 'Push', startTime: DateTime(2024, 1, 10)),
        createSession(id: 2, name: 'Pull', startTime: DateTime(2024, 1, 12)),
      ];
      when(
        () => mockRepo.getByDateRange(any(), any()),
      ).thenAnswer((_) async => sessions);

      final result = await mockRepo.getByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );

      expect(result.length, 2);
    });
  });

  group('WorkoutSession entity', () {
    test('copyWith preserves unchanged fields', () {
      final session = createSession(
        id: 1,
        name: 'Push Day',
        startTime: DateTime(2024, 1, 1),
        totalVolume: 1500.0,
      );

      final updated = session.copyWith(name: 'Pull Day');

      expect(updated.name, 'Pull Day');
      expect(updated.id, 1); // Unchanged
      expect(updated.totalVolume, 1500.0); // Unchanged
    });

    test('equality works correctly', () {
      final session1 = createSession(
        id: 1,
        name: 'Push',
        startTime: DateTime(2024, 1, 1),
      );
      final session2 = session1.copyWith();

      expect(session1, equals(session2));
    });
  });
}
