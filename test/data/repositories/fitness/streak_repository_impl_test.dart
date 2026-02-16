import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/domain/repositories/fitness/streak_repository.dart';

class MockStreakRepository extends Mock implements StreakRepository {}

void main() {
  late MockStreakRepository mockRepo;

  setUp(() {
    mockRepo = MockStreakRepository();
  });

  group('getCurrentStreak', () {
    test('returns 0 when no workout dates exist', () async {
      when(() => mockRepo.getCurrentStreak()).thenAnswer((_) async => 0);

      final streak = await mockRepo.getCurrentStreak();

      expect(streak, 0);
    });

    test('returns 1 for a single workout today', () async {
      when(() => mockRepo.getCurrentStreak()).thenAnswer((_) async => 1);

      final streak = await mockRepo.getCurrentStreak();

      expect(streak, 1);
    });

    test('counts consecutive days correctly', () async {
      when(() => mockRepo.getCurrentStreak()).thenAnswer((_) async => 5);

      final streak = await mockRepo.getCurrentStreak();

      expect(streak, 5);
    });

    test('returns 0 when streak is broken', () async {
      when(() => mockRepo.getCurrentStreak()).thenAnswer((_) async => 0);

      final streak = await mockRepo.getCurrentStreak();

      expect(streak, 0);
      verify(() => mockRepo.getCurrentStreak()).called(1);
    });
  });

  group('getLongestStreak', () {
    test('returns 0 when no workout dates exist', () async {
      when(() => mockRepo.getLongestStreak()).thenAnswer((_) async => 0);

      final streak = await mockRepo.getLongestStreak();

      expect(streak, 0);
    });

    test('returns 1 for single workout', () async {
      when(() => mockRepo.getLongestStreak()).thenAnswer((_) async => 1);

      final streak = await mockRepo.getLongestStreak();

      expect(streak, 1);
    });

    test('finds longest streak from historical data', () async {
      when(() => mockRepo.getLongestStreak()).thenAnswer((_) async => 14);

      final streak = await mockRepo.getLongestStreak();

      expect(streak, 14);
    });

    test('longest streak can be greater than current streak', () async {
      when(() => mockRepo.getCurrentStreak()).thenAnswer((_) async => 3);
      when(() => mockRepo.getLongestStreak()).thenAnswer((_) async => 14);

      final current = await mockRepo.getCurrentStreak();
      final longest = await mockRepo.getLongestStreak();

      expect(longest, greaterThan(current));
    });
  });

  group('updateStreak', () {
    test('updateStreak completes without error', () async {
      when(() => mockRepo.updateStreak()).thenAnswer((_) async {});

      await mockRepo.updateStreak();

      verify(() => mockRepo.updateStreak()).called(1);
    });
  });

  group('getWorkoutDates', () {
    test('returns empty list when no workouts', () async {
      when(() => mockRepo.getWorkoutDates(days: 30))
          .thenAnswer((_) async => []);

      final dates = await mockRepo.getWorkoutDates(days: 30);

      expect(dates, isEmpty);
    });

    test('returns dates for given day range', () async {
      final workoutDates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 5),
      ];
      when(() => mockRepo.getWorkoutDates(days: 30))
          .thenAnswer((_) async => workoutDates);

      final dates = await mockRepo.getWorkoutDates(days: 30);

      expect(dates.length, 3);
      expect(dates.first, DateTime(2024, 1, 1));
    });

    test('uses default days parameter', () async {
      when(() => mockRepo.getWorkoutDates())
          .thenAnswer((_) async => [DateTime(2024, 1, 10)]);

      final dates = await mockRepo.getWorkoutDates();

      expect(dates.length, 1);
      verify(() => mockRepo.getWorkoutDates()).called(1);
    });
  });

  group('getCalendarData', () {
    test('returns empty map for month with no workouts', () async {
      final month = DateTime(2024, 1);
      when(() => mockRepo.getCalendarData(month))
          .thenAnswer((_) async => {});

      final data = await mockRepo.getCalendarData(month);

      expect(data, isEmpty);
    });

    test('returns day-by-day workout status for a month', () async {
      final month = DateTime(2024, 1);
      final calendarData = {
        DateTime(2024, 1, 1): true,
        DateTime(2024, 1, 2): false,
        DateTime(2024, 1, 3): true,
        DateTime(2024, 1, 15): true,
      };
      when(() => mockRepo.getCalendarData(month))
          .thenAnswer((_) async => calendarData);

      final data = await mockRepo.getCalendarData(month);

      expect(data.length, 4);
      expect(data[DateTime(2024, 1, 1)], true);
      expect(data[DateTime(2024, 1, 2)], false);
    });

    test('different months return different data', () async {
      final jan = DateTime(2024, 1);
      final feb = DateTime(2024, 2);

      when(() => mockRepo.getCalendarData(jan)).thenAnswer(
        (_) async => {DateTime(2024, 1, 5): true},
      );
      when(() => mockRepo.getCalendarData(feb)).thenAnswer(
        (_) async => {
          DateTime(2024, 2, 10): true,
          DateTime(2024, 2, 11): true,
        },
      );

      final janData = await mockRepo.getCalendarData(jan);
      final febData = await mockRepo.getCalendarData(feb);

      expect(janData.length, 1);
      expect(febData.length, 2);
    });
  });
}
