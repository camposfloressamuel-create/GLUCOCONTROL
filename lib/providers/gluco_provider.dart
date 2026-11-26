import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/blood_pressure_record.dart';
import '../models/glucose_record.dart';
import '../models/patient_profile.dart';
import '../models/reminder_item.dart';
import '../models/water_record.dart';
import '../models/weight_record.dart';
import '../notifications/notification_service.dart';
import '../services/backup_service.dart';
import '../services/preferences_service.dart';
import '../utils/constants.dart';

class GlucoProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  final PreferencesService _prefs;
  final NotificationService _notifications;

  GlucoProvider({
    DatabaseHelper? db,
    PreferencesService? prefs,
    NotificationService? notifications,
  })  : _db = db ?? DatabaseHelper.instance,
        _prefs = prefs ?? PreferencesService(),
        _notifications = notifications ?? NotificationService.instance;

  bool _isLoading = true;
  bool _onboardingCompleted = false;
  PatientProfile? _profile;
  List<GlucoseRecord> _records = [];
  List<ReminderItem> _reminders = [];
  List<BloodPressureRecord> _bloodPressureRecords = [];
  List<WeightRecord> _weightRecords = [];
  List<WaterRecord> _waterRecords = [];
  int _dailyWaterGoalMl = AppConstants.defaultDailyWaterGoalMl;
  double _lastHeightCm = 165.0;

  bool get isLoading => _isLoading;
  bool get onboardingCompleted => _onboardingCompleted;
  PatientProfile? get profile => _profile;
  List<GlucoseRecord> get records => List.unmodifiable(_records);
  List<ReminderItem> get reminders => List.unmodifiable(_reminders);
  List<BloodPressureRecord> get bloodPressureRecords =>
      List.unmodifiable(_bloodPressureRecords);
  List<WeightRecord> get weightRecords => List.unmodifiable(_weightRecords);
  List<WaterRecord> get waterRecords => List.unmodifiable(_waterRecords);
  int get dailyWaterGoalMl => _dailyWaterGoalMl;
  double get lastHeightCm => _lastHeightCm;

  String get preferredUnit =>
      _profile?.preferredUnit ?? AppConstants.unitMgDl;

  GlucoseRecord? get latestRecord => _records.isEmpty ? null : _records.first;
  BloodPressureRecord? get latestBloodPressure =>
      _bloodPressureRecords.isEmpty ? null : _bloodPressureRecords.first;
  WeightRecord? get latestWeight =>
      _weightRecords.isEmpty ? null : _weightRecords.first;

  int get todayRecordsCount {
    final now = DateTime.now();
    return _records.where((r) {
      return r.measuredAt.year == now.year &&
          r.measuredAt.month == now.month &&
          r.measuredAt.day == now.day;
    }).length;
  }

  List<WaterRecord> get todayWaterRecords {
    final now = DateTime.now();
    return _waterRecords.where((w) {
      return w.loggedAt.year == now.year &&
          w.loggedAt.month == now.month &&
          w.loggedAt.day == now.day;
    }).toList();
  }

  int get todayWaterMl =>
      todayWaterRecords.fold<int>(0, (sum, item) => sum + item.amountMl);

  int get todayWaterCups => todayWaterRecords.length;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _onboardingCompleted = await _prefs.isOnboardingCompleted();
      _dailyWaterGoalMl = await _prefs.getDailyWaterGoalMl();
      _lastHeightCm = await _prefs.getLastHeightCm();
      _profile = await _db.getProfile();
      _records = await _db.getAllRecords();
      _reminders = await _db.getAllReminders();
      _bloodPressureRecords = await _db.getAllBloodPressureRecords();
      _weightRecords = await _db.getAllWeightRecords();
      _waterRecords = await _db.getAllWaterRecords();
      if (_profile != null && !_onboardingCompleted) {
        _onboardingCompleted = true;
        await _prefs.setOnboardingCompleted(true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(PatientProfile profile) async {
    _profile = await _db.saveProfile(profile);
    _onboardingCompleted = true;
    await _prefs.setOnboardingCompleted(true);
    await _prefs.setPreferredUnit(_profile!.preferredUnit);
    notifyListeners();
  }

  // ===================== GLUCOSA =====================

  Future<GlucoseRecord> addRecord(GlucoseRecord record) async {
    final saved = await _db.insertRecord(record);
    _records = await _db.getAllRecords();
    notifyListeners();
    return saved;
  }

  Future<void> updateRecord(GlucoseRecord record) async {
    await _db.updateRecord(record);
    _records = await _db.getAllRecords();
    notifyListeners();
  }

  Future<void> deleteRecord(int id) async {
    await _db.deleteRecord(id);
    _records = await _db.getAllRecords();
    notifyListeners();
  }

  Future<List<GlucoseRecord>> queryRecords({
    DateTime? startDate,
    DateTime? endDate,
    MeasurementType? type,
    String? searchQuery,
  }) {
    return _db.getAllRecords(
      startDate: startDate,
      endDate: endDate,
      type: type,
      searchQuery: searchQuery,
    );
  }

  // ===================== PRESIÓN ARTERIAL =====================

  Future<void> addBloodPressure(BloodPressureRecord record) async {
    await _db.insertBloodPressureRecord(record);
    _bloodPressureRecords = await _db.getAllBloodPressureRecords();
    notifyListeners();
  }

  Future<void> deleteBloodPressure(int id) async {
    await _db.deleteBloodPressureRecord(id);
    _bloodPressureRecords = await _db.getAllBloodPressureRecords();
    notifyListeners();
  }

  // ===================== PESO E IMC =====================

  Future<void> addWeight(WeightRecord record) async {
    await _db.insertWeightRecord(record);
    _lastHeightCm = record.heightCm;
    await _prefs.setLastHeightCm(record.heightCm);
    _weightRecords = await _db.getAllWeightRecords();
    notifyListeners();
  }

  Future<void> deleteWeight(int id) async {
    await _db.deleteWeightRecord(id);
    _weightRecords = await _db.getAllWeightRecords();
    notifyListeners();
  }

  // ===================== AGUA / HIDRATACIÓN =====================

  Future<void> addWater(int amountMl) async {
    await _db.insertWaterRecord(
      WaterRecord(amountMl: amountMl, loggedAt: DateTime.now()),
    );
    _waterRecords = await _db.getAllWaterRecords();
    notifyListeners();
  }

  Future<void> deleteWater(int id) async {
    await _db.deleteWaterRecord(id);
    _waterRecords = await _db.getAllWaterRecords();
    notifyListeners();
  }

  Future<void> setDailyWaterGoalMl(int goalMl) async {
    _dailyWaterGoalMl = goalMl;
    await _prefs.setDailyWaterGoalMl(goalMl);
    notifyListeners();
  }

  // ===================== RECORDATORIOS =====================

  Future<void> addReminder(ReminderItem reminder) async {
    final saved = await _db.insertReminder(reminder);
    await _notifications.syncReminder(saved);
    _reminders = await _db.getAllReminders();
    notifyListeners();
  }

  Future<void> updateReminder(ReminderItem reminder) async {
    await _db.updateReminder(reminder);
    await _notifications.syncReminder(reminder);
    _reminders = await _db.getAllReminders();
    notifyListeners();
  }

  Future<void> toggleReminder(ReminderItem reminder, bool enabled) async {
    final updated = reminder.copyWith(isEnabled: enabled);
    await updateReminder(updated);
  }

  Future<void> deleteReminder(int id) async {
    await _db.deleteReminder(id);
    await _notifications.cancelReminder(id);
    _reminders = await _db.getAllReminders();
    notifyListeners();
  }

  // ===================== RESTAURACIÓN =====================

  Future<void> restoreFromBackup(BackupPayload payload) async {
    await _db.replaceAllData(
      profile: payload.profile,
      records: payload.records,
      reminders: payload.reminders,
      bloodPressureRecords: payload.bloodPressureRecords,
      weightRecords: payload.weightRecords,
      waterRecords: payload.waterRecords,
    );
    _profile = await _db.getProfile();
    _records = await _db.getAllRecords();
    _reminders = await _db.getAllReminders();
    _bloodPressureRecords = await _db.getAllBloodPressureRecords();
    _weightRecords = await _db.getAllWeightRecords();
    _waterRecords = await _db.getAllWaterRecords();
    if (_profile != null) {
      _onboardingCompleted = true;
      await _prefs.setOnboardingCompleted(true);
      await _prefs.setPreferredUnit(_profile!.preferredUnit);
    }
    await _notifications.resyncAllReminders(_reminders);
    notifyListeners();
  }
}
