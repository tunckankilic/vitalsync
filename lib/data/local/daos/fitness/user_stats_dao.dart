import 'package:drift/drift.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/local/tables/fitness/user_stats_table.dart';

part 'user_stats_dao.g.dart';

@DriftAccessor(tables: [UserStats])
class UserStatsDao extends DatabaseAccessor<AppDatabase>
    with _$UserStatsDaoMixin {
  UserStatsDao(super.db);

  Future<UserStatsData?> getLatest() {
    return (select(userStats)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<UserStatsData?> getByDate(DateTime date) {
    return (select(
      userStats,
    )..where((tbl) => tbl.date.equals(date))).getSingleOrNull();
  }

  Future<int> getMaxStreak() async {
    final query = select(userStats)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.streakDays)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.streakDays ?? 0;
  }

  Future<int> insertOrUpdate(UserStatsCompanion stat) {
    return into(userStats).insertOnConflictUpdate(stat);
  }

  Future<List<UserStatsData>> getMonthStats(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(
      month.year,
      month.month + 1,
      1,
    ).subtract(const Duration(days: 1));

    return (select(userStats)..where(
          (tbl) =>
              tbl.date.isBiggerOrEqualValue(start) &
              tbl.date.isSmallerOrEqualValue(end),
        ))
        .get();
  }
}
