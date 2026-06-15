import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/analytics/analytics_service.dart';
import 'package:vitalsync/domain/entities/fitness/workout_session.dart';
import 'package:vitalsync/domain/entities/fitness/workout_set.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_template_repository.dart';
import 'package:vitalsync/features/fitness/presentation/providers/workout_provider.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockWorkoutSessionRepository extends Mock
    implements WorkoutSessionRepository {}

class MockWorkoutTemplateRepository extends Mock
    implements WorkoutTemplateRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockWorkoutSessionRepository mockWorkoutRepo;
  late MockWorkoutTemplateRepository mockTemplateRepo;
  late MockAnalyticsService mockAnalytics;
  late ProviderContainer container;

  setUp(() {
    mockWorkoutRepo = MockWorkoutSessionRepository();
    mockTemplateRepo = MockWorkoutTemplateRepository();
    mockAnalytics = MockAnalyticsService();

    container = ProviderContainer(
      overrides: [
        workoutSessionRepositoryProvider.overrideWithValue(mockWorkoutRepo),
        workoutTemplateRepositoryProvider.overrideWithValue(mockTemplateRepo),
        analyticsServiceProvider.overrideWithValue(mockAnalytics),
      ],
    );

    // Register fallback values for mocktail matchers
    registerFallbackValue(
      WorkoutSession(
        id: 0,
        name: 'Fallback',
        startTime: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      WorkoutSet(
        id: 0,
        sessionId: 0,
        exerciseId: 0,
        setNumber: 1,
        reps: 0,
        weight: 0.0,
        isWarmup: false,
        isPR: false,
        completedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() {
    container.dispose();
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns the WorkoutNotifier from the container, triggering build().
  WorkoutNotifier getNotifier() {
    return container.read(workoutProvider.notifier);
  }

  // ── Test Groups ────────────────────────────────────────────────────────

  group('WorkoutNotifier.startSession', () {
    test('creates a session and returns the session ID', () async {
      // Arrange
      when(() => mockWorkoutRepo.startSession(any()))
          .thenAnswer((_) async => 42);
      when(
        () => mockAnalytics.logWorkoutStarted(
          templateName: any(named: 'templateName'),
          isCustom: any(named: 'isCustom'),
        ),
      ).thenAnswer((_) async {});

      // Act
      final notifier = getNotifier();
      final sessionId = await notifier.startSession(name: 'Push Day');

      // Assert
      expect(sessionId, 42);
      verify(() => mockWorkoutRepo.startSession(any())).called(1);
      verify(
        () => mockAnalytics.logWorkoutStarted(
          templateName: null,
          isCustom: true,
        ),
      ).called(1);
    });
  });

  group('WorkoutNotifier.addSet', () {
    test('adds a set to the active session', () async {
      // Arrange
      final now = DateTime.now();
      final activeSession = WorkoutSession(
        id: 1,
        name: 'Push Day',
        startTime: now,
        lastModifiedAt: now,
        createdAt: now,
      );

      when(() => mockWorkoutRepo.watchActiveSession())
          .thenAnswer((_) => Stream.value(activeSession));
      when(() => mockWorkoutRepo.getSessionSets(1))
          .thenAnswer((_) async => []);
      when(() => mockWorkoutRepo.addSet(any())).thenAnswer((_) async {});
      when(
        () => mockAnalytics.logSetLogged(
          exerciseName: any(named: 'exerciseName'),
          isPR: any(named: 'isPR'),
        ),
      ).thenAnswer((_) async {});

      // Act
      final notifier = getNotifier();
      await notifier.addSet(
        exerciseId: 10,
        reps: 8,
        weight: 60.0,
      );

      // Assert
      verify(() => mockWorkoutRepo.addSet(any())).called(1);
      verify(
        () => mockAnalytics.logSetLogged(
          exerciseName: null,
          isPR: false,
        ),
      ).called(1);
    });
  });

  group('WorkoutNotifier.endSession', () {
    test('completes the active workout session', () async {
      // Arrange
      final now = DateTime.now();
      final activeSession = WorkoutSession(
        id: 1,
        name: 'Push Day',
        startTime: now.subtract(const Duration(minutes: 45)),
        totalVolume: 3600.0,
        lastModifiedAt: now,
        createdAt: now,
      );

      when(() => mockWorkoutRepo.watchActiveSession())
          .thenAnswer((_) => Stream.value(activeSession));
      when(() => mockWorkoutRepo.getSessionSets(1)).thenAnswer(
        (_) async => [
          WorkoutSet(
            id: 1,
            sessionId: 1,
            exerciseId: 10,
            setNumber: 1,
            reps: 8,
            weight: 60.0,
            isWarmup: false,
            isPR: false,
            completedAt: now,
          ),
        ],
      );
      when(
        () => mockWorkoutRepo.endSession(
          any(),
          notes: any(named: 'notes'),
          rating: any(named: 'rating'),
          totalVolume: any(named: 'totalVolume'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockWorkoutRepo.closeOpenSessions(),
      ).thenAnswer((_) async {});
      when(
        () => mockAnalytics.logWorkoutCompleted(
          durationMinutes: any(named: 'durationMinutes'),
          totalVolume: any(named: 'totalVolume'),
          exerciseCount: any(named: 'exerciseCount'),
        ),
      ).thenAnswer((_) async {});

      // Act
      final notifier = getNotifier();
      await notifier.endSession(notes: 'Great workout');

      // Assert
      // Volume is computed from the working sets (8 reps × 60 kg), not the
      // stale value stored on the session.
      verify(
        () => mockWorkoutRepo.endSession(
          1,
          notes: 'Great workout',
          rating: null,
          totalVolume: 480.0,
        ),
      ).called(1);
      verify(
        () => mockAnalytics.logWorkoutCompleted(
          durationMinutes: any(named: 'durationMinutes'),
          totalVolume: 480.0,
          exerciseCount: 1,
        ),
      ).called(1);
    });
  });

  group('WorkoutNotifier.cancelSession', () {
    test('discards the active session and deletes it', () async {
      // Arrange
      final now = DateTime.now();
      final activeSession = WorkoutSession(
        id: 1,
        name: 'Push Day',
        startTime: now.subtract(const Duration(minutes: 10)),
        lastModifiedAt: now,
        createdAt: now,
      );

      when(() => mockWorkoutRepo.watchActiveSession())
          .thenAnswer((_) => Stream.value(activeSession));
      when(() => mockWorkoutRepo.deleteSession(1))
          .thenAnswer((_) async {});
      when(
        () => mockAnalytics.logWorkoutCancelled(
          durationMinutes: any(named: 'durationMinutes'),
        ),
      ).thenAnswer((_) async {});

      // Act
      final notifier = getNotifier();
      await notifier.cancelSession();

      // Assert
      verify(() => mockWorkoutRepo.deleteSession(1)).called(1);
      verify(
        () => mockAnalytics.logWorkoutCancelled(
          durationMinutes: any(named: 'durationMinutes'),
        ),
      ).called(1);
    });
  });
}
