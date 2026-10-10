import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/wahoo_header.dart';
import '../../../activities/presentation/bloc/activity_bloc.dart';
import '../../../activities/presentation/bloc/activity_state.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../../../home/presentation/bloc/heart_rate_bloc.dart';
import '../../../home/presentation/bloc/heart_rate_state.dart';
import '../../data/models/hr_trend.dart';
import '../../data/models/weekly_hr_data.dart';

/// Wahoo-style History screen.
///
/// Inspired by Wahoo screen 3 ("ELEMNT BOLT 2B58" sensor view):
/// - ALL-CAPS title with action icons on the right.
/// - A "Device" header card showing connection / battery summary.
/// - "Sensors" sub-section with a 2-column grid of connected sensors.
/// - "Choose a route" pill.
/// - Heart Rate Trends section with a thin blue line chart.
/// - Recent HR readings list.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(LoadWeeklyData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      appBar: WahooHeader(
        title: 'History',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined,
                color: AppColors.brandBlue),
            tooltip: 'Export CSV',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocListener<HeartRateBloc, HeartRateState>(
          // Refresh the dense HR trend whenever a new live sample lands
          // so the chart updates in step with the Workout tab.
          listenWhen: (prev, next) => prev.currentBpm != next.currentBpm,
          listener: (context, _) {
            context.read<HistoryBloc>().add(LoadHrTrend());
          },
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DeviceHeaderCard(),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel('Sensors'),
              const SizedBox(height: AppSpacing.sm),
              const _HrSensorCard(),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(child: _RoutePicker()),
                  const SizedBox(width: AppSpacing.md),
                  _LogActivityButton(
                    onTap: () => context.go('/record'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _SectionLabel('Heart Rate Trends'),
              const SizedBox(height: AppSpacing.md),
              const _HrTrendChart(),
              const SizedBox(height: AppSpacing.lg),
              const _WeeklyHrChart(),
              const SizedBox(height: AppSpacing.xl),

              _SectionLabel('Activity Summary'),
              const SizedBox(height: AppSpacing.md),
              const _ActivitySummary(),
              const SizedBox(height: AppSpacing.xl),

              _SectionLabel('Recent Heart Rate'),
              const SizedBox(height: AppSpacing.md),
              const _RecentHrCard(),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

// ─── Section label (no icon, all-caps tracking) ────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label.toUpperCase(), style: AppTypography.sectionHeader),
      ],
    );
  }
}

// ─── Device header card (mirrors the Wahoo sensor-detail top card) ─────
class _DeviceHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.cards),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandBlueTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.watch_outlined,
                  color: AppColors.brandBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heart Rate Sensor',
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Press start on HRM',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── HR sensor card ─────────────────────────────────────────────────────
class _HrSensorCard extends StatelessWidget {
  const _HrSensorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.cards),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_outline, color: AppColors.brandBlue, size: 18),
              const SizedBox(width: 6),
              Text(
                'Connected',
                style: AppTypography.caption.copyWith(
                  color: AppColors.brandBlueDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'HR',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.inkBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Searching…',
            style: AppTypography.caption.copyWith(
              color: AppColors.pewter,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── "Choose a route" pill ─────────────────────────────────────────────
class _RoutePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.cards),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.alt_route_outlined,
            color: AppColors.brandBlue,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Choose a route',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.diamond_outlined,
            color: AppColors.brandBlue,
            size: 18,
          ),
        ],
      ),
    );
  }
}

// ─── "+ Log activity" pill (opens /record) ─────────────────────────────
class _LogActivityButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogActivityButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandBlue,
      borderRadius: BorderRadius.circular(AppRadius.cards),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cards),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                color: AppColors.paperWhite,
                size: 20,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Log',
                style: TextStyle(
                  color: AppColors.paperWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HR trend chart (red filled area with corner stat pair) ──────────
class _HrTrendChart extends StatelessWidget {
  const _HrTrendChart();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        final trend = state.hrTrend;
        final hasData = !trend.isEmpty;
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.paperWhite,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppRadius.cards),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TrendHeader(trend: trend),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 180,
                child: hasData
                    ? _buildChart(trend)
                    : _emptyState(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 36,
            color: AppColors.pewter.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('No HR data yet', style: AppTypography.bodySm),
          const SizedBox(height: 2),
          Text(
            'Connect a device to start tracking',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  /// Build the dense red filled area chart. Samples are normalised onto
  /// a 0..N X axis (we don't care about clock time on this view — only
  /// the shape of the day's HR envelope).
  Widget _buildChart(HrTrend trend) {
    final samples = trend.samples;
    final maxBpm = samples.map((s) => s.bpm).reduce((a, b) => a > b ? a : b);
    final peakIndex = samples.indexWhere((s) => s.bpm == maxBpm);
    final spots = <FlSpot>[
      for (int i = 0; i < samples.length; i++)
        FlSpot(i.toDouble(), samples[i].bpm.toDouble()),
    ];

    return LineChart(
      LineChartData(
        minY: 40,
        maxY: 200,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.bone,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 50,
              getTitlesWidget: (value, meta) {
                // Hide the implicit top/bottom frame labels.
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    value.toInt().toString(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.silverLabel,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          verticalLines: [
            VerticalLine(
              x: peakIndex.toDouble(),
              color: AppColors.inkBlack.withValues(alpha: 0.35),
              strokeWidth: 1,
              dashArray: const [3, 3],
            ),
          ],
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.hrChartFill,
            barWidth: 1.6,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.hrChartFill.withValues(alpha: 0.55),
                  AppColors.hrChartFill.withValues(alpha: 0.05),
                ],
              ),
              cutOffY: 0,
              applyCutOffY: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HR trend header (bpm + distance, mirrors the reference top row) ──
class _TrendHeader extends StatelessWidget {
  final HrTrend trend;
  const _TrendHeader({required this.trend});

  @override
  Widget build(BuildContext context) {
    final samples = trend.samples;
    final currentBpm =
        samples.isEmpty ? 0 : samples.last.bpm;
    final distance = trend.distanceKm;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$currentBpm',
          style: AppTypography.statValue.copyWith(fontSize: 26),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'bpm',
            style: AppTypography.statUnit.copyWith(color: AppColors.graphite),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            width: 1,
            height: 18,
            color: AppColors.hairline,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          distance.toStringAsFixed(1),
          style: AppTypography.statValue.copyWith(fontSize: 26),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'km',
            style: AppTypography.statUnit.copyWith(color: AppColors.graphite),
          ),
        ),
      ],
    );
  }
}

// ─── Activity summary (uses existing ActivityBloc totals) ──────────────
class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.paperWhite,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppRadius.cards),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                label: 'This Week',
                value: '${state.activities.length}',
                unit: 'activities',
              ),
              _StatColumn(
                label: 'Duration',
                value: '${state.todayDuration}',
                unit: 'min',
              ),
              _StatColumn(
                label: 'Calories',
                value: '${state.todayCalories}',
                unit: 'kcal',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.statLabel),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.statValue),
        const SizedBox(height: 2),
        Text(unit, style: AppTypography.statUnit),
      ],
    );
  }
}

// ─── Recent HR card ────────────────────────────────────────────────────
class _RecentHrCard extends StatelessWidget {
  const _RecentHrCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.cards),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.favorite_outline,
              size: 28,
              color: AppColors.pewter.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('No recent readings', style: AppTypography.bodySm),
          ],
        ),
      ),
    );
  }
}

// ─── 7-day HR trend graph (avg line + min/max band) ───────────────────
class _WeeklyHrChart extends StatelessWidget {
  const _WeeklyHrChart();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        final weekly = state.weeklyHrData;
        final hasData = weekly.dailyAvg.any((v) => v > 0);
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.paperWhite,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppRadius.cards),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeeklyHeader(weekly: weekly),
              const SizedBox(height: AppSpacing.sm),
              _WeeklyLegend(),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 180,
                child: hasData ? _buildChart(weekly) : _emptyState(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 36,
            color: AppColors.pewter.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('No weekly data yet', style: AppTypography.bodySm),
          const SizedBox(height: 2),
          Text(
            'Track a few sessions to see your trend',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  /// Avg line on top of a translucent min/max band, with day labels
  /// on the X axis and a fixed 40..200 bpm Y range so the curve is
  /// visually stable as new days roll in.
  Widget _buildChart(WeeklyHrData weekly) {
    final avg = weekly.dailyAvg;
    final min = weekly.dailyMin;
    final max = weekly.dailyMax;
    final labels = weekly.dayLabels;
    final n = avg.length;

    // Compute Y bounds from the actual data so the curve fills the
    // chart, but clamp to a sensible HR envelope.
    final nonZero = [for (final v in [...min, ...max, ...avg]) v].where((v) => v > 0);
    int yMin = 40;
    int yMax = 200;
    if (nonZero.isNotEmpty) {
      final lo = nonZero.reduce((a, b) => a < b ? a : b);
      final hi = nonZero.reduce((a, b) => a > b ? a : b);
      yMin = (lo - 10).clamp(30, 180);
      yMax = (hi + 10).clamp(yMin + 20, 220);
    }
    final yInterval = ((yMax - yMin) / 4).ceilToDouble();

    final avgSpots = <FlSpot>[
      for (int i = 0; i < n; i++)
        if (avg[i] > 0) FlSpot(i.toDouble(), avg[i].toDouble()),
    ];
    final minSpots = <FlSpot>[
      for (int i = 0; i < n; i++)
        if (min[i] > 0) FlSpot(i.toDouble(), min[i].toDouble()),
    ];
    final maxSpots = <FlSpot>[
      for (int i = 0; i < n; i++)
        if (max[i] > 0) FlSpot(i.toDouble(), max[i].toDouble()),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (n - 1).toDouble(),
        minY: yMin.toDouble(),
        maxY: yMax.toDouble(),
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.bone,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    value.toInt().toString(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.silverLabel,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= n) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: AppTypography.caption.copyWith(
                      color: AppColors.silverLabel,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          // min/max band rendered as a low-opacity filled area between
          // the max and min lines.
          LineChartBarData(
            spots: maxSpots,
            color: AppColors.brandBlue.withValues(alpha: 0.12),
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.brandBlue.withValues(alpha: 0.12),
              cutOffY: 0,
              applyCutOffY: false,
              spotsLine: BarAreaSpotsLine(show: false),
            ),
          ),
          LineChartBarData(
            spots: minSpots,
            color: Colors.transparent,
            barWidth: 0,
            dotData: const FlDotData(show: false),
          ),
          // Avg line on top.
          LineChartBarData(
            spots: avgSpots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: AppColors.brandBlue,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.brandBlue,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.brandBlue.withValues(alpha: 0.18),
                  AppColors.brandBlue.withValues(alpha: 0.0),
                ],
              ),
              cutOffY: 0,
              applyCutOffY: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Weekly HR header (avg / min / max) ────────────────────────────────
class _WeeklyHeader extends StatelessWidget {
  final WeeklyHrData weekly;
  const _WeeklyHeader({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final avgValues = weekly.dailyAvg.where((v) => v > 0).toList();
    final maxValues = weekly.dailyMax.where((v) => v > 0).toList();
    final minValues = weekly.dailyMin.where((v) => v > 0).toList();
    final avg = avgValues.isEmpty
        ? 0
        : (avgValues.reduce((a, b) => a + b) / avgValues.length).round();
    final max = maxValues.isEmpty ? 0 : maxValues.reduce((a, b) => a > b ? a : b);
    final min = minValues.isEmpty ? 0 : minValues.reduce((a, b) => a < b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$avg', style: AppTypography.statValue.copyWith(fontSize: 26)),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'bpm avg',
            style: AppTypography.statUnit.copyWith(color: AppColors.graphite),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            width: 1,
            height: 18,
            color: AppColors.hairline,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '$min–$max',
            style: AppTypography.statValue.copyWith(fontSize: 22),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'bpm range',
            style: AppTypography.statUnit.copyWith(color: AppColors.graphite),
          ),
        ),
      ],
    );
  }
}

// ─── Weekly chart legend (avg / min-max) ───────────────────────────────
class _WeeklyLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendDot(color: AppColors.brandBlue, label: 'Avg'),
        SizedBox(width: AppSpacing.md),
        _LegendDot(
          color: AppColors.brandBlue,
          label: 'Min–Max',
          soft: true,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool soft;
  const _LegendDot({
    required this.color,
    required this.label,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: soft ? color.withValues(alpha: 0.18) : color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

