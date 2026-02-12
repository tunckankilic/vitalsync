/// VitalSync — Fitness Repository Implementations.
///
/// Concrete implementations for fitness repositories.
library;

import '../../../data/local/database.dart';
import '../../../domain/repositories/fitness/workout_repository.dart';

/// Concrete implementation of ExerciseRepository.
class ExerciseRepositoryImpl implements ExerciseRepository {
  ExerciseRepositoryImpl({required AppDatabase database})
    : _database = database;
  final AppDatabase _database;

  // TODO: Implement in Prompt 2.3
}

/// Concrete implementation of WorkoutTemplateRepository.
class WorkoutTemplateRepositoryImpl implements WorkoutTemplateRepository {
  WorkoutTemplateRepositoryImpl({required AppDatabase database})
    : _database = database;
  final AppDatabase _database;

  // TODO: Implement in Prompt 2.3
}

/// Concrete implementation of WorkoutSessionRepository.
class WorkoutSessionRepositoryImpl implements WorkoutSessionRepository {
  WorkoutSessionRepositoryImpl({required AppDatabase database})
    : _database = database;
  final AppDatabase _database;

  // TODO: Implement in Prompt 2.3
}

/// Concrete implementation of PersonalRecordRepository.
class PersonalRecordRepositoryImpl implements PersonalRecordRepository {
  PersonalRecordRepositoryImpl({required AppDatabase database})
    : _database = database;
  final AppDatabase _database;

  // TODO: Implement in Prompt 2.3
}

/// Concrete implementation of StreakRepository.
class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl({required AppDatabase database}) : _database = database;
  final AppDatabase _database;

  // TODO: Implement in Prompt 2.3
}

/// Concrete implementation of AchievementRepository.
class AchievementRepositoryImpl implements AchievementRepository {
  AchievementRepositoryImpl({required AppDatabase database})
    : _database = database;
  final AppDatabase _database;

  // TODO: Implement in Prompt 2.3
}
