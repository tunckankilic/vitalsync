/// Helper class for correlation insights.
class CorrelationResult {
  const CorrelationResult({
    required this.factorA,
    required this.factorB,
    required this.strength,
    required this.sampleSize,
    required this.description,
  });
  final String factorA;
  final String factorB;
  final double strength; // -1.0 to 1.0
  final int sampleSize;
  final String description;
}
