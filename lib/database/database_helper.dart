import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/glucose_record.dart';
import '../models/patient_profile.dart';
import '../models/reminder_item.dart';

class DatabaseHelper {
  static const String _dbName = 'glucocontrol.db';
  static const int _dbVersion = 1;

  static const String tableProfile = 'patient_profile';
  static const String tableRecords = 'glucose_records';
  static const String tableReminders = 'reminders';

  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;
  String? _customPath;

  DatabaseHelper._internal();

  /// Constructor para pruebas unitarias con bases de datos aisladas.
  DatabaseHelper.forTesting(String path) : _customPath = path;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = _customPath ?? p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableProfile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        birth_date TEXT,
        preferred_unit TEXT NOT NULL,
        target_min REAL NOT NULL,
        target_max REAL NOT NULL,
        tracking_start_date TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        measured_at TEXT NOT NULL,
        measurement_type TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_glucose_measured_at ON $tableRecords (measured_at DESC)
    ''');

    await db.execute('''
      CREATE TABLE $tableReminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        frequency TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        weekdays TEXT NOT NULL,
        appointment_date TEXT,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
  }

  // ===================== PERFIL DEL PACIENTE =====================

  Future<PatientProfile?> getProfile() async {
    final db = await database;
    final rows = await db.query(tableProfile, limit: 1);
    if (rows.isEmpty) return null;
    return PatientProfile.fromMap(rows.first);
  }

  Future<PatientProfile> saveProfile(PatientProfile profile) async {
    final db = await database;
    final existing = await getProfile();
    final updated = profile.copyWith(updatedAt: DateTime.now());
    if (existing == null) {
      final id = await db.insert(tableProfile, updated.toMap());
      return updated.copyWith(id: id);
    } else {
      final withId = updated.copyWith(id: existing.id);
      await db.update(
        tableProfile,
        withId.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return withId;
    }
  }

  // ===================== MEDICIONES DE GLUCOSA =====================

  Future<GlucoseRecord> insertRecord(GlucoseRecord record) async {
    final db = await database;
    final id = await db.insert(tableRecords, record.toMap());
    return record.copyWith(id: id);
  }

  Future<int> updateRecord(GlucoseRecord record) async {
    final db = await database;
    return db.update(
      tableRecords,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return db.delete(
      tableRecords,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<GlucoseRecord>> getAllRecords({
    DateTime? startDate,
    DateTime? endDate,
    MeasurementType? type,
    String? searchQuery,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      whereClauses.add('measured_at >= ?');
      whereArgs.add(start.toIso8601String());
    }
    if (endDate != null) {
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );
      whereClauses.add('measured_at <= ?');
      whereArgs.add(end.toIso8601String());
    }
    if (type != null) {
      whereClauses.add('measurement_type = ?');
      whereArgs.add(type.code);
    }

    final rows = await db.query(
      tableRecords,
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'measured_at DESC',
    );

    var results = rows.map(GlucoseRecord.fromMap).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      results = results.where((r) {
        final notesMatch = (r.notes ?? '').toLowerCase().contains(q);
        final typeMatch = r.measurementType.label.toLowerCase().contains(q);
        final valueMatch = r.value.toString().contains(q);
        return notesMatch || typeMatch || valueMatch;
      }).toList();
    }

    return results;
  }

  // ===================== RECORDATORIOS =====================

  Future<List<ReminderItem>> getAllReminders() async {
    final db = await database;
    final rows = await db.query(
      tableReminders,
      orderBy: 'is_enabled DESC, hour ASC, minute ASC',
    );
    return rows.map(ReminderItem.fromMap).toList();
  }

  Future<ReminderItem> insertReminder(ReminderItem reminder) async {
    final db = await database;
    final id = await db.insert(tableReminders, reminder.toMap());
    return reminder.copyWith(id: id);
  }

  Future<int> updateReminder(ReminderItem reminder) async {
    final db = await database;
    return db.update(
      tableReminders,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return db.delete(
      tableReminders,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===================== RESTAURACIÓN TRANSACCIONAL =====================

  Future<void> replaceAllData({
    required PatientProfile? profile,
    required List<GlucoseRecord> records,
    required List<ReminderItem> reminders,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableProfile);
      await txn.delete(tableRecords);
      await txn.delete(tableReminders);

      if (profile != null) {
        final map = profile.toMap()..remove('id');
        await txn.insert(tableProfile, map);
      }

      for (final rec in records) {
        final map = rec.toMap()..remove('id');
        await txn.insert(tableRecords, map);
      }

      for (final rem in reminders) {
        final map = rem.toMap()..remove('id');
        await txn.insert(tableReminders, map);
      }
    });
  }
}
