import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/wahoo_header.dart';
import '../../../activities/presentation/bloc/activity_bloc.dart';
import '../../../activities/presentation/bloc/activity_state.dart';
import '../bloc/heart_rate_bloc.dart';
import '../bloc/heart_rate_state.dart';

/// PulseX home screen — directly inspired by the reference
/// screenshot: ALL-CAPS title, Avg/Max/Calories trio, a red-filled live
/// HR chart, then a Heart-Rate Zones list with bar fill + time.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      appBar: WahooHeader(
        title: 'PulseX',
        showBack: false,
        leading: const PulseXHeaderMark(size: 32),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.brandBlue),
            tooltip: 'Filters',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, color: AppColors.brandBlue),
            tooltip: 'Share',
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<HeartRateBloc, HeartRateState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    icon: Icons.favorite,
                    label: 'Heart Rate',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TodaySummaryRow(
                    avgHr: state.todayStats.avgHr,
                    maxHr: state.todayStats.maxHr,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LiveHrChartCard(
                    bpm: state.currentBpm,
                    isConnected: state.isConnected,
                    deviceName: state.connectedDevice?.name,
                    batteryPercent: state.telemetry.batteryPercent,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionLabel(
                    icon: Icons.bar_chart,
                    label: 'Heart Rate Zones',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ZoneLegend(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Section label (small caps + icon) ─────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.inkBlack),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: AppTypography.sectionHeader.copyWith(
            color: AppColors.inkBlack,
          ),
        ),
      ],
    );
  }
}

// ─── Avg / Max / Calories trio ─────────────────────────────────────────
class _TodaySummaryRow extends StatelessWidget {
  final int avgHr;
  final int maxHr;

  const _TodaySummaryRow({required this.avgHr, required this.maxHr});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, activityState) {
        final calories = activityState.todayCalories;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _SummaryStat(
                label: 'Average',
                value: avgHr > 0 ? '$avgHr' : '--',
                unit: 'bpm',
              ),
            ),
            Expanded(
              child: _SummaryStat(
                label: 'Max',
                value: maxHr > 0 ? '$maxHr' : '--',
                unit: 'bpm',
              ),
            ),
            Expanded(
              child: _SummaryStat(
                label: 'Calories',
                value: '$calories',
                unit: 'info',
                trailingIcon: Icons.info_outline,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData? trailingIcon;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.unit,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.statLabel),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: AppTypography.statValue),
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: AppTypography.statUnit.copyWith(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, size: 11, color: AppColors.brandBlue),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Live HR chart card (red fill) ─────────────────────────────────────
class _LiveHrChartCard extends StatelessWidget {
  final int? bpm;
  final bool isConnected;
  final String? deviceName;
  final int? batteryPercent;

  const _LiveHrChartCard({
    this.bpm,
    required this.isConnected,
    this.deviceName,
    this.batteryPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.cards),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current reading + pills.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bpm != null ? '$bpm' : '--',
                style: AppTypography.displaySm.copyWith(
                  color: AppColors.inkBlack,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'bpm',
                  style: AppTypography.statUnit.copyWith(
                    color: AppColors.silverLabel,
                  ),
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  _Pill(
                    label: isConnected
                        ? (deviceName ?? 'Connected')
                        : 'Not Connected',
                    leadingDotColor: isConnected
                        ? AppColors.successGreen
                        : AppColors.pewter,
                  ),
                  if (batteryPercent != null)
                    _Pill(
                      label: '$batteryPercent%',
                      icon: Icons.battery_full,
                      tintColor: AppColors.brandBlueTint,
                      foregroundColor: AppColors.brandBlueDark,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Red filled HR chart (sample waveform — same look as Wahoo).
          SizedBox(
            height: 160,
            child: bpm != null
                ? _HrAreaChart(currentBpm: bpm!)
                : _EmptyChart(),
          ),
        ],
      ),
    );
  }
}

class _HrAreaChart extends StatelessWidget {
  final int currentBpm;
  const _HrAreaChart({required this.currentBpm});

  @override
  Widget build(BuildContext context) {
    // Stable pseudo-waveform based on the live reading so the chart
    // shape feels alive without requiring a real time-series DB read.
    final base = currentBpm.toDouble();
    final spots = <FlSpot>[
      const FlSpot(0, 110),
      FlSpot(1, 120),
      FlSpot(2, 135),
      FlSpot(3, 128),
      FlSpot(4, 142),
      FlSpot(5, 155),
      FlSpot(6, 148),
      FlSpot(7, 162),
      FlSpot(8, 170),
      FlSpot(9, 158),
      FlSpot(10, 165),
      FlSpot(11, 172),
      FlSpot(12, base.clamp(80, 200)),
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 60,
        maxY: 200,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.hrChartFill,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.hrChartFillSoft,
                  AppColors.hrChartFillSoft.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 28,
            color: AppColors.pewter.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No live reading',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 2),
          Text(
            'Connect a device to start tracking',
            style: AppTypography.caption.copyWith(
              color: AppColors.silverLabel,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status / battery pill chips ───────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color? leadingDotColor;
  final IconData? icon;
  final Color? tintColor;
  final Color? foregroundColor;

  const _Pill({
    required this.label,
    this.leadingDotColor,
    this.icon,
    this.tintColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? AppColors.charcoal;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tintColor ?? AppColors.pillGrey,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: leadingDotColor,
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Heart-rate zone legend (Peak / Cardio / Fat burn) ─────────────────
class _ZoneLegend extends StatelessWidget {
  const _ZoneLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.cards),
      ),
      child: Column(
        children: const [
          _ZoneRow(
            zone: 'Peak',
            range: '180+',
            color: AppColors.zonePeak,
            percent: 0.01,
            timeLabel: '0:10',
          ),
          _ZoneDivider(),
          _ZoneRow(
            zone: 'Hard',
            range: '170–179',
            color: AppColors.zoneCardio,
            percent: 0.01,
            timeLabel: '0:10',
          ),
          _ZoneDivider(),
          _ZoneRow(
            zone: 'Cardio',
            range: '150–169',
            color: Color(0xFFFFA552),
            percent: 0.56,
            timeLabel: '22:30',
            highlight: true,
          ),
          _ZoneDivider(),
          _ZoneRow(
            zone: 'Fat burn',
            range: '120–149',
            color: AppColors.zoneFatBurn,
            percent: 0.20,
            timeLabel: '7:57',
          ),
        ],
      ),
    );
  }
}

class _ZoneDivider extends StatelessWidget {
  const _ZoneDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.hairline,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final String zone;
  final String range;
  final Color color;
  final double percent; // 0..1 fill of the bar
  final String timeLabel;
  final bool highlight;

  const _ZoneRow({
    required this.zone,
    required this.range,
    required this.color,
    required this.percent,
    required this.timeLabel,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  range,
                  style: AppTypography.statUnit.copyWith(
                    color: AppColors.silverLabel,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _ZoneBar(
              color: color,
              percent: percent,
              highlight: highlight,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 44,
            child: Text(
              timeLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneBar extends StatelessWidget {
  final Color color;
  final double percent;
  final bool highlight;

  const _ZoneBar({
    required this.color,
    required this.percent,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);
    final fillColor = highlight ? color : color;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              width: constraints.maxWidth * clamped,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );
      },
    );
  }
}