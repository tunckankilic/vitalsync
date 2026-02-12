/// Helper class for daily health overview.
class DailyHealthSummary {
  // derived from symptoms or future mood tracking

  const DailyHealthSummary({
    required this.date,
    required this.medicationCompliance,
    required this.symptomsLogged,
    this.overallMood,
  });
  final DateTime date;
  final double medicationCompliance;
  final int symptomsLogged;
  final String? overallMood;
}
