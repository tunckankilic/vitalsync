/// VitalSync — Insights Module DAO.
library;

import 'package:drift/drift.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/local/tables/insights/generated_insights_table.dart';

part 'insight_dao.g.dart';

/// DAO for generated insight operations.
@DriftAccessor(tables: [GeneratedInsights])
class InsightDao extends DatabaseAccessor<AppDatabase> with _$InsightDaoMixin {
  InsightDao(super.db);

  /// Get all active insights (not dismissed and not expired).
  Future<List<GeneratedInsightData>> getActive() {
    final now = DateTime.now();
    return (select(generatedInsights)
          ..where(
            (tbl) =>
                tbl.isDismissed.equals(false) &
                tbl.validUntil.isBiggerThanValue(now),
          )
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.priority),
            (tbl) => OrderingTerm.desc(tbl.generatedAt),
          ]))
        .get();
  }

  /// Get insights by category.
  Future<List<GeneratedInsightData>> getByCategory(String category) {
    final now = DateTime.now();
    return (select(generatedInsights)
          ..where(
            (tbl) =>
                tbl.category.equals(category) &
                tbl.isDismissed.equals(false) &
                tbl.validUntil.isBiggerThanValue(now),
          )
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.priority),
            (tbl) => OrderingTerm.desc(tbl.generatedAt),
          ]))
        .get();
  }

  /// Get unread insights count.
  Future<int> getUnreadCount() async {
    final now = DateTime.now();
    final query = selectOnly(generatedInsights)
      ..addColumns([generatedInsights.id.count()])
      ..where(
        generatedInsights.isRead.equals(false) &
            generatedInsights.isDismissed.equals(false) &
            generatedInsights.validUntil.isBiggerThanValue(now),
      );

    final result = await query.getSingle();
    return result.read(generatedInsights.id.count()) ?? 0;
  }

  /// Insert a new insight.
  Future<int> insert(GeneratedInsightsCompanion insight) {
    return into(generatedInsights).insert(insight);
  }

  /// Mark an insight as read.
  Future<int> markAsRead(int id) {
    return (update(generatedInsights)..where((tbl) => tbl.id.equals(id))).write(
      const GeneratedInsightsCompanion(isRead: Value(true)),
    );
  }

  /// Dismiss an insight.
  Future<int> dismiss(int id) {
    return (update(generatedInsights)..where((tbl) => tbl.id.equals(id))).write(
      const GeneratedInsightsCompanion(isDismissed: Value(true)),
    );
  }

  /// Clear expired insights.
  Future<int> clearExpired() {
    final now = DateTime.now();
    return (delete(
      generatedInsights,
    )..where((tbl) => tbl.validUntil.isSmallerThanValue(now))).go();
  }

  /// Watch active insights.
  Stream<List<GeneratedInsightData>> watchActive() {
    final now = DateTime.now();
    return (select(generatedInsights)
          ..where(
            (tbl) =>
                tbl.isDismissed.equals(false) &
                tbl.validUntil.isBiggerThanValue(now),
          )
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.priority),
            (tbl) => OrderingTerm.desc(tbl.generatedAt),
          ]))
        .watch();
  }
}
