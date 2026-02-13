abstract class StreakRepository {
  Future<int> getCurrentStreak();
  Future<int> getLongestStreak();
  Future<void> updateStreak();
  Future<List<DateTime>> getWorkoutDates({int days = 30});
  Future<Map<DateTime, bool>> getCalendarData(DateTime month);
}
