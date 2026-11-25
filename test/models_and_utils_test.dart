import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/models/glucose_record.dart';
import 'package:glucocontrol/models/patient_profile.dart';
import 'package:glucocontrol/models/reminder_item.dart';
import 'package:glucocontrol/utils/constants.dart';
import 'package:glucocontrol/utils/glucose_converter.dart';

void main() {
  group('Validación y conversión de glucosa', () {
    test('Rechaza valores vacíos, negativos, no numéricos y fuera de límite', () {
      expect(GlucoseConverter.validateInput('', AppConstants.unitMgDl), isNotNull);
      expect(GlucoseConverter.validateInput('-10', AppConstants.unitMgDl), isNotNull);
      expect(GlucoseConverter.validateInput('abc', AppConstants.unitMgDl), isNotNull);
      expect(GlucoseConverter.validateInput('5', AppConstants.unitMgDl), isNotNull);
      expect(GlucoseConverter.validateInput('950', AppConstants.unitMgDl), isNotNull);
      expect(GlucoseConverter.validateInput('115', AppConstants.unitMgDl), isNull);
      expect(GlucoseConverter.validateInput('6,2', AppConstants.unitMmolL), isNull);
    });

    test('Convierte correctamente entre mg/dL y mmol/L', () {
      final mmol = GlucoseConverter.convert(
        value: 180,
        fromUnit: AppConstants.unitMgDl,
        toUnit: AppConstants.unitMmolL,
      );
      expect(mmol, closeTo(10.0, 0.1));

      final mgDl = GlucoseConverter.convert(
        value: 5.5,
        fromUnit: AppConstants.unitMmolL,
        toUnit: AppConstants.unitMgDl,
      );
      expect(mgDl, closeTo(99.0, 1.0));
    });
  });

  group('Evaluación de rangos personalizados del perfil', () {
    final profile = PatientProfile(
      fullName: 'Carlos Ramírez',
      preferredUnit: AppConstants.unitMgDl,
      targetMin: 80,
      targetMax: 130,
      trackingStartDate: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('Clasifica correctamente por debajo, en rango y por encima', () {
      final low = GlucoseRecord(
        value: 68,
        unit: AppConstants.unitMgDl,
        measuredAt: DateTime(2026, 5, 10, 7, 30),
        measurementType: MeasurementType.fasting,
        createdAt: DateTime(2026, 5, 10, 7, 30),
      );
      final normal = low.copyWith(value: 105);
      final high = low.copyWith(value: 175);

      expect(low.evaluateAgainst(profile), GlucoseRangeStatus.belowRange);
      expect(normal.evaluateAgainst(profile), GlucoseRangeStatus.inRange);
      expect(high.evaluateAgainst(profile), GlucoseRangeStatus.aboveRange);
    });
  });

  group('Modelo de recordatorios', () {
    test('Serializa y deserializa días de semana y citas médicas', () {
      final reminder = ReminderItem(
        id: 1,
        title: 'Medir antes de almorzar',
        category: ReminderCategory.glucoseCheck,
        frequency: ReminderFrequency.weeklyDays,
        hour: 12,
        minute: 30,
        weekdays: const [1, 3, 5],
        isEnabled: true,
        createdAt: DateTime(2026, 5, 1),
      );

      final restored = ReminderItem.fromMap(reminder.toMap());
      expect(restored.title, 'Medir antes de almorzar');
      expect(restored.weekdays, [1, 3, 5]);
      expect(restored.isEnabled, isTrue);
      expect(restored.scheduleSummary, contains('Lun, Mié, Vie'));
    });
  });
}
