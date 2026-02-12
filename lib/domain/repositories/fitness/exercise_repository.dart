import 'package:vitalsync/core/enums/exercise_category.dart';
import 'package:vitalsync/domain/entities/fitness/exercise.dart';

abstract class ExerciseRepository {
  Future<List<Exercise>> getAll();
  Future<List<Exercise>> getByCategory(ExerciseCategory category);
  Future<Exercise?> getById(int id);
  Future<List<Exercise>> search(String query);
  Future<int> insertCustom(Exercise exercise);
  Future<void> delete(int id);
  Stream<List<Exercise>> watchAll();
}
