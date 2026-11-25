import '../models/glucose_record.dart';
import '../models/patient_profile.dart';
import '../utils/constants.dart';

enum StatsPeriod {
  daily('Hoy'),
  weekly('7 días'),
  monthly('30 días'),
  all('Todo');

  final String label;
  const StatsPeriod(this.label);
}

class GlucoseStatistics {
  final int totalCount;
  final double average;
  final double minValue;
  final double maxValue;
  final int inRangeCount;
  final int aboveRangeCount;
  final int belowRangeCount;
  final String unit;
  final String neutralTrendDescription;

  const GlucoseStatistics({
    required this.totalCount,
    required this.average,
    required this.minValue,
    required this.maxValue,
    required this.inRangeCount,
    required this.aboveRangeCount,
    required this.belowRangeCount,
    required this.unit,
    required this.neutralTrendDescription,
  });

  double get inRangePercent =>
      totalCount == 0 ? 0 : (inRangeCount / totalCount) * 100;
  double get aboveRangePercent =>
      totalCount == 0 ? 0 : (aboveRangeCount / totalCount) * 100;
  double get belowRangePercent =>
      totalCount == 0 ? 0 : (belowRangeCount / totalCount) * 100;

  static GlucoseStatistics empty(String unit) {
    return GlucoseStatistics(
      totalCount: 0,
      average: 0,
      minValue: 0,
      maxValue: 0,
      inRangeCount: 0,
      aboveRangeCount: 0,
      belowRangeCount: 0,
      unit: unit,
      neutralTrendDescription:
          'Aún no hay suficientes registros en este período para calcular una tendencia.',
    );
  }
}

class StatisticsService {
  /// Filtra registros según el período seleccionado tomando como referencia [referenceDate].
  static List<GlucoseRecord> filterByPeriod(
    List<GlucoseRecord> allRecords,
    StatsPeriod period, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (period) {
      case StatsPeriod.daily:
        return allRecords
            .where((r) => !r.measuredAt.isBefore(todayStart))
            .toList();
      case StatsPeriod.weekly:
        final weekStart = todayStart.subtract(const Duration(days: 6));
        return allRecords
            .where((r) => !r.measuredAt.isBefore(weekStart))
            .toList();
      case StatsPeriod.monthly:
        final monthStart = todayStart.subtract(const Duration(days: 29));
        return allRecords
            .where((r) => !r.measuredAt.isBefore(monthStart))
            .toList();
      case StatsPeriod.all:
        return List<GlucoseRecord>.from(allRecords);
    }
  }

  /// Calcula estadísticas puramente descriptivas (sin diagnósticos ni recomendaciones médicas).
  static GlucoseStatistics calculate({
    required List<GlucoseRecord> records,
    required PatientProfile? profile,
  }) {
    final unit = profile?.preferredUnit ?? AppConstants.unitMgDl;
    if (records.isEmpty) {
      return GlucoseStatistics.empty(unit);
    }

    final sortedChronological = List<GlucoseRecord>.from(records)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    double sum = 0;
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    int inRange = 0;
    int aboveRange = 0;
    int belowRange = 0;

    for (final rec in sortedChronological) {
      final v = rec.valueIn(unit);
      sum += v;
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;

      switch (rec.evaluateAgainst(profile)) {
        case GlucoseRangeStatus.inRange:
          inRange++;
          break;
        case GlucoseRangeStatus.aboveRange:
          aboveRange++;
          break;
        case GlucoseRangeStatus.belowRange:
          belowRange++;
          break;
      }
    }

    final avg = sum / sortedChronological.length;
    final trend = _describeNeutralTrend(sortedChronological, unit);

    return GlucoseStatistics(
      totalCount: sortedChronological.length,
      average: avg,
      minValue: minVal,
      maxValue: maxVal,
      inRangeCount: inRange,
      aboveRangeCount: aboveRange,
      belowRangeCount: belowRange,
      unit: unit,
      neutralTrendDescription: trend,
    );
  }

  static String _describeNeutralTrend(
    List<GlucoseRecord> chronological,
    String unit,
  ) {
    if (chronological.length < 3) {
      return 'Se requieren al menos 3 mediciones en el período para observar la evolución de los datos.';
    }

    final mid = chronological.length ~/ 2;
    final firstHalf = chronological.sublist(0, mid);
    final secondHalf = chronological.sublist(mid);

    final firstAvg = firstHalf
            .map((r) => r.valueIn(unit))
            .reduce((a, b) => a + b) /
        firstHalf.length;
    final secondAvg = secondHalf
            .map((r) => r.valueIn(unit))
            .reduce((a, b) => a + b) /
        secondHalf.length;

    final diff = secondAvg - firstAvg;
    final threshold = unit == AppConstants.unitMgDl ? 8.0 : 0.45;

    if (diff > threshold) {
      return 'Los valores registrados en la segunda mitad del período fueron más altos en promedio que al inicio. Comparta este historial con su médico en su próxima consulta.';
    } else if (diff < -threshold) {
      return 'Los valores registrados en la segunda mitad del período fueron más bajos en promedio que al inicio. Comparta este historial con su médico en su próxima consulta.';
    } else {
      return 'Los valores registrados se mantuvieron relativamente estables a lo largo del período seleccionado.';
    }
  }
}
