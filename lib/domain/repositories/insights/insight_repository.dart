import 'package:vitalsync/core/enums/insight_category.dart';
import 'package:vitalsync/domain/entities/insights/insight.dart';

abstract class InsightRepository {
  Future<List<Insight>> getActive();
  Future<List<Insight>> getDismissed();
  Future<List<Insight>> getByCategory(InsightCategory category);
  Future<void> insert(Insight insight);
  Future<void> markAsRead(int id);
  Future<void> dismiss(int id);
  Future<void> clearExpired();
  Stream<List<Insight>> watchActive();
  Stream<List<Insight>> watchDismissed();
}
