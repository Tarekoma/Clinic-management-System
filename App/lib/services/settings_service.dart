// ─────────────────────────────────────────────────────────────────────────────
// lib/services/settings_service.dart
//
// Persists clinic-level UI preferences (fee defaults, etc.) locally.
// Uses shared_preferences — no backend call needed for these values.
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

  // ── Write ───────────────────────────────────────────────────────────────────

  static Future<void> setConsultationFee(double fee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyConsultFee, fee);
  }

  static Future<void> setRevisitFee(double fee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRevisitFee, fee);
  }

  // ── Load both at once (used in form initState) ───────────────────────────────

  static Future<Map<String, double>> loadFeeDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'consultation': prefs.getDouble(_keyConsultFee) ?? 200.0,
      'revisit': prefs.getDouble(_keyRevisitFee) ?? 100.0,
    };
  }
}
