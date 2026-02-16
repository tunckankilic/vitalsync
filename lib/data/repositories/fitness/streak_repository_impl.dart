import 'package:drift/drift.dart';
import 'package:vitalsync/data/local/daos/fitness/user_stats_dao.dart';
import 'package:vitalsync/data/local/daos/fitness/workout_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/domain/repositories/fitness/streak_repository.dart';

class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl(this._statsDao, this._sessionDao);
  final UserStatsDao _statsDao;
  final WorkoutSessionDao _sessionDao;

  @override
  Future<int> getCurrentStreak() async {
    // Get all workout dates from workout sessions
    final dates = await _sessionDao.getWorkoutDates(days: 365);

    if (dates.isEmpty) return 0;

    // Convert to date-only format (remove time component)
    final uniqueDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // Streak must include today or yesterday to be valid
    final mostRecent = uniqueDates.last;
    final daysSinceLastWorkout = todayOnly.difference(mostRecent).inDays;

    // If last workout was more than 1 day ago, streak is broken
    if (daysSinceLastWorkout > 1) return 0;

    // Calculate streak by going backwards from most recent date
    var streak = 1;
    for (var i = uniqueDates.length - 2; i >= 0; i--) {
      final diff = uniqueDates[i + 1].difference(uniqueDates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break; // Streak broken
      }
      // if diff == 0, it's the same day (duplicate), skip
    }

    return streak;
  }

  @override
  Future<int> getLongestStreak() async {
    // Get all workout dates from workout sessions
    final dates = await _sessionDao.getWorkoutDates(days: 365 * 2); // 2 years

    if (dates.isEmpty) return 0;

    // Convert to date-only format and sort
    final uniqueDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    var longestStreak = 1;
    var currentStreak = 1;

    for (var i = 1; i < uniqueDates.length; i++) {
      final diff = uniqueDates[i].difference(uniqueDates[i - 1]).inDays;

      if (diff == 1) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else if (diff > 1) {
        currentStreak = 1; // Reset streak
      }
      // if diff == 0, same day (duplicate), continue
    }

    return longestStreak;
  }

  @override
  Future<void> updateStreak() async {
    // Update user_stats table with current streak
    final currentStreak = await getCurrentStreak();

    // Get or create today's user stats entry
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final existing = await _statsDao.getByDate(todayOnly);

    if (existing != null) {
      // Update existing entry
      await _statsDao.insertOrUpdate(
        existing.toCompanion(true).copyWith(
          streakDays: Value(currentStreak),
        ),
      );
    } else {
      // Create new entry with current streak
      await _statsDao.insertOrUpdate(
        UserStatsCompanion.insert(
          date: todayOnly,
          streakDays: currentStreak,
          totalWorkouts: 0,
          totalVolume: 0.0,
          totalDuration: 0,
          medicationCompliance: 0.0,
        ),
      );
    }
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
