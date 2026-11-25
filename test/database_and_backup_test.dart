import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/database/database_helper.dart';
import 'package:glucocontrol/models/glucose_record.dart';
import 'package:glucocontrol/models/patient_profile.dart';
import 'package:glucocontrol/models/reminder_item.dart';
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

  test('CRUD completo, persistencia tras cerrar/reabrir SQLite, estadísticas y respaldo JSON', () async {
    final db = DatabaseHelper.forTesting(dbPath);

    // 1. Crear perfil del paciente
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

    // 2. Registrar mediciones
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
    final r3 = await db.insertRecord(
      GlucoseRecord(
        value: 112,
        unit: AppConstants.unitMgDl,
        measuredAt: DateTime(2026, 5, 11, 21, 0),
        measurementType: MeasurementType.beforeSleep,
        createdAt: DateTime(2026, 5, 11, 21, 0),
      ),
    );

    // 3. Consultar historial y filtros
    final all = await db.getAllRecords();
    expect(all.length, 3);
    expect(all.first.id, r3.id); // Orden cronológico descendente

    final filteredByType = await db.getAllRecords(type: MeasurementType.fasting);
    expect(filteredByType.length, 1);
    expect(filteredByType.first.id, r1.id);

    final filteredBySearch = await db.getAllRecords(searchQuery: 'almuerzo');
    expect(filteredBySearch.length, 1);
    expect(filteredBySearch.first.id, r2.id);

    // 4. Editar registro
    await db.updateRecord(r2.copyWith(value: 138, notes: 'Valor corregido'));
    final afterEdit = await db.getAllRecords(type: MeasurementType.afterLunch);
    expect(afterEdit.first.value, 138);
    expect(afterEdit.first.notes, 'Valor corregido');

    // 5. Crear recordatorio
    final rem = await db.insertReminder(
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
    expect(rem.id, isNotNull);

    // 6. Verificar persistencia cerrando y reabriendo la base de datos
    await db.close();
    final reopenedDb = DatabaseHelper.forTesting(dbPath);
    final persistedProfile = await reopenedDb.getProfile();
    final persistedRecords = await reopenedDb.getAllRecords();
    final persistedReminders = await reopenedDb.getAllReminders();

    expect(persistedProfile?.fullName, 'Elena Morales');
    expect(persistedRecords.length, 3);
    expect(persistedReminders.length, 1);

    // 7. Calcular estadísticas
    final stats = StatisticsService.calculate(
      records: persistedRecords,
      profile: persistedProfile,
    );
    expect(stats.totalCount, 3);
    expect(stats.average, closeTo((98 + 138 + 112) / 3, 0.01));
    expect(stats.minValue, 98);
    expect(stats.maxValue, 138);
    expect(stats.inRangeCount, 3);

    // 8. Exportar copia de seguridad JSON y validar restauración
    final jsonBackup = BackupService.serializeBackup(
      profile: persistedProfile,
      records: persistedRecords,
      reminders: persistedReminders,
    );
    final parsedBackup = BackupService.parseAndValidateBackup(jsonBackup);
    expect(parsedBackup.profile?.fullName, 'Elena Morales');
    expect(parsedBackup.records.length, 3);
    expect(parsedBackup.reminders.length, 1);

    // 9. Eliminar un registro y luego restaurar la copia completa
    await reopenedDb.deleteRecord(r1.id!);
    expect((await reopenedDb.getAllRecords()).length, 2);

    await reopenedDb.replaceAllData(
      profile: parsedBackup.profile,
      records: parsedBackup.records,
      reminders: parsedBackup.reminders,
    );
    expect((await reopenedDb.getAllRecords()).length, 3);

    // 10. Validar que respaldos corruptos son rechazados
    expect(
      () => BackupService.parseAndValidateBackup('{"app":"OtraApp"}'),
      throwsA(isA<BackupValidationException>()),
    );

    await reopenedDb.close();
  });
}
