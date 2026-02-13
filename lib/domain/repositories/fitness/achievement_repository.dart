import 'package:vitalsync/domain/entities/fitness/achievement.dart';

abstract class AchievementRepository {
  Future<List<Achievement>> getAll();
  Future<List<Achievement>> getUnlocked();
  Future<List<Achievement>> getLocked();
  Future<void> checkAndUnlock();
  Stream<List<Achievement>> watchAll();
}
