import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/weight_record.dart';
import '../providers/gluco_provider.dart';
import '../utils/app_theme.dart';
import '../utils/glucose_converter.dart';
import '../widgets/medical_disclaimer_banner.dart';
import '../widgets/range_indicator_bar.dart';

class WeightBmiScreen extends StatefulWidget {
  const WeightBmiScreen({super.key});

  @override
  State<WeightBmiScreen> createState() => _WeightBmiScreenState();
}

class _WeightBmiScreenState extends State<WeightBmiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController(text: '70.0');
  final _heightController = TextEditingController(text: '165');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GlucoProvider>();
    _heightController.text = provider.lastHeightCm.toStringAsFixed(0);
    if (provider.latestWeight != null) {
      _weightController.text =
          provider.latestWeight!.weightKg.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  WeightRecord? get _livePreview {
    final w = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final h = double.tryParse(_heightController.text.replaceAll(',', '.'));
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return WeightRecord(
      weightKg: w,
      heightCm: h,
      measuredAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final w = double.parse(_weightController.text.trim().replaceAll(',', '.'));
    final h = double.parse(_heightController.text.trim().replaceAll(',', '.'));

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await context.read<GlucoProvider>().addWeight(
            WeightRecord(
              weightKg: w,
              heightCm: h,
              measuredAt: now,
              createdAt: now,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro de peso e IMC guardado.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(WeightRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Desea eliminar el registro de ${record.weightKg.toStringAsFixed(1)} kg (IMC ${record.bmi.toStringAsFixed(1)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.belowRange,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && record.id != null && mounted) {
      await context.read<GlucoProvider>().deleteWeight(record.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    final records = provider.weightRecords;
    final preview = _livePreview;

    double avgBmi = 0;
    double minBmi = 0;
    double maxBmi = 0;
    if (records.isNotEmpty) {
      final bmis = records.map((r) => r.bmi).toList();
      avgBmi = bmis.reduce((a, b) => a + b) / bmis.length;
      minBmi = bmis.reduce(math.min);
      maxBmi = bmis.reduce(math.max);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peso e IMC'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrar peso y estatura',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                            ),
                            validator: (v) {
                              final n = double.tryParse(
                                (v ?? '').replaceAll(',', '.'),
                              );
                              if (n == null || n < 20 || n > 350) {
                                return '20 - 350 kg';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Estatura (cm)',
                            ),
                            validator: (v) {
                              final n = double.tryParse(
                                (v ?? '').replaceAll(',', '.'),
                              );
                              if (n == null || n < 80 || n > 240) {
                                return '80 - 240 cm';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 16),
                      RangeIndicatorBar(
                        segmentColors: const [
                          AppColors.secondaryBlue,
                          AppColors.primaryGreen,
                          AppColors.aboveRange,
                          AppColors.belowRange,
                        ],
                        segmentLabels: const [
                          '<18.5',
                          '18.5-24.9',
                          '25-29.9',
                          '≥30',
                        ],
                        activeIndex: preview.visualSegmentIndex,
                        title:
                            'IMC calculado: ${preview.bmi.toStringAsFixed(1)}',
                        subtitle: preview.category.label,
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        _saving ? 'Guardando...' : 'GUARDAR PESO E IMC',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (records.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen de IMC',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniMetric('Máx', maxBmi.toStringAsFixed(1)),
                          _MiniMetric('Mín', minBmi.toStringAsFixed(1)),
                          _MiniMetric('Promedio', avgBmi.toStringAsFixed(1)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _BmiChart(records: records.take(7).toList()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Historial de peso',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (records.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Aún no hay registros de peso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              )
            else
              ...records.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEAF3FC),
                        child: const Icon(
                          Icons.monitor_weight_outlined,
                          color: AppColors.secondaryBlue,
                        ),
                      ),
                      title: Text(
                        '${r.weightKg.toStringAsFixed(1)} kg  •  IMC ${r.bmi.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${r.category.label}\n${GlucoseConverter.formatDateTime(r.measuredAt)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.belowRange,
                        ),
                        onPressed: () => _confirmDelete(r),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const MedicalDisclaimerBanner(compact: true),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.mainText,
          ),
        ),
      ],
    );
  }
}

class _BmiChart extends StatelessWidget {
  final List<WeightRecord> records;

  const _BmiChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final ordered = records.reversed.toList();
    final dateFmt = DateFormat('dd/MM');
    final bmis = ordered.map((e) => e.bmi).toList();
    final maxY = math.max(35.0, (bmis.reduce(math.max) + 5).ceilToDouble());

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
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
                reservedSize: 32,
                interval: 10,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= ordered.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      dateFmt.format(ordered[idx].measuredAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(ordered.length, (i) {
            final r = ordered[i];
            final barColor = r.category == BmiCategory.normal
                ? AppColors.primaryGreen
                : (r.category == BmiCategory.underweight
                    ? AppColors.secondaryBlue
                    : (r.category == BmiCategory.overweight
                        ? AppColors.aboveRange
                        : AppColors.belowRange));
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: r.bmi,
                  width: 18,
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
