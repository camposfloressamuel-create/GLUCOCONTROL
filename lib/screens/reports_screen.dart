import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/glucose_record.dart';
import '../providers/gluco_provider.dart';
import '../reports/pdf_report_service.dart';
import '../services/statistics_service.dart';
import '../utils/app_theme.dart';
import '../utils/glucose_converter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day);
    _startDate = _endDate.subtract(const Duration(days: 29));
  }

  void _setPresetDays(int days) {
    final now = DateTime.now();
    setState(() {
      _endDate = DateTime(now.year, now.month, now.day);
      _startDate = _endDate.subtract(Duration(days: days - 1));
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<Uint8List> _buildBytes() async {
    final provider = context.read<GlucoProvider>();
    final records = await provider.queryRecords(
      startDate: _startDate,
      endDate: _endDate,
    );
    return PdfReportService.buildReportBytes(
      profile: provider.profile,
      records: records,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _runAction(Future<void> Function(Uint8List bytes) action) async {
    setState(() => _generating = true);
    try {
      final bytes = await _buildBytes();
      await action(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el informe PDF: $e'),
          backgroundColor: AppColors.belowRange,
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  List<GlucoseRecord> _filteredPreview(List<GlucoseRecord> all) {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      23,
      59,
      59,
      999,
    );
    return all
        .where((r) => !r.measuredAt.isBefore(start) && !r.measuredAt.isAfter(end))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    final previewRecords = _filteredPreview(provider.records);
    final stats = StatisticsService.calculate(
      records: previewRecords,
      profile: provider.profile,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes PDF'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Seleccione el período del informe',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Últimos 7 días'),
                onPressed: () => _setPresetDays(7),
              ),
              ActionChip(
                label: const Text('Últimos 30 días'),
                onPressed: () => _setPresetDays(30),
              ),
              ActionChip(
                label: const Text('Últimos 90 días'),
                onPressed: () => _setPresetDays(90),
              ),
              ActionChip(
                avatar: const Icon(Icons.date_range_rounded, size: 18),
                label: const Text('Elegir fechas'),
                onPressed: _pickCustomRange,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.secondaryBlue,
                        size: 32,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Resumen del informe a generar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoLine(
                    label: 'Paciente',
                    value: provider.profile?.fullName ?? 'Sin configurar',
                  ),
                  _InfoLine(
                    label: 'Período',
                    value:
                        '${GlucoseConverter.formatDate(_startDate)} al ${GlucoseConverter.formatDate(_endDate)}',
                  ),
                  _InfoLine(
                    label: 'Total de mediciones',
                    value: '${stats.totalCount}',
                  ),
                  _InfoLine(
                    label: 'Promedio calculado',
                    value: stats.totalCount == 0
                        ? '--'
                        : '${GlucoseConverter.formatValue(stats.average, stats.unit)} ${stats.unit}',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'El archivo PDF incluirá logotipo, datos del paciente, resumen estadístico, gráfica de evolución y tabla completa con fechas, horas y observaciones.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _generating
                ? null
                : () => _runAction((bytes) async {
                      await PdfReportService.sharePdf(bytes);
                    }),
            icon: _generating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.share_rounded, size: 24),
            label: const Text('Compartir informe PDF'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _generating
                ? null
                : () => _runAction((bytes) async {
                      final file = await PdfReportService.savePdfLocally(bytes);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Informe guardado localmente: ${file.path.split('/').last}',
                          ),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    }),
            icon: const Icon(Icons.download_rounded, size: 24),
            label: const Text('Guardar PDF en el dispositivo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _generating
                ? null
                : () => _runAction((bytes) async {
                      await PdfReportService.printPdf(bytes);
                    }),
            icon: const Icon(Icons.print_rounded, size: 24),
            label: const Text('Imprimir informe'),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.secondaryText,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.mainText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
