// ignore_for_file: deprecated_member_use

/// VitalSync — Weekly Report Screen.
///
/// Comprehensive weekly health & fitness report with cross-module highlights.
library;

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../presentation/widgets/glassmorphic_card.dart';
import '../providers/weekly_report_provider.dart';
import '../widgets/charts/activity_rings.dart';
import '../widgets/charts/donut_chart.dart';
import '../widgets/charts/volume_bar_chart.dart';
import '../widgets/health_score_gauge.dart';
import '../widgets/share/weekly_report_compact_card.dart';
import '../widgets/share/weekly_report_share_card.dart';

/// Weekly report screen with comprehensive health & fitness summary.
///
/// Features:
/// - Week selector with horizontal date scroller
/// - Glassmorphic card series with staggered animations
/// - Health Summary Card (compliance donut chart)
/// - Fitness Summary Card (volume bar chart with ghost bars)
/// - Cross-Module Highlight Card (Health Score gauge)
/// - Activity Rings Summary
/// - Next Week Suggestions Card
/// - Branded share templates
class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());
  final GlobalKey _infographicKey = GlobalKey();
  final GlobalKey _compactKey = GlobalKey();

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final reportAsync = ref.watch(weeklyReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Report'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareOptions(context),
            tooltip: l10n.shareReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Week selector
          _buildWeekSelector(theme, colorScheme),
          // Report content
          Expanded(
            child: reportAsync.when(
              data: (report) => _buildReportContent(report, theme, colorScheme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error loading report: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector(ThemeData theme, ColorScheme colorScheme) {
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedWeekStart = _selectedWeekStart.subtract(
                  const Duration(days: 7),
                );
              });
            },
          ),
          Text(
            '${dateFormat.format(_selectedWeekStart)} - ${dateFormat.format(weekEnd)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final nextWeek = _selectedWeekStart.add(const Duration(days: 7));
              if (nextWeek.isBefore(DateTime.now())) {
                setState(() {
                  _selectedWeekStart = nextWeek;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(
    Map<String, dynamic> report,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Health Summary Card
          _buildHealthSummaryCard(report, theme, colorScheme)
              .animate()
              .fadeIn(delay: 0.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0, delay: 0.ms, duration: 600.ms),
          const SizedBox(height: 16),
          // Fitness Summary Card
          _buildFitnessSummaryCard(report, theme, colorScheme)
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 600.ms),
          const SizedBox(height: 16),
          // Cross-Module Highlight Card
          _buildCrossModuleCard(report, theme, colorScheme)
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 600.ms),
          const SizedBox(height: 16),
          // Activity Rings Summary
          _buildActivityRingsCard(report, theme, colorScheme)
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 600.ms),
          const SizedBox(height: 16),
          // Next Week Suggestions
          _buildSuggestionsCard(report, theme, colorScheme)
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildHealthSummaryCard(
    Map<String, dynamic> report,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final complianceRate = (report['compliance_rate'] as num?)?.toDouble() ?? 0;
    final takenCount = (report['taken_count'] as int?) ?? 0;
    final missedCount = (report['missed_count'] as int?) ?? 0;
    final skippedCount = (report['skipped_count'] as int?) ?? 0;
    final previousComplianceRate =
        (report['previous_compliance_rate'] as num?)?.toDouble() ?? 0;
    final problematicTimeSlot = report['problematic_time_slot'] as String?;

    final complianceChange = complianceRate - previousComplianceRate;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Compliance donut chart
            DonutChart(
              segments: [
                DonutSegment(
                  label: 'Taken',
                  value: takenCount.toDouble(),
                  color: Colors.green,
                ),
                DonutSegment(
                  label: 'Missed',
                  value: missedCount.toDouble(),
                  color: Colors.red,
                ),
                DonutSegment(
                  label: 'Skipped',
                  value: skippedCount.toDouble(),
                  color: Colors.grey,
                ),
              ],
              centerValue: '${(complianceRate * 100).toInt()}%',
              centerLabel: 'Compliance',
              size: 180,
            ),
            const SizedBox(height: 16),
            // vs previous week indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  complianceChange > 0
                      ? Icons.arrow_upward
                      : complianceChange < 0
                      ? Icons.arrow_downward
                      : Icons.arrow_forward,
                  color: complianceChange > 0
                      ? Colors.green
                      : complianceChange < 0
                      ? Colors.red
                      : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${(complianceChange.abs() * 100).toStringAsFixed(1)}% vs last week',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: complianceChange > 0
                        ? Colors.green
                        : complianceChange < 0
                        ? Colors.red
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Most problematic time slot badge
            if (problematicTimeSlot != null && missedCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Most missed: $problematicTimeSlot',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFitnessSummaryCard(
    Map<String, dynamic> report,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final workoutCount = (report['workout_count'] as int?) ?? 0;
    final totalVolume = (report['total_volume'] as num?)?.toDouble() ?? 0;
    final totalDuration = (report['total_duration'] as int?) ?? 0;
    final newPRs = (report['new_prs'] as List<dynamic>?) ?? [];
    final dailyVolumes = (report['daily_volumes'] as List<dynamic>?) ?? [];
    final previousDailyVolumes =
        (report['previous_daily_volumes'] as List<dynamic>?) ?? [];
    final bestWorkout = report['best_workout'] as Map<String, dynamic>?;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fitness Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Volume bar chart with ghost bars
            if (dailyVolumes.isNotEmpty)
              VolumeBarChart(
                data: List.generate(
                  7,
                  (index) => VolumeDataPoint(
                    day: ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                    currentVolume: index < dailyVolumes.length
                        ? (dailyVolumes[index] as num).toDouble()
                        : 0,
                    previousVolume: index < previousDailyVolumes.length
                        ? (previousDailyVolumes[index] as num).toDouble()
                        : 0,
                  ),
                ),
                height: 180,
              ),
            const SizedBox(height: 20),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.fitness_center,
                  label: 'Workouts',
                  value: workoutCount.toString(),
                  theme: theme,
                ),
                _buildStatItem(
                  icon: Icons.trending_up,
                  label: 'Volume',
                  value: '${totalVolume.toInt()}kg',
                  theme: theme,
                ),
                _buildStatItem(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: '${(totalDuration / 60).toInt()}h',
                  theme: theme,
                ),
              ],
            ),
            // Best workout highlight
            if (bestWorkout != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Best workout: ${bestWorkout['name']} — ${bestWorkout['volume']}kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (newPRs.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'New Personal Records 🏆',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              ...newPRs.take(3).map((pr) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '• ${pr['exercise']}: ${pr['weight']}kg × ${pr['reps']}',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCrossModuleCard(
    Map<String, dynamic> report,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Calculate health score: compliance 40% + workout consistency 30% + symptom inverse 30%
    final complianceRate = (report['compliance_rate'] as num?)?.toDouble() ?? 0;
    final workoutCount = (report['workout_count'] as int?) ?? 0;
    final symptomCount = (report['symptom_count'] as int?) ?? 0;

    final workoutConsistency = (workoutCount / 7).clamp(0.0, 1.0);
    final symptomInverse = 1.0 - (symptomCount / 10).clamp(0.0, 1.0);

    final healthScore =
        complianceRate * 0.4 + workoutConsistency * 0.3 + symptomInverse * 0.3;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Wellness',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Health Score gauge
            HealthScoreGauge(score: healthScore, size: 200),
            const SizedBox(height: 16),
            // Best day highlight
            Text(
              'Best Day: Wednesday',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '100% compliance + 1 workout + 0 symptoms',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRingsCard(
    Map<String, dynamic> report,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final complianceRate = (report['compliance_rate'] as num?)?.toDouble() ?? 0;
    final workoutCount = (report['workout_count'] as int?) ?? 0;
    final symptomCount = (report['symptom_count'] as int?) ?? 0;
    final previousReport = report['previous_week'] as Map<String, dynamic>?;

    final workoutConsistency = (workoutCount / 7).clamp(0.0, 1.0);
    final symptomInverse = 1.0 - (symptomCount / 10).clamp(0.0, 1.0);

    List<ActivityRingData>? previousRings;
    if (previousReport != null) {
      final prevCompliance =
          (previousReport['compliance_rate'] as num?)?.toDouble() ?? 0;
      final prevWorkouts = (previousReport['workout_count'] as int?) ?? 0;
      final prevSymptoms = (previousReport['symptom_count'] as int?) ?? 0;
      final prevWorkoutConsistency = (prevWorkouts / 7).clamp(0.0, 1.0);
      final prevSymptomInverse = 1.0 - (prevSymptoms / 10).clamp(0.0, 1.0);

      previousRings = [
        ActivityRingData(
          label: 'Health',
          progress: prevCompliance,
          color: Colors.green,
        ),
        ActivityRingData(
          label: 'Fitness',
          progress: prevWorkoutConsistency,
          color: Colors.orange,
        ),
        ActivityRingData(
          label: 'Wellness',
          progress: prevSymptomInverse,
          color: Colors.blue,
        ),
      ];
    }

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Rings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ActivityRings(
              rings: [
                ActivityRingData(
                  label: 'Health',
                  progress: complianceRate,
                  color: Colors.green,
                ),
                ActivityRingData(
                  label: 'Fitness',
                  progress: workoutConsistency,
                  color: Colors.orange,
                ),
                ActivityRingData(
                  label: 'Wellness',
                  progress: symptomInverse,
                  color: Colors.blue,
                ),
              ],
              size: 200,
              showComparison: previousRings != null,
              previousRings: previousRings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(
    Map<String, dynamic> report,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final suggestions = (report['suggestions'] as List<dynamic>?) ?? [];

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Week Suggestions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (suggestions.isEmpty)
              Text(
                'Keep up the great work!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              )
            else
              ...suggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        size: 20,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion.toString(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  void _showShareOptions(BuildContext context) {
    final reportAsync = ref.read(weeklyReportProvider);
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Share as Infographic (1080x1920)'),
                subtitle: const Text('Perfect for Instagram Stories'),
                onTap: () {
                  Navigator.pop(context);
                  reportAsync.whenData((report) {
                    _shareAsImage(
                      context,
                      _infographicKey,
                      WeeklyReportShareCard(
                        report: report,
                        weekStart: _selectedWeekStart,
                        weekEnd: weekEnd,
                      ),
                      'vitalsync_weekly_report.png',
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Share as Compact Card (1080x1080)'),
                subtitle: const Text('Perfect for general sharing'),
                onTap: () {
                  Navigator.pop(context);
                  reportAsync.whenData((report) {
                    _shareAsImage(
                      context,
                      _compactKey,
                      WeeklyReportCompactCard(
                        report: report,
                        weekStart: _selectedWeekStart,
                        weekEnd: weekEnd,
                      ),
                      'vitalsync_weekly_compact.png',
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Export as JSON'),
                subtitle: const Text('GDPR data portability'),
                onTap: () {
                  Navigator.pop(context);
                  reportAsync.whenData(_exportAsJson);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareAsImage(
    BuildContext context,
    GlobalKey key,
    Widget widget,
    String filename,
  ) async {
    try {
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating image...')));

      // Create a temporary widget tree to render
      final overlay = OverlayEntry(
        builder: (context) => Positioned(
          left: -10000,
          top: -10000,
          child: RepaintBoundary(key: key, child: widget),
        ),
      );

      Overlay.of(context).insert(overlay);

      // Wait for the widget to be rendered
      await Future.delayed(const Duration(milliseconds: 500));

      // Capture the image
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not find render boundary');
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Remove overlay
      overlay.remove();

      // Share the image
      await Share.shareXFiles([
        XFile.fromData(pngBytes, name: filename, mimeType: 'image/png'),
      ], text: 'My weekly report from VitalSync');

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
    }
  }

  Future<void> _exportAsJson(Map<String, dynamic> report) async {
    try {
      final json = jsonEncode(report);
      final bytes = utf8.encode(json);

      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          name:
              'vitalsync_report_${DateFormat('yyyy-MM-dd').format(_selectedWeekStart)}.json',
          mimeType: 'application/json',
        ),
      ], text: 'VitalSync Weekly Report Data');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report exported as JSON')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting: $e')));
    }
  }
}
