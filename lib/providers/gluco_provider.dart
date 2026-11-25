import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/glucose_record.dart';
import '../models/patient_profile.dart';
import '../models/reminder_item.dart';
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

  bool get isLoading => _isLoading;
  bool get onboardingCompleted => _onboardingCompleted;
  PatientProfile? get profile => _profile;
  List<GlucoseRecord> get records => List.unmodifiable(_records);
  List<ReminderItem> get reminders => List.unmodifiable(_reminders);

  String get preferredUnit =>
      _profile?.preferredUnit ?? AppConstants.unitMgDl;

  GlucoseRecord? get latestRecord => _records.isEmpty ? null : _records.first;

  int get todayRecordsCount {
    final now = DateTime.now();
    return _records.where((r) {
      return r.measuredAt.year == now.year &&
          r.measuredAt.month == now.month &&
          r.measuredAt.day == now.day;
    }).length;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _onboardingCompleted = await _prefs.isOnboardingCompleted();
      _profile = await _db.getProfile();
      _records = await _db.getAllRecords();
      _reminders = await _db.getAllReminders();
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

  Future<void> restoreFromBackup(BackupPayload payload) async {
    await _db.replaceAllData(
      profile: payload.profile,
      records: payload.records,
      reminders: payload.reminders,
    );
    _profile = await _db.getProfile();
    _records = await _db.getAllRecords();
    _reminders = await _db.getAllReminders();
    if (_profile != null) {
      _onboardingCompleted = true;
      await _prefs.setOnboardingCompleted(true);
      await _prefs.setPreferredUnit(_profile!.preferredUnit);
    }
    await _notifications.resyncAllReminders(_reminders);
    notifyListeners();
  }
}
