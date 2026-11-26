import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/glucose_record.dart';
import '../models/patient_profile.dart';
import '../services/statistics_service.dart';
import '../utils/constants.dart';
import '../utils/glucose_converter.dart';

class PdfReportService {
  static final PdfColor _primaryGreen = PdfColor.fromHex('#16A36A');
  static final PdfColor _lightGreen = PdfColor.fromHex('#E8F7EF');
  static final PdfColor _secondaryBlue = PdfColor.fromHex('#2878C7');
  static final PdfColor _lightGray = PdfColor.fromHex('#F4F6F8');
  static final PdfColor _mainText = PdfColor.fromHex('#202A35');
  static final PdfColor _mutedText = PdfColor.fromHex('#5A6776');
  static final PdfColor _borderColor = PdfColor.fromHex('#DCE3EA');
  static final PdfColor _amber = PdfColor.fromHex('#D97706');
  static final PdfColor _red = PdfColor.fromHex('#DC2626');

  /// Genera los bytes del informe PDF usando datos reales de SQLite.
  static Future<Uint8List> buildReportBytes({
    required PatientProfile? profile,
    required List<GlucoseRecord> records,
    required DateTime startDate,
    required DateTime endDate,
    Uint8List? logoBytesOverride,
  }) async {
    final doc = pw.Document(
      title: 'Informe de Glucosa - ${profile?.fullName ?? "Paciente"}',
      author: AppConstants.appName,
    );

    Uint8List? logoBytes = logoBytesOverride;
    if (logoBytes == null) {
      try {
        final data = await rootBundle.load(
          'assets/images/glucocontrol_logo.png',
        );
        logoBytes = data.buffer.asUint8List();
      } catch (_) {
        logoBytes = null;
      }
    }

    final unit = profile?.preferredUnit ?? AppConstants.unitMgDl;
    final stats = StatisticsService.calculate(
      records: records,
      profile: profile,
    );

    final chronological = List<GlucoseRecord>.from(records)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final newestFirst = List<GlucoseRecord>.from(records)
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('hh:mm a');
    final periodLabel =
        '${dateFmt.format(startDate)} al ${dateFmt.format(endDate)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildHeader(
          logoBytes: logoBytes,
          periodLabel: periodLabel,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildPatientInfoCard(profile, periodLabel, unit),
          pw.SizedBox(height: 14),
          _buildSummaryRow(stats),
          pw.SizedBox(height: 14),
          if (chronological.isNotEmpty) ...[
            pw.Text(
              'Gráfica de evolución de glucosa ($unit)',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _mainText,
              ),
            ),
            pw.SizedBox(height: 6),
            _buildVectorChart(
              records: chronological,
              profile: profile,
              unit: unit,
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _lightGray,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Resumen descriptivo: ${stats.neutralTrendDescription}',
                style: pw.TextStyle(fontSize: 9.5, color: _mainText),
              ),
            ),
            pw.SizedBox(height: 16),
          ],
          pw.Text(
            'Historial detallado de mediciones (${newestFirst.length})',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _mainText,
            ),
          ),
          pw.SizedBox(height: 8),
          if (newestFirst.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _borderColor),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'No se encontraron mediciones registradas en el período seleccionado.',
                style: pw.TextStyle(fontSize: 10.5, color: _mutedText),
              ),
            )
          else
            _buildHistoryTable(
              records: newestFirst,
              profile: profile,
              unit: unit,
              dateFmt: dateFmt,
              timeFmt: timeFmt,
            ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _lightGreen,
              border: pw.Border.all(color: _primaryGreen, width: 0.6),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Aviso de responsabilidad médica: ${AppConstants.medicalDisclaimerShort}',
              style: pw.TextStyle(fontSize: 8.8, color: _mainText),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader({
    required Uint8List? logoBytes,
    required String periodLabel,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _primaryGreen, width: 1.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            children: [
              if (logoBytes != null) ...[
                pw.Image(pw.MemoryImage(logoBytes), width: 34, height: 34),
                pw.SizedBox(width: 10),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    AppConstants.appName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryGreen,
                    ),
                  ),
                  pw.Text(
                    AppConstants.appSlogan,
                    style: pw.TextStyle(fontSize: 9, color: _mutedText),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INFORME DE GLUCOSA',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _secondaryBlue,
                ),
              ),
              pw.Text(
                'Período: $periodLabel',
                style: pw.TextStyle(fontSize: 9, color: _mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    final generated = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 0.7)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado localmente por GlucoControl el $generated',
            style: pw.TextStyle(fontSize: 8.5, color: _mutedText),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8.5, color: _mutedText),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientInfoCard(
    PatientProfile? profile,
    String periodLabel,
    String unit,
  ) {
    final minVal = profile?.targetMinIn(unit) ??
        (unit == AppConstants.unitMgDl
            ? AppConstants.defaultMinMgDl
            : AppConstants.defaultMinMmolL);
    final maxVal = profile?.targetMaxIn(unit) ??
        (unit == AppConstants.unitMgDl
            ? AppConstants.defaultMaxMgDl
            : AppConstants.defaultMaxMmolL);

    final birthText = profile?.birthDate != null
        ? DateFormat('dd/MM/yyyy').format(profile!.birthDate!)
        : 'No registrada';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Paciente: ${profile?.fullName ?? "Sin configurar"}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _mainText,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Fecha de nacimiento: $birthText',
                  style: pw.TextStyle(fontSize: 9.5, color: _mutedText),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Rango de referencia médico:',
                style: pw.TextStyle(fontSize: 9, color: _mutedText),
              ),
              pw.Text(
                '${GlucoseConverter.formatValue(minVal, unit)} - ${GlucoseConverter.formatValue(maxVal, unit)} $unit',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(GlucoseStatistics stats) {
    pw.Widget kpi(String label, String value, PdfColor accent) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _borderColor),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                label,
                style: pw.TextStyle(fontSize: 8.5, color: _mutedText),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final avgText = stats.totalCount == 0
        ? '--'
        : '${GlucoseConverter.formatValue(stats.average, stats.unit)} ${stats.unit}';
    final minMaxText = stats.totalCount == 0
        ? '--'
        : '${GlucoseConverter.formatValue(stats.minValue, stats.unit)} / ${GlucoseConverter.formatValue(stats.maxValue, stats.unit)}';

    return pw.Row(
      children: [
        kpi('Mediciones', '${stats.totalCount}', _secondaryBlue),
        pw.SizedBox(width: 8),
        kpi('Promedio', avgText, _primaryGreen),
        pw.SizedBox(width: 8),
        kpi('Mín / Máx', minMaxText, _mainText),
        pw.SizedBox(width: 8),
        kpi(
          'En rango',
          '${stats.inRangePercent.toStringAsFixed(0)}%',
          _primaryGreen,
        ),
      ],
    );
  }

  static pw.Widget _buildVectorChart({
    required List<GlucoseRecord> records,
    required PatientProfile? profile,
    required String unit,
  }) {
    final values = records.map((r) => r.valueIn(unit)).toList();
    final minTarget = profile?.targetMinIn(unit) ??
        (unit == AppConstants.unitMgDl
            ? AppConstants.defaultMinMgDl
            : AppConstants.defaultMinMmolL);
    final maxTarget = profile?.targetMaxIn(unit) ??
        (unit == AppConstants.unitMgDl
            ? AppConstants.defaultMaxMgDl
            : AppConstants.defaultMaxMmolL);

    final rawMin = math.min(values.reduce(math.min), minTarget);
    final rawMax = math.max(values.reduce(math.max), maxTarget);
    final pad = unit == AppConstants.unitMgDl ? 15.0 : 1.0;
    final yMin = math.max(0.0, rawMin - pad);
    final yMax = rawMax + pad;
    final ySpan = math.max(1.0, yMax - yMin);

    return pw.Container(
      height: 150,
      padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.CustomPaint(
        size: const PdfPoint(500, 130),
        painter: (canvas, size) {
          const leftPad = 32.0;
          const bottomPad = 14.0;
          const topPad = 8.0;
          const rightPad = 10.0;

          final plotW = size.x - leftPad - rightPad;
          final plotH = size.y - topPad - bottomPad;

          double mapY(double v) => bottomPad + ((v - yMin) / ySpan) * plotH;

          final bandBottom =
              mapY(minTarget).clamp(bottomPad, bottomPad + plotH);
          final bandTop = mapY(maxTarget).clamp(bottomPad, bottomPad + plotH);
          canvas
            ..setFillColor(_lightGreen)
            ..drawRect(leftPad, bandBottom, plotW, bandTop - bandBottom)
            ..fillPath();

          canvas
            ..setStrokeColor(_borderColor)
            ..setLineWidth(0.5);
          for (int i = 0; i <= 4; i++) {
            final gy = bottomPad + (plotH * i / 4);
            canvas
              ..moveTo(leftPad, gy)
              ..lineTo(leftPad + plotW, gy)
              ..strokePath();
          }

          final count = values.length;
          double mapX(int index) {
            if (count <= 1) return leftPad + plotW / 2;
            return leftPad + (index / (count - 1)) * plotW;
          }

          if (count > 1) {
            canvas
              ..setStrokeColor(_secondaryBlue)
              ..setLineWidth(1.8)
              ..moveTo(mapX(0), mapY(values[0]));
            for (int i = 1; i < count; i++) {
              canvas.lineTo(mapX(i), mapY(values[i]));
            }
            canvas.strokePath();
          }

          for (int i = 0; i < count; i++) {
            final status = records[i].evaluateAgainst(profile);
            final dotColor = status == GlucoseRangeStatus.inRange
                ? _primaryGreen
                : (status == GlucoseRangeStatus.aboveRange ? _amber : _red);
            canvas
              ..setFillColor(dotColor)
              ..drawEllipse(mapX(i), mapY(values[i]), 3.0, 3.0)
              ..fillPath();
          }
        },
      ),
    );
  }

  static pw.Widget _buildHistoryTable({
    required List<GlucoseRecord> records,
    required PatientProfile? profile,
    required String unit,
    required DateFormat dateFmt,
    required DateFormat timeFmt,
  }) {
    final headers = [
      'Fecha',
      'Hora',
      'Glucosa',
      'Tipo de medición',
      'Referencia',
      'Observaciones',
    ];

    final data = records.map((r) {
      final converted = r.valueIn(unit);
      final status = r.evaluateAgainst(profile);
      return [
        dateFmt.format(r.measuredAt),
        timeFmt.format(r.measuredAt),
        '${GlucoseConverter.formatValue(converted, unit)} $unit',
        r.measurementType.label,
        status.label,
        r.notes?.trim().isNotEmpty == true ? r.notes!.trim() : '-',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: _primaryGreen),
      cellStyle: pw.TextStyle(fontSize: 8.5, color: _mainText),
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: pw.BoxDecoration(color: _lightGray),
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.3),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.3),
        3: const pw.FlexColumnWidth(1.9),
        4: const pw.FlexColumnWidth(1.6),
        5: const pw.FlexColumnWidth(2.4),
      },
    );
  }

  /// Abre el selector nativo de Android (SAF) para guardar el PDF directamente
  /// en Descargas o la carpeta que elija el usuario, visible en "Mis archivos".
  static Future<String?> savePdfToDevice(Uint8List bytes) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'GlucoControl_Informe_$timestamp.pdf';

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar informe PDF',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );

    if (savedPath != null && savedPath.isNotEmpty) {
      return savedPath;
    }
    return null;
  }

  /// Respaldo interno en documentos de la app (útil para pruebas o fallback).
  static Future<File> savePdfLocally(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory(p.join(dir.path, 'informes'));
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      p.join(reportsDir.path, 'GlucoControl_Informe_$timestamp.pdf'),
    );
    return file.writeAsBytes(bytes, flush: true);
  }

  /// Comparte el informe PDF mediante las aplicaciones instaladas en Android.
  static Future<void> sharePdf(Uint8List bytes) async {
    final timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'GlucoControl_Informe_$timestamp.pdf',
    );
  }

  /// Abre el diálogo nativo de impresión de Android.
  static Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Informe_GlucoControl.pdf',
    );
  }
}
