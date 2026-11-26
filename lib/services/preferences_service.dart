import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PreferencesService {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyPreferredUnit = 'preferred_unit';
  static const String _keyMedicalNoticeAccepted = 'medical_notice_accepted';
  static const String _keyDailyWaterGoalMl = 'daily_water_goal_ml';
  static const String _keyLastHeightCm = 'last_height_cm';

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, value);
  }

  Future<String> getPreferredUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPreferredUnit) ?? AppConstants.unitMgDl;
  }

  Future<void> setPreferredUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreferredUnit, unit);
  }

  Future<bool> isMedicalNoticeAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMedicalNoticeAccepted) ?? false;
  }

  Future<void> setMedicalNoticeAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMedicalNoticeAccepted, value);
  }

  Future<int> getDailyWaterGoalMl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyWaterGoalMl) ??
        AppConstants.defaultDailyWaterGoalMl;
  }

  Future<void> setDailyWaterGoalMl(int goalMl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyWaterGoalMl, goalMl);
  }

  Future<double> getLastHeightCm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyLastHeightCm) ?? 165.0;
  }

  Future<void> setLastHeightCm(double heightCm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLastHeightCm, heightCm);
  }
}
