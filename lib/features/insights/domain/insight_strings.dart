/// VitalSync — Centralized Insight Message Strings.
///
/// All user-facing strings from InsightEngine are collected here
/// for easy localization. Replace these with l10n lookups when
/// the insight layer gains access to a localisation delegate.
library;

/// Holds all insight titles and message templates used by [InsightEngine].
///
/// Each method returns a ready-to-display string. Parameterised
/// messages accept the dynamic values as arguments.
abstract final class InsightStrings {
  // ── Rule 1: Medication–Workout Correlation ──────────────────────────

  static String medWorkoutCorrelationPositive(int percentDiff) =>
      'Your workout performance is $percentDiff% higher on days when you '
      'take all your medications on time.';

  static String medWorkoutCorrelationNeutral =
      'Interesting pattern: your workout volume is slightly different on '
      'medication-compliant days.';

  static const String medWorkoutCorrelationTitle =
      'Medication & Workout Correlation';

  // ── Rule 2: Symptom–Exercise Pattern ────────────────────────────────

  static const String symptomExercisePatternTitle = 'Symptom-Exercise Pattern';

  static String symptomExercisePatternMessage(
    String symptomName,
    String category,
    int ratePercent,
  ) =>
      'Your $symptomName complaints tend to appear after $category workouts '
      '($ratePercent% of the time).';

  // ── Rule 3: Compliance-Streak Correlation ───────────────────────────

  static const String complianceStreakTitle = 'Health & Fitness Balance';

  static String complianceStreakBothHigh(int streak, int compliancePercent) =>
      'Both your health and fitness routines are going great — '
      '$streak-day workout streak with $compliancePercent% medication compliance!';

  static String complianceStreakHighComplianceLowStreak(int compliancePercent) =>
      'Your medication compliance is excellent at $compliancePercent%, '
      'but your workout streak could use a boost. Try a quick session today!';

  static String complianceStreakLowComplianceHighStreak(
    int streak,
    int compliancePercent,
  ) =>
      'Your workouts are on fire with a $streak-day streak! '
      "Don't forget your medications — compliance is at "
      '$compliancePercent% this week.';

  static const String complianceStreakBothLow =
      "This week has been quiet — let's get back on track with both "
      'medications and workouts!';

  // ── Rule 4: Compliance Weekday Pattern ──────────────────────────────

  static const String complianceWeekdayTitle = 'Medication Pattern';

  static String complianceWeekdayMessage(String dayName, int percentDrop) =>
      'Your medication compliance drops by $percentDrop% on ${dayName}s '
      '— would you like to adjust your reminder times?';

  // ── Rule 5: Symptom Trend ───────────────────────────────────────────

  static const String symptomTrendTitle = 'Symptom Trend Alert';

  static String symptomTrendMessage(
    String name,
    String prior,
    String recent,
  ) =>
      'Your $name severity has increased from $prior to $recent '
      'over the past week — you may want to discuss this with your doctor.';

  // ── Rule 6: Medication Adherence Milestone ──────────────────────────

  static const String medMilestoneTitle = 'Medication Milestone 🎉';

  static String medMilestoneMessage(int days) =>
      "You've taken all your medications on time for $days days "
      'straight! Incredible consistency!';

  // ── Rule 7: Volume Plateau ──────────────────────────────────────────

  static const String volumePlateauTitle = 'Volume Plateau Detected';

  static String volumePlateauMessage(int avgVolume) =>
      'Your workout volume has been flat for 3 weeks at ~$avgVolume kg/week. '
      'Consider a deload week or progressive overload to break through!';

  // ── Rule 8: Rest Day Suggestion ─────────────────────────────────────

  static const String restDayTitle = 'Rest Day Recommended';

  static String restDayMessage(int dayCount) =>
      "You've worked out $dayCount out of the last 5 days — "
      'a rest day today could be great for muscle recovery and growth!';

  // ── Rule 9: Workout Consistency ─────────────────────────────────────

  static const String workoutConsistencyTitle = 'Workout Pattern';

  static String workoutConsistencyMessage(String topDayStr) =>
      'You typically work out on $topDayStr — this consistency is great '
      'for building long-term habits!';

  // ── Rule 10: PR Proximity ───────────────────────────────────────────

  static const String prProximityTitle = 'PR Proximity Alert 🔥';

  static String prProximityMessage(
    String exerciseName,
    double setWeight,
    int setReps,
    double prWeight,
    int prReps,
  ) =>
      "You're very close to your $exerciseName PR! Your recent set "
      'was ${setWeight}kg × $setReps — '
      'PR is ${prWeight}kg × $prReps.';

  // ── Weekday Names ───────────────────────────────────────────────────

  static const Map<int, String> weekdayNames = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  static String weekdayName(int weekday) =>
      weekdayNames[weekday] ?? 'Unknown';
}
