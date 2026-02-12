import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/exercise_category.dart';
import 'package:vitalsync/data/local/daos/fitness/workout_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/fitness/exercise_model.dart';
import 'package:vitalsync/domain/entities/fitness/exercise.dart';
import 'package:vitalsync/domain/repositories/fitness/exercise_repository.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  ExerciseRepositoryImpl(this._dao);
  final ExerciseDao _dao;

  @override
  Future<List<Exercise>> getAll() async {
    final results = await _dao.getAll();
    return results.map(ExerciseModel.fromDrift).toList();
  }

  @override
  Future<List<Exercise>> getByCategory(ExerciseCategory category) async {
    // DAO expects String for category?
    // Let's check DAO signature: Future<List<ExerciseData>> getByCategory(String category)
    // So we need to convert enum to string.
    final results = await _dao.getByCategory(category.name);
    return results.map(ExerciseModel.fromDrift).toList();
  }

  @override
  Future<Exercise?> getById(int id) async {
    final result = await _dao.getById(id);
    return result != null ? ExerciseModel.fromDrift(result) : null;
  }

  @override
  Future<List<Exercise>> search(String query) async {
    final results = await _dao.search(query);
    return results.map(ExerciseModel.fromDrift).toList();
  }

  @override
  Future<int> insertCustom(Exercise exercise) {
    return _dao.insertCustom(ExerciseModel.fromEntity(exercise).toCompanion());
  }

  @override
  Future<void> delete(int id) {
    // DAO: Future<int> deleteCustom(int id)
    // Repo: Future<void> delete(int id)
    // Assuming delete in Repo means deleteCustom (since default exercises probably shouldn't be deleted)
    return _dao.deleteCustom(id);
  }

  @override
  Stream<List<Exercise>> watchAll() {
    return _dao.watchAll().map(
      (list) => list.map(ExerciseModel.fromDrift).toList(),
    );
  }
}
