import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/blood_pressure_record.dart';
import '../providers/gluco_provider.dart';
import '../utils/app_theme.dart';
import '../utils/glucose_converter.dart';
import '../widgets/medical_disclaimer_banner.dart';
import '../widgets/range_indicator_bar.dart';

class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  int _systolic = 118;
  int _diastolic = 76;
  int _pulse = 70;
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  BloodPressureRecord get _previewRecord => BloodPressureRecord(
        systolic: _systolic,
        diastolic: _diastolic,
        pulse: _pulse,
        measuredAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await context.read<GlucoProvider>().addBloodPressure(
            BloodPressureRecord(
              systolic: _systolic,
              diastolic: _diastolic,
              pulse: _pulse,
              measuredAt: now,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              createdAt: now,
            ),
          );
      _notesController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro de presión arterial guardado.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(BloodPressureRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Desea eliminar la medición ${record.systolic}/${record.diastolic} mmHg?',
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
      await context.read<GlucoProvider>().deleteBloodPressure(record.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    final records = provider.bloodPressureRecords;
    final preview = _previewRecord;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presión arterial y pulso'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Tarjeta de registro con botones grandes +/-
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nueva medición',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberStepperCard(
                          label: 'Sistólica',
                          unit: 'mmHg',
                          value: _systolic,
                          accent: AppColors.primaryGreen,
                          onDecrement: () => setState(
                            () => _systolic = (_systolic - 1).clamp(60, 240),
                          ),
                          onIncrement: () => setState(
                            () => _systolic = (_systolic + 1).clamp(60, 240),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _NumberStepperCard(
                          label: 'Diastólica',
                          unit: 'mmHg',
                          value: _diastolic,
                          accent: AppColors.secondaryBlue,
                          onDecrement: () => setState(
                            () => _diastolic = (_diastolic - 1).clamp(40, 150),
                          ),
                          onIncrement: () => setState(
                            () => _diastolic = (_diastolic + 1).clamp(40, 150),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _NumberStepperCard(
                          label: 'Pulso',
                          unit: 'BPM',
                          value: _pulse,
                          accent: const Color(0xFFD97706),
                          onDecrement: () => setState(
                            () => _pulse = (_pulse - 1).clamp(35, 200),
                          ),
                          onIncrement: () => setState(
                            () => _pulse = (_pulse + 1).clamp(35, 200),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  RangeIndicatorBar(
                    segmentColors: const [
                      AppColors.secondaryBlue,
                      AppColors.primaryGreen,
                      AppColors.aboveRange,
                      AppColors.belowRange,
                    ],
                    segmentLabels: const [
                      'Baja',
                      'Referencia',
                      'Elevada',
                      'Alta',
                    ],
                    activeIndex: preview.visualSegmentIndex,
                    title: preview.category.label,
                    subtitle:
                        'Referencia general orientativa: <120 / <80 mmHg (consulte siempre a su médico)',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones (opcional)',
                      hintText: 'Ej. En reposo, brazo izquierdo...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(
                      _saving ? 'Guardando...' : 'GUARDAR PRESIÓN ARTERIAL',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Gráfica reciente
          if (records.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tendencia reciente (mmHg)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BloodPressureBarChart(records: records.take(7).toList()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Historial
          const Text(
            'Historial de presión arterial',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (records.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Aún no hay registros de presión arterial.',
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
                      backgroundColor: AppColors.lightGreen,
                      child: const Icon(
                        Icons.favorite_outline_rounded,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    title: Text(
                      '${r.systolic}/${r.diastolic} mmHg  •  ${r.pulse} BPM',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${r.category.label}\n${GlucoseConverter.formatDateTime(r.measuredAt)}${r.notes != null ? '\n${r.notes}' : ''}',
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
    );
  }
}

class _NumberStepperCard extends StatelessWidget {
  final String label;
  final String unit;
  final int value;
  final Color accent;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _NumberStepperCard({
    required this.label,
    required this.unit,
    required this.value,
    required this.accent,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onIncrement,
            icon: Icon(Icons.add_circle_outline_rounded, color: accent),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: accent,
              height: 1.0,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDecrement,
            icon: Icon(Icons.remove_circle_outline_rounded, color: accent),
          ),
        ],
      ),
    );
  }
}

class _BloodPressureBarChart extends StatelessWidget {
  final List<BloodPressureRecord> records;

  const _BloodPressureBarChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final ordered = records.reversed.toList();
    final dateFmt = DateFormat('dd/MM');

    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          minY: 40,
          maxY: 190,
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
                reservedSize: 36,
                interval: 30,
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
            final barColor = r.category == BloodPressureCategory.normal
                ? AppColors.primaryGreen
                : (r.category == BloodPressureCategory.elevated
                    ? AppColors.aboveRange
                    : (r.category == BloodPressureCategory.low
                        ? AppColors.secondaryBlue
                        : AppColors.belowRange));
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  fromY: r.diastolic.toDouble(),
                  toY: r.systolic.toDouble(),
                  width: 18,
                  color: barColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
