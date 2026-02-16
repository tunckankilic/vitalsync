/// VitalSync — Fitness Module: Workout Providers.
///
/// Riverpod 2.0 providers for workout session and template management
/// with code generation.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/enums/workout_rating.dart';
import '../../../../domain/entities/fitness/exercise.dart';
import '../../../../domain/entities/fitness/workout_session.dart';
import '../../../../domain/entities/fitness/workout_set.dart';
import '../../../../domain/entities/fitness/workout_template.dart';
import '../../../../domain/repositories/fitness/workout_session_repository.dart';
import '../../../../domain/repositories/fitness/workout_template_repository.dart';
import '../providers/exercise_provider.dart';

part 'workout_provider.g.dart';

/// Provider for the WorkoutSessionRepository instance
@Riverpod(keepAlive: true)
WorkoutSessionRepository workoutSessionRepository(Ref ref) {
  return getIt<WorkoutSessionRepository>();
}

/// Provider for the WorkoutTemplateRepository instance
@Riverpod(keepAlive: true)
WorkoutTemplateRepository workoutTemplateRepository(Ref ref) {
  return getIt<WorkoutTemplateRepository>();
}

/// Provider for the AnalyticsService instance
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  return getIt<AnalyticsService>();
}

/// Stream provider for all workout templates
@riverpod
Stream<List<WorkoutTemplate>> workoutTemplates(Ref ref) {
  final repository = ref.watch(workoutTemplateRepositoryProvider);
  return repository.watchAll();
}

/// Stream provider for active workout session (nullable)
@riverpod
Stream<WorkoutSession?> activeSession(Ref ref) {
  final repository = ref.watch(workoutSessionRepositoryProvider);
  return repository.watchActiveSession();
}

/// Provider for workout session by ID
@riverpod
Future<WorkoutSession?> workoutSessionById(Ref ref, int id) async {
  final repository = ref.watch(workoutSessionRepositoryProvider);
  return repository.getById(id);
}

/// Provider for sets of a specific session
@riverpod
Stream<List<WorkoutSet>> sessionSets(Ref ref, int sessionId) {
  final repository = ref.watch(workoutSessionRepositoryProvider);
  return repository.watchSessionSets(sessionId);
}

/// Provider for recent workout sessions (last 5)
@riverpod
Future<List<WorkoutSession>> recentWorkouts(Ref ref) async {
  final repository = ref.watch(workoutSessionRepositoryProvider);
  final allWorkouts = await repository.getAll();

  // Sort by start time descending and take the last 5
  final sorted = allWorkouts.toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));

  return sorted.take(5).toList();
}

/// Provider for total completed workouts count
@riverpod
Future<int> totalWorkoutCount(Ref ref) async {
  final repository = ref.watch(workoutSessionRepositoryProvider);
  return repository.getWorkoutCount();
}

/// Stream provider for sets of the active session
@riverpod
Stream<List<WorkoutSet>> activeSessionSets(Ref ref) {
  final activeSessionAsync = ref.watch(activeSessionProvider);

  return activeSessionAsync.when(
    data: (session) {
      if (session == null) return Stream.value([]);
      final repository = ref.watch(workoutSessionRepositoryProvider);
      return repository.watchSessionSets(session.id);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
}

/// Stream provider for exercises in the active session
/// Combines exercises from the template (if any) and exercises from logged sets
@riverpod
Future<List<Exercise>> activeSessionExercises(Ref ref) async {
  final activeSession = await ref.watch(activeSessionProvider.future);
  if (activeSession == null) return [];

  final repository = ref.watch(exerciseRepositoryProvider);
  final exerciseIds = <int>{};

  // 1. Get exercises from template
  if (activeSession.templateId != null) {
    final templateRepo = ref.watch(workoutTemplateRepositoryProvider);
    final templateExercises = await templateRepo.getTemplateExercises(
      activeSession.templateId!,
    );
    exerciseIds.addAll(templateExercises.map((e) => e.exerciseId));
  }

  // 2. Get exercises from logged sets
  final sets = await ref.watch(activeSessionSetsProvider.future);
  exerciseIds.addAll(sets.map((s) => s.exerciseId));

  if (exerciseIds.isEmpty) return [];

  // 3. Fetch exercise details
  // Ideally repository should have getByIds, but we'll loop for now or use getAll if feasible
  // For better performance, we should add getByIds to repo, but let's stick to existing methods.
  // efficient way: fetch all and filter? Or fetch one by one?
  // If list is small (it is for a workout), one by one is fine.

  final exercises = <Exercise>[];
  for (final id in exerciseIds) {
    final exercise = await repository.getById(id);
    if (exercise != null) {
      exercises.add(exercise);
    }
  }

  return exercises;
}

/// Notifier for workout session lifecycle management
@riverpod
class WorkoutNotifier extends _$WorkoutNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Start a new workout session
  /// [templateId] - Optional template to use
  /// [name] - Name of the workout session
  Future<int> startSession({required String name, int? templateId}) async {
    state = const AsyncValue.loading();

    final repository = ref.read(workoutSessionRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);

    final result = await AsyncValue.guard(() async {
      // Get template name if using a template
      String? templateName;
      final isCustom = templateId == null;

      if (templateId != null) {
        final templateRepo = ref.read(workoutTemplateRepositoryProvider);
        final template = await templateRepo.getById(templateId);
        templateName = template?.name;
      }

      // Create new session
      final now = DateTime.now();
      final session = WorkoutSession(
        id: 0, // Will be assigned by DB
        templateId: templateId,
        name: name,
        startTime: now,
        endTime: null,
        totalVolume: 0.0,
        notes: null,
        rating: null,
        lastModifiedAt: now,
        createdAt: now,
      );

      final sessionId = await repository.startSession(session);

      // Fire analytics event
      await analytics.logWorkoutStarted(
        templateName: templateName,
        isCustom: isCustom,
      );

      return sessionId;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    return result.value as int;
  }

  /// Add a set to the active workout session
  /// [exerciseId] - Exercise being performed
  /// [reps] - Number of repetitions
  /// [weight] - Weight used
  /// [isWarmup] - Whether this is a warmup set
  Future<void> addSet({
    required int exerciseId,
    required int reps,
    required double weight,
    bool isWarmup = false,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(workoutSessionRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);

    state = await AsyncValue.guard(() async {
      // Get active session
      final activeSession = await repository.watchActiveSession().first;
      if (activeSession == null) {
        throw Exception('No active workout session');
      }

      // Get existing sets for this exercise to determine set number
      final existingSets = await repository.getSessionSets(activeSession.id);
      final setsForExercise = existingSets
          .where((s) => s.exerciseId == exerciseId)
          .toList();
      final setNumber = setsForExercise.length + 1;

      // Create workout set
      final now = DateTime.now();
      final set = WorkoutSet(
        id: 0, // Will be assigned by DB
        sessionId: activeSession.id,
        exerciseId: exerciseId,
        setNumber: setNumber,
        reps: reps,
        weight: weight,
        isWarmup: isWarmup,
        isPR: false, // Will be determined by repository
        completedAt: now,
      );

      await repository.addSet(set);

      // Fire analytics event
      await analytics.logSetLogged(
        exerciseName: null, // Exercise name not readily available here
        isPR: set.isPR,
      );
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Update an existing set
  /// [setId] - ID of the set to update
  /// [reps] - New number of repetitions
  /// [weight] - New weight
  Future<void> updateSet({
    required int setId,
    required int reps,
    required double weight,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(workoutSessionRepositoryProvider);

    state = await AsyncValue.guard(() async {
      // Get active session
      final activeSession = await repository.watchActiveSession().first;
      if (activeSession == null) {
        throw Exception('No active workout session');
      }

      // Get the existing set
      final sets = await repository.getSessionSets(activeSession.id);
      final existingSet = sets.firstWhere((s) => s.id == setId);

      // Update the set
      final updatedSet = existingSet.copyWith(
        reps: reps,
        weight: weight,
        completedAt: DateTime.now(),
      );

      await repository.updateSet(updatedSet);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Delete a set from the active session
  /// [setId] - ID of the set to delete
  Future<void> deleteSet(int setId) async {
    state = const AsyncValue.loading();

    final repository = ref.read(workoutSessionRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.deleteSet(setId);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// End the active workout session
  /// [notes] - Optional workout notes
  /// [rating] - Optional workout rating
  Future<void> endSession({String? notes, WorkoutRating? rating}) async {
    state = const AsyncValue.loading();

    final repository = ref.read(workoutSessionRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);

    state = await AsyncValue.guard(() async {
      // Get active session
      final activeSession = await repository.watchActiveSession().first;
      if (activeSession == null) {
        throw Exception('No active workout session');
      }

      // Get session sets to calculate metrics
      final sets = await repository.getSessionSets(activeSession.id);
      final exerciseCount = sets.map((s) => s.exerciseId).toSet().length;
      final durationMinutes = DateTime.now()
          .difference(activeSession.startTime)
          .inMinutes;

      // End the session
      await repository.endSession(
        activeSession.id,
        notes: notes,
        rating: rating?.index,
      );

      // Fire analytics event
      await analytics.logWorkoutCompleted(
        durationMinutes: durationMinutes,
        totalVolume: activeSession.totalVolume,
        exerciseCount: exerciseCount,
      );
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Cancel the active workout session
  Future<void> cancelSession() async {
    state = const AsyncValue.loading();

    final repository = ref.read(workoutSessionRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);

    state = await AsyncValue.guard(() async {
      // Get active session
      final activeSession = await repository.watchActiveSession().first;
      if (activeSession == null) {
        throw Exception('No active workout session');
      }

      final durationMinutes = DateTime.now()
          .difference(activeSession.startTime)
          .inMinutes;

      // Fire analytics event
      await analytics.logWorkoutCancelled(durationMinutes: durationMinutes);

      // Delete session and all its sets from database
      await repository.deleteSession(activeSession.id);

      // Clear state - no active session
      return;
    });

    if (state.hasError) {
      throw state.error!;
    }
  }
}
