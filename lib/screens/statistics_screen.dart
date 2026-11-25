import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gluco_provider.dart';
import '../services/statistics_service.dart';
import '../utils/app_theme.dart';
import '../utils/glucose_converter.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/medical_disclaimer_banner.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsPeriod _period = StatsPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    final profile = provider.profile;
    final filtered = StatisticsService.filterByPeriod(
      provider.records,
      _period,
    );
    final stats = StatisticsService.calculate(
      records: filtered,
      profile: profile,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráficas y estadísticas'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Selector de período (diario, semanal, mensual, todo)
          SegmentedButton<StatsPeriod>(
            segments: StatsPeriod.values
                .map(
                  (p) => ButtonSegment<StatsPeriod>(
                    value: p,
                    label: Text(
                      p.label,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
            selected: {_period},
            onSelectionChanged: (sel) {
              if (sel.isNotEmpty) {
                setState(() => _period = sel.first);
              }
            },
          ),
          const SizedBox(height: 16),

          // Gráfica fl_chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evolución (${_period.label})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _LegendDot(
                        color: AppColors.inRange,
                        label: 'En rango',
                      ),
                      _LegendDot(
                        color: AppColors.aboveRange,
                        label: 'Por encima',
                      ),
                      _LegendDot(
                        color: AppColors.belowRange,
                        label: 'Por debajo',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GlucoseChart(
                    records: filtered,
                    profile: profile,
                    height: 250,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tarjetas de resumen numérico
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Promedio',
                  value: stats.totalCount == 0
                      ? '--'
                      : GlucoseConverter.formatValue(stats.average, stats.unit),
                  subtitle: stats.unit,
                  accent: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Mediciones',
                  value: '${stats.totalCount}',
                  subtitle: _period.label,
                  accent: AppColors.secondaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Valor mínimo',
                  value: stats.totalCount == 0
                      ? '--'
                      : GlucoseConverter.formatValue(
                          stats.minValue,
                          stats.unit,
                        ),
                  subtitle: stats.unit,
                  accent: AppColors.mainText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Valor máximo',
                  value: stats.totalCount == 0
                      ? '--'
                      : GlucoseConverter.formatValue(
                          stats.maxValue,
                          stats.unit,
                        ),
                  subtitle: stats.unit,
                  accent: AppColors.mainText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Distribución por rangos personalizados
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribución respecto a su rango',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _RangeBarRow(
                    label: 'Dentro del rango',
                    count: stats.inRangeCount,
                    percent: stats.inRangePercent,
                    color: AppColors.inRange,
                  ),
                  const SizedBox(height: 10),
                  _RangeBarRow(
                    label: 'Por encima del rango',
                    count: stats.aboveRangeCount,
                    percent: stats.aboveRangePercent,
                    color: AppColors.aboveRange,
                  ),
                  const SizedBox(height: 10),
                  _RangeBarRow(
                    label: 'Por debajo del rango',
                    count: stats.belowRangeCount,
                    percent: stats.belowRangePercent,
                    color: AppColors.belowRange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tendencia descriptiva neutra (sin diagnóstico)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.insights_rounded,
                    color: AppColors.secondaryBlue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Observación de tendencia',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stats.neutralTrendDescription,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.mainText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const MedicalDisclaimerBanner(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeBarRow extends StatelessWidget {
  final String label;
  final int count;
  final double percent;
  final Color color;

  const _RangeBarRow({
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Text(
              '$count (${percent.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: AppColors.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
