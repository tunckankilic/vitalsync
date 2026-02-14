/// VitalSync — Pattern Heatmap Widget.
///
/// Heatmap chart for pattern insights showing frequency patterns.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../presentation/widgets/glassmorphic_card.dart';

/// Cell data for heatmap.
class HeatmapCell {
  const HeatmapCell({
    required this.row,
    required this.column,
    required this.value,
  });

  final int row;
  final int column;
  final double value;
}

/// Heatmap chart widget for pattern insights.
///
/// Features:
/// - Grid layout (rows × columns)
/// - Color intensity based on frequency
/// - Touch interaction showing count
class PatternHeatmap extends StatefulWidget {
  const PatternHeatmap({
    required this.data,
    required this.rowLabels,
    required this.columnLabels,
    this.lowColor,
    this.highColor,
    super.key,
  });

  final List<HeatmapCell> data;
  final List<String> rowLabels;
  final List<String> columnLabels;
  final Color? lowColor;
  final Color? highColor;

  @override
  State<PatternHeatmap> createState() => _PatternHeatmapState();
}

class _PatternHeatmapState extends State<PatternHeatmap> {
  HeatmapCell? _selectedCell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveLowColor =
        widget.lowColor ?? colorScheme.primary.withValues(alpha: 0.2);
    final effectiveHighColor = widget.highColor ?? colorScheme.primary;

    // Find max value for normalization
    final maxValue = widget.data.fold<double>(
      0,
      (max, cell) => cell.value > max ? cell.value : max,
    );

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heatmap grid
            Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row labels
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 30), // Offset for column labels
                        ...widget.rowLabels.map((label) {
                          return SizedBox(
                            height: 40,
                            child: Center(
                              child: Text(
                                label,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Grid
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Column labels
                          Row(
                            children: widget.columnLabels.map((label) {
                              return Expanded(
                                child: SizedBox(
                                  height: 30,
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: theme.textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          // Grid cells
                          ...List.generate(widget.rowLabels.length, (rowIndex) {
                            return Row(
                              children: List.generate(
                                widget.columnLabels.length,
                                (colIndex) {
                                  final cell = widget.data.firstWhere(
                                    (c) =>
                                        c.row == rowIndex &&
                                        c.column == colIndex,
                                    orElse: () => HeatmapCell(
                                      row: rowIndex,
                                      column: colIndex,
                                      value: 0,
                                    ),
                                  );

                                  final intensity = maxValue > 0
                                      ? cell.value / maxValue
                                      : 0;
                                  final cellColor = Color.lerp(
                                    effectiveLowColor,
                                    effectiveHighColor,
                                    intensity.toDouble(),
                                  )!;

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedCell = cell;
                                        });
                                      },
                                      child: Container(
                                        height: 40,
                                        margin: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: cellColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: _selectedCell == cell
                                              ? Border.all(
                                                  color: colorScheme.primary,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            cell.value.toInt().toString(),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: intensity > 0.5
                                                      ? Colors.white
                                                      : colorScheme.onSurface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
            if (_selectedCell != null) ...[
              const SizedBox(height: 16),
              Text(
                '${widget.rowLabels[_selectedCell!.row]} × ${widget.columnLabels[_selectedCell!.column]}: ${_selectedCell!.value.toInt()} occurrences',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
