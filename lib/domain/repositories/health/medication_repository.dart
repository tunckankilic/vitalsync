import 'package:vitalsync/domain/entities/health/medication.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getAll();
  Future<Medication?> getById(int id);
  Future<List<Medication>> getActive();
  Future<int> insert(Medication medication);
  Future<void> update(Medication medication);
  Future<void> delete(int id);
  Future<void> toggleActive(int id);
  Stream<List<Medication>> watchAll();
  Stream<List<Medication>> watchActive();
}
