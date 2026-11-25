import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/glucose_record.dart';
import '../models/patient_profile.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/glucose_converter.dart';

class GlucoseChart extends StatelessWidget {
  final List<GlucoseRecord> records;
  final PatientProfile? profile;
  final double height;

  const GlucoseChart({
    super.key,
    required this.records,
    required this.profile,
    this.height = 240,
  });

  Color _colorForStatus(GlucoseRangeStatus status) {
    switch (status) {
      case GlucoseRangeStatus.inRange:
        return AppColors.inRange;
      case GlucoseRangeStatus.aboveRange:
        return AppColors.aboveRange;
      case GlucoseRangeStatus.belowRange:
        return AppColors.belowRange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = profile?.preferredUnit ?? AppConstants.unitMgDl;
    if (records.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.show_chart_rounded,
                size: 46,
                color: AppColors.secondaryText,
              ),
              SizedBox(height: 10),
              Text(
                'Sin mediciones en este período',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List<GlucoseRecord>.from(records)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].valueIn(unit)));
    }

    final minTarget = profile?.targetMinIn(unit) ??
        (unit == AppConstants.unitMgDl
            ? AppConstants.defaultMinMgDl
            : AppConstants.defaultMinMmolL);
    final maxTarget = profile?.targetMaxIn(unit) ??
        (unit == AppConstants.unitMgDl
            ? AppConstants.defaultMaxMgDl
            : AppConstants.defaultMaxMmolL);

    final values = spots.map((s) => s.y).toList();
    final minVal = math.min(values.reduce(math.min), minTarget);
    final maxVal = math.max(values.reduce(math.max), maxTarget);
    final pad = unit == AppConstants.unitMgDl ? 18.0 : 1.2;
    final chartMinY = math.max(0.0, (minVal - pad).floorToDouble());
    final chartMaxY = (maxVal + pad).ceilToDouble();

    final dateFmt = DateFormat('dd/MM');
    final timeFmt = DateFormat('HH:mm');
    final sameDay = sorted.first.measuredAt.year == sorted.last.measuredAt.year &&
        sorted.first.measuredAt.month == sorted.last.measuredAt.month &&
        sorted.first.measuredAt.day == sorted.last.measuredAt.day;

    final labelStep = math.max(1, (sorted.length / 4).ceil());

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 16, left: 4, bottom: 4),
        child: LineChart(
          LineChartData(
            minY: chartMinY,
            maxY: chartMaxY,
            minX: 0,
            maxX: math.max(0, sorted.length - 1).toDouble(),
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.borderGray,
                strokeWidth: 0.8,
              ),
            ),
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                HorizontalRangeAnnotation(
                  y1: minTarget,
                  y2: maxTarget,
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                ),
              ],
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: minTarget,
                  color: AppColors.primaryGreen.withValues(alpha: 0.6),
                  strokeWidth: 1.2,
                  dashArray: [6, 4],
                ),
                HorizontalLine(
                  y: maxTarget,
                  color: AppColors.primaryGreen.withValues(alpha: 0.6),
                  strokeWidth: 1.2,
                  dashArray: [6, 4],
                ),
              ],
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max || value == meta.min) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      GlucoseConverter.formatValue(value, unit),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= sorted.length) {
                      return const SizedBox.shrink();
                    }
                    if (idx != 0 &&
                        idx != sorted.length - 1 &&
                        idx % labelStep != 0) {
                      return const SizedBox.shrink();
                    }
                    final dt = sorted[idx].measuredAt;
                    final text = sameDay ? timeFmt.format(dt) : dateFmt.format(dt);
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: AppColors.borderGray),
                bottom: BorderSide(color: AppColors.borderGray),
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.mainText,
                tooltipRoundedRadius: 10,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final idx = spot.x.toInt();
                    if (idx < 0 || idx >= sorted.length) return null;
                    final rec = sorted[idx];
                    final valStr = GlucoseConverter.formatValue(spot.y, unit);
                    return LineTooltipItem(
                      '$valStr $unit\n${rec.measurementType.label}\n${GlucoseConverter.formatDateTime(rec.measuredAt)}',
                      const TextStyle(
                        color: AppColors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: spots.length > 2,
                curveSmoothness: 0.22,
                color: AppColors.secondaryBlue,
                barWidth: 3.2,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.secondaryBlue.withValues(alpha: 0.08),
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final status = sorted[index].evaluateAgainst(profile);
                    return FlDotCirclePainter(
                      radius: 5.5,
                      color: _colorForStatus(status),
                      strokeWidth: 2,
                      strokeColor: AppColors.white,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
