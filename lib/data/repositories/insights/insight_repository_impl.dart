import 'package:vitalsync/core/enums/insight_category.dart';
import 'package:vitalsync/data/local/daos/insights/insight_dao.dart';
import 'package:vitalsync/data/models/insights/insight_model.dart';
import 'package:vitalsync/domain/entities/insights/insight.dart';
import 'package:vitalsync/domain/repositories/insights/insight_repository.dart';

class InsightRepositoryImpl implements InsightRepository {
  InsightRepositoryImpl(this._dao);
  final InsightDao _dao;

  @override
  Future<List<Insight>> getActive() async {
    final results = await _dao.getActive();
    return results.map(InsightModel.fromDrift).toList();
  }

  @override
  Future<List<Insight>> getDismissed() async {
    final results = await _dao.getDismissed();
    return results.map(InsightModel.fromDrift).toList();
  }

  @override
  Future<List<Insight>> getByCategory(InsightCategory category) async {
    // Assuming DAO supports enum or we map it.
    // If GeneratedInsightData stores enum index or string, we need to pass appropriate type.
    // Let's assume DAO supports GeneratedInsightData objects filter or SQL expression.
    // But DAO method `getByCategory(InsightCategory category)` is likely what's generated or implemented.
    final results = await _dao.getByCategory(category.name);
    return results.map(InsightModel.fromDrift).toList();
  }

  @override
  Future<void> insert(Insight insight) {
    return _dao.insert(InsightModel.fromEntity(insight).toCompanion());
  }

  @override
  Future<void> markAsRead(int id) {
    return _dao.markAsRead(id);
  }

  @override
  Future<void> dismiss(int id) {
    return _dao.dismiss(id);
  }

  @override
  Future<void> clearExpired() {
    return _dao.clearExpired();
  }

  @override
  Stream<List<Insight>> watchActive() {
    return _dao.watchActive().map(
      (list) => list.map(InsightModel.fromDrift).toList(),
    );
  }

  @override
  Stream<List<Insight>> watchDismissed() {
    return _dao.watchDismissed().map(
      (list) => list.map(InsightModel.fromDrift).toList(),
    );
  }
}
