/// Helper class for charting progress.
class ProgressData {
  const ProgressData({
    required this.date,
    required this.value,
    required this.label,
  });
  final DateTime date;
  final double value;
  final String label;
}
