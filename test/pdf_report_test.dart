import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/models/glucose_record.dart';
import 'package:glucocontrol/models/patient_profile.dart';
import 'package:glucocontrol/reports/pdf_report_service.dart';
import 'package:glucocontrol/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Genera un documento PDF válido con datos reales del paciente', () async {
    final profile = PatientProfile(
      fullName: 'Jorge Salazar',
      preferredUnit: AppConstants.unitMgDl,
      targetMin: 70,
      targetMax: 140,
      trackingStartDate: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    final records = [
      GlucoseRecord(
        value: 102,
        unit: AppConstants.unitMgDl,
        measuredAt: DateTime(2026, 5, 1, 7, 30),
        measurementType: MeasurementType.fasting,
        notes: 'Sin novedad',
        createdAt: DateTime(2026, 5, 1, 7, 30),
      ),
      GlucoseRecord(
        value: 148,
        unit: AppConstants.unitMgDl,
        measuredAt: DateTime(2026, 5, 2, 13, 45),
        measurementType: MeasurementType.afterLunch,
        notes: 'Almuerzo con arroz',
        createdAt: DateTime(2026, 5, 2, 13, 45),
      ),
    ];

    final bytes = await PdfReportService.buildReportBytes(
      profile: profile,
      records: records,
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 7),
    );

    expect(bytes.isNotEmpty, isTrue);
    final header = ascii.decode(bytes.sublist(0, 5));
    expect(header, '%PDF-');
  });
}
