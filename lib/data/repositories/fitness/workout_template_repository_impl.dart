import 'package:vitalsync/data/local/daos/fitness/workout_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/fitness/template_exercise_model.dart';
import 'package:vitalsync/data/models/fitness/workout_template_model.dart';
import 'package:vitalsync/domain/entities/fitness/template_exercise.dart';
import 'package:vitalsync/domain/entities/fitness/workout_template.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_template_repository.dart';

class WorkoutTemplateRepositoryImpl implements WorkoutTemplateRepository {
  WorkoutTemplateRepositoryImpl(this._dao);
  final WorkoutTemplateDao _dao;

  @override
  Future<List<WorkoutTemplate>> getAll() async {
    final results = await _dao.getAll();
    return results.map(WorkoutTemplateModel.fromDrift).toList();
  }

  @override
  Future<WorkoutTemplate?> getById(int id) async {
    final result = await _dao.getById(id);
    return result != null ? WorkoutTemplateModel.fromDrift(result) : null;
  }

  @override
  Future<WorkoutTemplate> getWithExercises(int id) async {
    final templateData = await _dao.getById(id);
    if (templateData == null) {
      throw Exception('Template not found'); // Should use custom exception
    }

    final exercisesData = await _dao.getTemplateExercises(id);
    final exercises = exercisesData
        .map(TemplateExerciseModel.fromDrift)
        .toList();

    return WorkoutTemplateModel.fromDrift(
      templateData,
    ).copyWith(exercises: exercises);
  }

  @override
  Future<int> insert(WorkoutTemplate template) {
    return _dao.insert(WorkoutTemplateModel.fromEntity(template).toCompanion());
  }

  @override
  Future<void> update(WorkoutTemplate template) async {
    final model = WorkoutTemplateModel.fromEntity(template);
    final data = WorkoutTemplateData(
      id: model.id,
      name: model.name,
      description: model.description,
      color: model.color,
      estimatedDuration: model.estimatedDuration,
      isDefault: model.isDefault,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
    await _dao.updateTemplate(data);
  }

  @override
  Future<void> delete(int id) {
    return _dao.deleteTemplate(id);
  }

  @override
  Future<void> addExerciseToTemplate(
    int templateId,
    TemplateExercise exercise,
  ) {
    return _dao.addExerciseToTemplate(
      TemplateExerciseModel.fromEntity(exercise).toCompanion(),
    );
  }

  @override
  Future<void> removeExerciseFromTemplate(int templateId, int exerciseId) {
    return _dao.removeExerciseFromTemplate(templateId, exerciseId);
  }

  @override
  Future<void> reorderExercises(int templateId, List<int> exerciseIds) async {
    // Ideally this should be done in a transaction in DAO but we can do it here sequentially
    for (var i = 0; i < exerciseIds.length; i++) {
      await _dao.updateTemplateExerciseOrder(templateId, exerciseIds[i], i);
    }
  }

  @override
  Stream<List<WorkoutTemplate>> watchAll() {
    return _dao.watchAll().map(
      (list) => list.map(WorkoutTemplateModel.fromDrift).toList(),
    );
  }

  @override
  Future<List<TemplateExercise>> getTemplateExercises(int templateId) async {
    final exercisesData = await _dao.getTemplateExercises(templateId);
    return exercisesData.map(TemplateExerciseModel.fromDrift).toList();
  }
}
