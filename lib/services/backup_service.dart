import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/blood_pressure_record.dart';
import '../models/glucose_record.dart';
import '../models/patient_profile.dart';
import '../models/reminder_item.dart';
import '../models/water_record.dart';
import '../models/weight_record.dart';
import '../utils/constants.dart';

class BackupPayload {
  final PatientProfile? profile;
  final List<GlucoseRecord> records;
  final List<ReminderItem> reminders;
  final List<BloodPressureRecord> bloodPressureRecords;
  final List<WeightRecord> weightRecords;
  final List<WaterRecord> waterRecords;
  final DateTime exportedAt;

  const BackupPayload({
    required this.profile,
    required this.records,
    required this.reminders,
    this.bloodPressureRecords = const [],
    this.weightRecords = const [],
    this.waterRecords = const [],
    required this.exportedAt,
  });
}

class BackupValidationException implements Exception {
  final String message;
  const BackupValidationException(this.message);

  @override
  String toString() => message;
}

class BackupService {
  /// Serializa todos los datos locales a un JSON estructurado y verificable.
  static String serializeBackup({
    required PatientProfile? profile,
    required List<GlucoseRecord> records,
    required List<ReminderItem> reminders,
    List<BloodPressureRecord> bloodPressureRecords = const [],
    List<WeightRecord> weightRecords = const [],
    List<WaterRecord> waterRecords = const [],
  }) {
    final payload = {
      'app': AppConstants.appName,
      'schema_version': AppConstants.backupSchemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'profile': profile?.toMap(),
      'records': records.map((r) => r.toMap()).toList(),
      'reminders': reminders.map((rem) => rem.toMap()).toList(),
      'blood_pressure_records':
          bloodPressureRecords.map((bp) => bp.toMap()).toList(),
      'weight_records': weightRecords.map((w) => w.toMap()).toList(),
      'water_records': waterRecords.map((wa) => wa.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Valida y parsea un contenido JSON (compatible con v1 y v2) antes de restaurar.
  static BackupPayload parseAndValidateBackup(String jsonString) {
    if (jsonString.trim().isEmpty) {
      throw const BackupValidationException(
        'El archivo de copia de seguridad está vacío.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      throw const BackupValidationException(
        'El archivo no tiene un formato JSON válido.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupValidationException(
        'La estructura del archivo de respaldo no es compatible.',
      );
    }

    if (decoded['app'] != AppConstants.appName) {
      throw const BackupValidationException(
        'Este archivo no corresponde a una copia de seguridad de GlucoControl.',
      );
    }

    final schemaVersion = decoded['schema_version'];
    if (schemaVersion is! int ||
        schemaVersion > AppConstants.backupSchemaVersion) {
      throw const BackupValidationException(
        'La versión de la copia de seguridad no es compatible con esta versión de la app.',
      );
    }

    PatientProfile? profile;
    if (decoded['profile'] != null) {
      if (decoded['profile'] is! Map<String, dynamic>) {
        throw const BackupValidationException(
          'Los datos del perfil en el respaldo están dañados.',
        );
      }
      final profileMap = decoded['profile'] as Map<String, dynamic>;
      if ((profileMap['full_name'] as String?)?.trim().isEmpty ?? true) {
        throw const BackupValidationException(
          'El perfil del respaldo no contiene un nombre válido.',
        );
      }
      profile = PatientProfile.fromMap(profileMap);
    }

    final rawRecords = decoded['records'];
    if (rawRecords is! List) {
      throw const BackupValidationException(
        'La lista de mediciones en el respaldo no es válida.',
      );
    }

    final records = <GlucoseRecord>[];
    for (final item in rawRecords) {
      if (item is! Map<String, dynamic>) {
        throw const BackupValidationException(
          'Se encontró una medición con formato inválido en el respaldo.',
        );
      }
      final val = item['value'];
      if (val is! num || val <= 0) {
        throw const BackupValidationException(
          'Se encontró un valor de glucosa inválido en el respaldo.',
        );
      }
      if (item['measured_at'] is! String ||
          DateTime.tryParse(item['measured_at'] as String) == null) {
        throw const BackupValidationException(
          'Se encontró una fecha inválida en las mediciones del respaldo.',
        );
      }
      records.add(GlucoseRecord.fromMap(item));
    }

    final reminders = <ReminderItem>[];
    final rawReminders = decoded['reminders'];
    if (rawReminders != null) {
      if (rawReminders is! List) {
        throw const BackupValidationException(
          'La lista de recordatorios en el respaldo no es válida.',
        );
      }
      for (final item in rawReminders) {
        if (item is! Map<String, dynamic>) {
          throw const BackupValidationException(
            'Se encontró un recordatorio inválido en el respaldo.',
          );
        }
        reminders.add(ReminderItem.fromMap(item));
      }
    }

    final bpRecords = <BloodPressureRecord>[];
    final rawBp = decoded['blood_pressure_records'];
    if (rawBp is List) {
      for (final item in rawBp) {
        if (item is Map<String, dynamic>) {
          bpRecords.add(BloodPressureRecord.fromMap(item));
        }
      }
    }

    final weightRecords = <WeightRecord>[];
    final rawWeight = decoded['weight_records'];
    if (rawWeight is List) {
      for (final item in rawWeight) {
        if (item is Map<String, dynamic>) {
          weightRecords.add(WeightRecord.fromMap(item));
        }
      }
    }

    final waterRecords = <WaterRecord>[];
    final rawWater = decoded['water_records'];
    if (rawWater is List) {
      for (final item in rawWater) {
        if (item is Map<String, dynamic>) {
          waterRecords.add(WaterRecord.fromMap(item));
        }
      }
    }

    final exportedAt = decoded['exported_at'] is String
        ? (DateTime.tryParse(decoded['exported_at'] as String) ?? DateTime.now())
        : DateTime.now();

    return BackupPayload(
      profile: profile,
      records: records,
      reminders: reminders,
      bloodPressureRecords: bpRecords,
      weightRecords: weightRecords,
      waterRecords: waterRecords,
      exportedAt: exportedAt,
    );
  }

  /// Guarda la copia de seguridad JSON en el almacenamiento local del dispositivo.
  static Future<File> exportToLocalFile({
    required PatientProfile? profile,
    required List<GlucoseRecord> records,
    required List<ReminderItem> reminders,
    List<BloodPressureRecord> bloodPressureRecords = const [],
    List<WeightRecord> weightRecords = const [],
    List<WaterRecord> waterRecords = const [],
  }) async {
    final jsonContent = serializeBackup(
      profile: profile,
      records: records,
      reminders: reminders,
      bloodPressureRecords: bloodPressureRecords,
      weightRecords: weightRecords,
      waterRecords: waterRecords,
    );
    final dir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory(p.join(dir.path, 'backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      p.join(backupsDir.path, 'GlucoControl_respaldo_$timestamp.json'),
    );
    return file.writeAsString(jsonContent, flush: true);
  }
}
