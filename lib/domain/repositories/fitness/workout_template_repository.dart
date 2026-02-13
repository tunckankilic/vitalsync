import 'package:vitalsync/domain/entities/fitness/template_exercise.dart';
import 'package:vitalsync/domain/entities/fitness/workout_template.dart';

abstract class WorkoutTemplateRepository {
  Future<List<WorkoutTemplate>> getAll();
  Future<WorkoutTemplate?> getById(int id);
  Future<WorkoutTemplate> getWithExercises(int id);
  Future<int> insert(WorkoutTemplate template);
  Future<void> update(WorkoutTemplate template);
  Future<void> delete(int id);
  Future<void> addExerciseToTemplate(int templateId, TemplateExercise exercise);
  Future<void> removeExerciseFromTemplate(int templateId, int exerciseId);
  Future<void> reorderExercises(int templateId, List<int> exerciseIds);
  Stream<List<WorkoutTemplate>> watchAll();
}
