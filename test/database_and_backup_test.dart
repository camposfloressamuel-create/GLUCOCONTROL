import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/database/database_helper.dart';
import 'package:glucocontrol/models/blood_pressure_record.dart';
import 'package:glucocontrol/models/glucose_record.dart';
import 'package:glucocontrol/models/patient_profile.dart';
import 'package:glucocontrol/models/reminder_item.dart';
import 'package:glucocontrol/models/water_record.dart';
import 'package:glucocontrol/models/weight_record.dart';
import 'package:glucocontrol/services/backup_service.dart';
import 'package:glucocontrol/services/statistics_service.dart';
import 'package:glucocontrol/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('glucocontrol_test_');
    dbPath = p.join(tempDir.path, 'glucocontrol_test.db');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('CRUD completo, persistencia SQLite v2 (glucosa, presión, peso/IMC, agua) y respaldo JSON', () async {
    final db = DatabaseHelper.forTesting(dbPath);

    final savedProfile = await db.saveProfile(
      PatientProfile(
        fullName: 'Elena Morales',
        birthDate: DateTime(1958, 4, 15),
        preferredUnit: AppConstants.unitMgDl,
        targetMin: 75,
        targetMax: 140,
        trackingStartDate: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      ),
    );
    expect(savedProfile.id, isNotNull);

    final r1 = await db.insertRecord(
      GlucoseRecord(
        value: 98,
        unit: AppConstants.unitMgDl,
        measuredAt: DateTime(2026, 5, 10, 7, 15),
        measurementType: MeasurementType.fasting,
        notes: 'En ayunas tranquila',
        createdAt: DateTime(2026, 5, 10, 7, 15),
      ),
    );
    final r2 = await db.insertRecord(
      GlucoseRecord(
        value: 152,
        unit: AppConstants.unitMgDl,
        measuredAt: DateTime(2026, 5, 10, 14, 0),
        measurementType: MeasurementType.afterLunch,
        notes: 'Después del almuerzo familiar',
        createdAt: DateTime(2026, 5, 10, 14, 0),
      ),
    );

    await db.insertBloodPressureRecord(
      BloodPressureRecord(
        systolic: 115,
        diastolic: 75,
        pulse: 68,
        measuredAt: DateTime(2026, 5, 10, 8, 0),
        createdAt: DateTime(2026, 5, 10, 8, 0),
      ),
    );

    final w = await db.insertWeightRecord(
      WeightRecord(
        weightKg: 70,
        heightCm: 170,
        measuredAt: DateTime(2026, 5, 10, 8, 5),
        createdAt: DateTime(2026, 5, 10, 8, 5),
      ),
    );
    expect(w.bmi, closeTo(24.22, 0.05));
    expect(w.category, BmiCategory.normal);

    await db.insertWaterRecord(
      WaterRecord(amountMl: 250, loggedAt: DateTime(2026, 5, 10, 9, 0)),
    );

    await db.insertReminder(
      ReminderItem(
        title: 'Medición de la mañana',
        category: ReminderCategory.glucoseCheck,
        frequency: ReminderFrequency.daily,
        hour: 7,
        minute: 30,
        isEnabled: true,
        createdAt: DateTime(2026, 5, 10),
      ),
    );

    // Cerrar y reabrir SQLite para verificar persistencia real
    await db.close();
    final reopenedDb = DatabaseHelper.forTesting(dbPath);
    final persistedProfile = await reopenedDb.getProfile();
    final persistedRecords = await reopenedDb.getAllRecords();
    final persistedReminders = await reopenedDb.getAllReminders();
    final persistedBp = await reopenedDb.getAllBloodPressureRecords();
    final persistedWeight = await reopenedDb.getAllWeightRecords();
    final persistedWater = await reopenedDb.getAllWaterRecords();

    expect(persistedProfile?.fullName, 'Elena Morales');
    expect(persistedRecords.length, 2);
    expect(persistedReminders.length, 1);
    expect(persistedBp.length, 1);
    expect(persistedWeight.length, 1);
    expect(persistedWater.length, 1);

    final stats = StatisticsService.calculate(
      records: persistedRecords,
      profile: persistedProfile,
    );
    expect(stats.totalCount, 2);

    // Exportar y restaurar respaldo JSON v2
    final jsonBackup = BackupService.serializeBackup(
      profile: persistedProfile,
      records: persistedRecords,
      reminders: persistedReminders,
      bloodPressureRecords: persistedBp,
      weightRecords: persistedWeight,
      waterRecords: persistedWater,
    );
    final parsedBackup = BackupService.parseAndValidateBackup(jsonBackup);
    expect(parsedBackup.bloodPressureRecords.length, 1);
    expect(parsedBackup.weightRecords.length, 1);
    expect(parsedBackup.waterRecords.length, 1);

    await reopenedDb.deleteRecord(r1.id!);
    expect((await reopenedDb.getAllRecords()).length, 1);

    await reopenedDb.replaceAllData(
      profile: parsedBackup.profile,
      records: parsedBackup.records,
      reminders: parsedBackup.reminders,
      bloodPressureRecords: parsedBackup.bloodPressureRecords,
      weightRecords: parsedBackup.weightRecords,
      waterRecords: parsedBackup.waterRecords,
    );
    expect((await reopenedDb.getAllRecords()).length, 2);
    expect((await reopenedDb.getAllBloodPressureRecords()).length, 1);

    // Verificar actualización de registro existente
    await reopenedDb.updateRecord(r2.copyWith(value: 130));
    expect(
      () => BackupService.parseAndValidateBackup('{"app":"OtraApp"}'),
      throwsA(isA<BackupValidationException>()),
    );

    await reopenedDb.close();
  });
}
