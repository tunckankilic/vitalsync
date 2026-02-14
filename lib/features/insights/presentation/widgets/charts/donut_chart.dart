/// VitalSync — Donut Chart Widget.
///
/// Donut chart for compliance visualization.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../presentation/widgets/glassmorphic_card.dart';

/// Segment data for donut chart.
class DonutSegment {
  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Donut chart widget for compliance visualization.
///
/// Features:
/// - Multi-segment donut
/// - Animated fill
/// - Center percentage display
/// - Touch interaction
class DonutChart extends StatelessWidget {
  const DonutChart({
    required this.segments,
    this.centerValue,
    this.centerLabel,
    this.size = 200,
    super.key,
  });

  final List<DonutSegment> segments;
  final String? centerValue;
  final String? centerLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final total = segments.fold<double>(0, (sum, seg) => sum + seg.value);

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                        PieChartData(
                          sections: segments.map((segment) {
                            final percentage = segment.value / total * 100;
                            return PieChartSectionData(
                              value: segment.value,
                              color: segment.color,
                              title: '${percentage.toInt()}%',
                              radius: 60,
                              titleStyle: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              // Handle touch events if needed
                            },
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
                  // Center text
                  if (centerValue != null)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerValue!,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (centerLabel != null)
                          Text(
                            centerLabel!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: segments.map((segment) {
                return _LegendItem(
                  color: segment.color,
                  label: segment.label,
                  value: segment.value.toInt().toString(),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
