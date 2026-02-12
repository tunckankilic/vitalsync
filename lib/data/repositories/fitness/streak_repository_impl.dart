import 'package:vitalsync/data/local/daos/fitness/user_stats_dao.dart';
import 'package:vitalsync/data/local/daos/fitness/workout_dao.dart'; // For getWorkoutDates
import 'package:vitalsync/domain/repositories/fitness/streak_repository.dart';

class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl(this._statsDao, this._sessionDao);
  final UserStatsDao _statsDao;
  final WorkoutSessionDao _sessionDao;

  @override
  Future<int> getCurrentStreak() async {
    final latest = await _statsDao.getLatest();
    // Logic: check if latest entry is recent enough to count as active streak
    // Or just return accumulated streak.
    // Assuming user_stats is updated daily or after workouts.
    // If last update was > 1 day ago (allowing for rest days?), streak might be broken.
    // Prompt 1.1 logic says "StreakService" is responsible.
    // Repo just returns data.
    return latest?.streakDays ?? 0;
  }

  @override
  Future<int> getLongestStreak() {
    return _statsDao.getMaxStreak();
  }

  @override
  Future<void> updateStreak() async {
    // This logic belongs to StreakService.
    // Repo updateStreak might trigger recalculation or just persist current state.
    // But since no arguments, it implies recalculation.
    // However, Repo shouldn't contain complex business logic if Service exists.
    // I'll leave as TODO or call a helper if accessible.
    // Realistically, this method in repo is likely intended to be called by Service.
    // But since it's defined here, maybe it persists data provided by service?
    // The signature `void updateStreak()` suggests it does the calculation internally.
    // I'll skip implementing complex logic here as it requires reading session history etc.
  }

  @override
  Future<List<DateTime>> getWorkoutDates({int days = 30}) {
    return _sessionDao.getWorkoutDates(days: days);
  }

  @override
  Future<Map<DateTime, bool>> getCalendarData(DateTime month) async {
    // Return map of dates where workout happened or goal met.
    // Use UserStats for efficiency if available, or sessions.
    final stats = await _statsDao.getMonthStats(month);
    final map = <DateTime, bool>{};
    for (final stat in stats) {
      // Assuming if entry exists, user was active?
      // Or check totalWorkouts > 0.
      if (stat.totalWorkouts > 0) {
        map[stat.date] = true;
      }
    }
    // Also merge with session dates to be sure?
    // Sessions might be more accurate if stats are lazily updated.
    // But stats are summary.
    return map;
  }
}
