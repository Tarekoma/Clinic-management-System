// ─────────────────────────────────────────────────────────────────────────────
// lib/services/settings_service.dart
//
// Persists clinic-level UI preferences (fee defaults, etc.) locally.
// Uses shared_preferences — no backend call needed for these values.
//
// CHANGE: added getString() — a generic string reader used by
// locale_provider.dart to restore the saved language on app start.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyConsultFee = 'default_fee_consultation';
  static const _keyRevisitFee = 'default_fee_revisit';

  // ── Read ────────────────────────────────────────────────────────────────────

  static Future<double> getConsultationFee({double fallback = 200.0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyConsultFee) ?? fallback;
  }

  static Future<double> getRevisitFee({double fallback = 100.0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyRevisitFee) ?? fallback;
  }

  /// Generic string reader — used by locale_provider.dart (and anything else
  /// that just needs a single saved string value back).
  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // ── Write ───────────────────────────────────────────────────────────────────

  static Future<void> setConsultationFee(double fee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyConsultFee, fee);
  }

  static Future<void> setRevisitFee(double fee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRevisitFee, fee);
  }

  // ── Generic helpers (used by settings page) ─────────────────────────────────

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Loads all app-level preferences in one shot.
  /// Used by DoctorSettingsPage on open so it can populate all toggles.
  static Future<Map<String, dynamic>> loadAllPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'consultation': prefs.getDouble(_keyConsultFee) ?? 200.0,
      'revisit': prefs.getDouble(_keyRevisitFee) ?? 100.0,
      'language': prefs.getString('language') ?? 'English',
      'dark_mode': prefs.getBool('dark_mode') ?? false,
      'notif_appointments': prefs.getBool('notif_appointments') ?? true,
      'notif_urgent': prefs.getBool('notif_urgent') ?? true,
      'notif_daily_summary': prefs.getBool('notif_daily_summary') ?? false,
    };
  }

  // ── Navigation tab persistence ──────────────────────────────────────────────
  // Keyed by role string ('doctor', 'assistant', 'admin').
  // Written on every tab tap; read once during cold-start resolution so that
  // after a process-death restart the user lands on the same tab they left.

  static Future<int> getLastTab(String role, {int fallback = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('nav_last_tab_$role') ?? fallback;
  }

  static Future<void> setLastTab(String role, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nav_last_tab_$role', index);
  }

  // ── Load both at once (used in form initState) ─────────────────────────────
  static Future<Map<String, double>> loadFeeDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'consultation': prefs.getDouble(_keyConsultFee) ?? 200.0,
      'revisit': prefs.getDouble(_keyRevisitFee) ?? 100.0,
    };
  }
}
