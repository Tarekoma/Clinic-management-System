// ─────────────────────────────────────────────────────────────────────────────
// lib/viewmodels/settings_viewmodel.dart
//
// MVVM — ViewModel layer for all Settings features.
// The View (sheets + page) only calls methods here; zero business logic in UI.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:Hakim/errors/error_handler.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/services/settings_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════════════════════════════════════

class SettingsState {
  // ── Preferences ────────────────────────────────────────────────────────────
  final bool notifAppointments;
  final bool notifUrgent;
  final bool notifDailySummary;
  final String language;
  final bool darkMode;
  final double consultFee;
  final double revisitFee;

  // ── Assistants ─────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> assistants;
  final bool loadingAssistants;

  // ── Async feedback ─────────────────────────────────────────────────────────
  final bool isLoading;
  final bool exporting;
  final String? error;
  final String? successMessage;

  const SettingsState({
    this.notifAppointments = true,
    this.notifUrgent = true,
    this.notifDailySummary = false,
    this.language = 'English',
    this.darkMode = false,
    this.consultFee = 200.0,
    this.revisitFee = 100.0,
    this.assistants = const [],
    this.loadingAssistants = false,
    this.isLoading = false,
    this.exporting = false,
    this.error = null,
    this.successMessage = null,
  });

  SettingsState copyWith({
    bool? notifAppointments,
    bool? notifUrgent,
    bool? notifDailySummary,
    String? language,
    bool? darkMode,
    double? consultFee,
    double? revisitFee,
    List<Map<String, dynamic>>? assistants,
    bool? loadingAssistants,
    bool? isLoading,
    bool? exporting,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) => SettingsState(
    notifAppointments: notifAppointments ?? this.notifAppointments,
    notifUrgent: notifUrgent ?? this.notifUrgent,
    notifDailySummary: notifDailySummary ?? this.notifDailySummary,
    language: language ?? this.language,
    darkMode: darkMode ?? this.darkMode,
    consultFee: consultFee ?? this.consultFee,
    revisitFee: revisitFee ?? this.revisitFee,
    assistants: assistants ?? this.assistants,
    loadingAssistants: loadingAssistants ?? this.loadingAssistants,
    isLoading: isLoading ?? this.isLoading,
    exporting: exporting ?? this.exporting,
    error: clearError ? null : error ?? this.error,
    successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// VIEW MODEL
// ══════════════════════════════════════════════════════════════════════════════

class SettingsViewModel extends StateNotifier<SettingsState> {
  SettingsViewModel() : super(const SettingsState()) {
    loadPrefs();
  }

  // ── 1. Load all saved preferences ─────────────────────────────────────────

  Future<void> loadPrefs() async {
    try {
      final all = await SettingsService.loadAllPrefs();
      state = state.copyWith(
        notifAppointments: all['notif_appointments'] as bool,
        notifUrgent: all['notif_urgent'] as bool,
        notifDailySummary: all['notif_daily_summary'] as bool,
        language: all['language'] as String,
        darkMode: all['dark_mode'] as bool,
        consultFee: (all['consultation'] as num).toDouble(),
        revisitFee: (all['revisit'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('SettingsViewModel.loadPrefs: $e');
    }
  }

  // ── 2. Change password ────────────────────────────────────────────────────

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await ApiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password changed successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.friendlyMessage(e),
      );
      return false;
    }
  }

  // ── 3. Fetch linked assistants ────────────────────────────────────────────

  Future<void> fetchAssistants({
    required String clinicName,
    required String doctorId,
  }) async {
    state = state.copyWith(loadingAssistants: true, clearError: true);
    try {
      final all = await ApiService.getAssistants();
      final mine = all.cast<Map<String, dynamic>>().where((a) {
        final ac = (a['clinic_name'] ?? '').toString().toLowerCase();
        return ac == clinicName.toLowerCase() ||
            a['doctor_id']?.toString() == doctorId;
      }).toList();
      state = state.copyWith(assistants: mine, loadingAssistants: false);
    } catch (e) {
      state = state.copyWith(
        loadingAssistants: false,
        error: ErrorHandler.friendlyMessage(e),
      );
    }
  }

  // ── 4. Notification preferences ───────────────────────────────────────────

  Future<void> setNotifAppointments(bool value) async {
    state = state.copyWith(notifAppointments: value);
    await SettingsService.setBool('notif_appointments', value);
  }

  Future<void> setNotifUrgent(bool value) async {
    state = state.copyWith(notifUrgent: value);
    await SettingsService.setBool('notif_urgent', value);
  }

  Future<void> setNotifDailySummary(bool value) async {
    state = state.copyWith(notifDailySummary: value);
    await SettingsService.setBool('notif_daily_summary', value);
  }

  // ── 5. Appearance preferences ─────────────────────────────────────────────

  Future<void> setLanguage(String language) async {
    state = state.copyWith(
      language: language,
      successMessage: 'Language set to $language',
    );
    await SettingsService.setString('language', language);
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(
      darkMode: value,
      successMessage: value ? 'Dark mode enabled' : 'Light mode enabled',
    );
    await SettingsService.setBool('dark_mode', value);
  }

  // ── 6. Export ─────────────────────────────────────────────────────────────

  Future<bool> exportPatients(List<Map<String, dynamic>> patients) async {
    state = state.copyWith(exporting: true, clearError: true);
    try {
      final csv = _buildPatientsCsv(patients);
      await _shareFile(csv, 'patients');
      state = state.copyWith(exporting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        exporting: false,
        error: 'Export failed: ${ErrorHandler.friendlyMessage(e)}',
      );
      return false;
    }
  }

  Future<bool> exportAppointments(
    List<Map<String, dynamic>> appointments,
  ) async {
    state = state.copyWith(exporting: true, clearError: true);
    try {
      final csv = _buildAppointmentsCsv(appointments);
      await _shareFile(csv, 'appointments');
      state = state.copyWith(exporting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        exporting: false,
        error: 'Export failed: ${ErrorHandler.friendlyMessage(e)}',
      );
      return false;
    }
  }

  String _buildPatientsCsv(List<Map<String, dynamic>> patients) {
    final sb = StringBuffer();
    sb.writeln(
      'ID,First Name,Last Name,Phone,Gender,Date of Birth,Chronic Diseases',
    );
    for (final p in patients) {
      final diseases = (p['chronic_diseases'] as List? ?? []).join(' | ');
      sb.writeln(
        '${p['id']},'
        '"${p['first_name'] ?? ''}",'
        '"${p['last_name'] ?? ''}",'
        '${p['phone_number'] ?? ''},'
        '${p['gender'] ?? ''},'
        '${p['date_of_birth'] ?? ''},'
        '"$diseases"',
      );
    }
    return sb.toString();
  }

  String _buildAppointmentsCsv(List<Map<String, dynamic>> appointments) {
    final sb = StringBuffer();
    sb.writeln('ID,Patient,Date,Status,Type,Fee,Paid');
    for (final a in appointments) {
      final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
      final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
      final typeRaw = a['appointment_type'];
      final typeName = typeRaw is Map
          ? (typeRaw['name'] ?? '')
          : (typeRaw ?? '');
      sb.writeln(
        '${a['id']},'
        '"$fn $ln",'
        '${a['start_time'] ?? ''},'
        '${a['status'] ?? ''},'
        '$typeName,'
        '${a['fee'] ?? 0},'
        '${a['is_paid'] ?? false}',
      );
    }
    return sb.toString();
  }

  Future<void> _shareFile(String csv, String type) async {
    final dir = await getTemporaryDirectory();
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final file = File('${dir.path}/hakim_${type}_$date.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Hakim — ${type[0].toUpperCase()}${type.substring(1)} Export');
  }

  // ── 7. Default fees ───────────────────────────────────────────────────────

  Future<void> saveFees({
    required double consultFee,
    required double revisitFee,
    int? doctorId,
  }) async {
    // Persist locally so this device sees the new defaults immediately.
    await SettingsService.setConsultationFee(consultFee);
    await SettingsService.setRevisitFee(revisitFee);
    state = state.copyWith(
      consultFee: consultFee,
      revisitFee: revisitFee,
      successMessage: 'Default fees saved.',
    );

    // Sync to the backend appointment-types so every device (including the
    // assistant's) reads the updated default_fee from the API.
    // We track which categories were successfully PATCH'd (i.e. we own the
    // type — foreign types return 403 and are silently skipped).  Any category
    // that was never PATCH'd means no owned type exists yet, so we create one.
    // If create fails with 409 (type already exists under a different query
    // result page), we do a second targeted fetch and PATCH to recover.
    try {
      final types = await ApiService.getAppointmentTypes(doctorId: doctorId);
      debugPrint('💰 saveFees → doctorId=$doctorId  ${types.length} type(s)');
      bool consultPatched = false;
      bool revisitPatched = false;

      for (final raw in types) {
        final t = raw as Map<String, dynamic>;
        final id = int.tryParse((t['id'] ?? '').toString());
        if (id == null) continue;
        final name = (t['name'] ?? '').toString().toLowerCase();
        final isRevisit = name.contains('revisit') || name.contains('follow');
        try {
          await ApiService.updateAppointmentType(
            id,
            {'default_fee': isRevisit ? revisitFee : consultFee},
          );
          if (isRevisit) {
            revisitPatched = true;
          } else {
            consultPatched = true;
          }
          debugPrint(
            '💰 saveFees → PATCHed type $id "$name" '
            'fee=${isRevisit ? revisitFee : consultFee}',
          );
        } catch (e) {
          debugPrint('💰 saveFees → skipping type $id "$name": $e');
        }
      }

      // If a category has no owned type, create one.
      // If create returns 409 (type already exists but wasn't in the paged
      // result above), do a fresh fetch without doctorId filter and PATCH the
      // matching type — this handles the rare case where pagination hid it.
      if (!consultPatched) {
        bool created = false;
        try {
          await ApiService.createAppointmentType({
            'name': 'Consultation',
            'default_fee': consultFee,
          });
          created = true;
          debugPrint(
            '💰 saveFees → created Consultation type (fee=$consultFee)',
          );
        } catch (e) {
          debugPrint('💰 saveFees → Consultation create failed ($e) — retrying via fetch');
        }
        // Recovery: fetch all types and PATCH ours by name.
        if (!created) {
          try {
            final all = await ApiService.getAppointmentTypes();
            for (final raw in all) {
              final t = raw as Map<String, dynamic>;
              final n = (t['name'] ?? '').toString().toLowerCase();
              if (n.contains('consult') || n.contains('initial')) {
                final id = int.tryParse((t['id'] ?? '').toString());
                if (id == null) continue;
                try {
                  await ApiService.updateAppointmentType(
                    id,
                    {'default_fee': consultFee},
                  );
                  debugPrint(
                    '💰 saveFees → recovery: PATCHed Consultation type $id',
                  );
                  break;
                } catch (_) {}
              }
            }
          } catch (e) {
            debugPrint('💰 saveFees → recovery fetch failed: $e');
          }
        }
      }

      if (!revisitPatched) {
        bool created = false;
        try {
          await ApiService.createAppointmentType({
            'name': 'Revisit',
            'default_fee': revisitFee,
          });
          created = true;
          debugPrint('💰 saveFees → created Revisit type (fee=$revisitFee)');
        } catch (e) {
          debugPrint('💰 saveFees → Revisit create failed ($e) — retrying via fetch');
        }
        if (!created) {
          try {
            final all = await ApiService.getAppointmentTypes();
            for (final raw in all) {
              final t = raw as Map<String, dynamic>;
              final n = (t['name'] ?? '').toString().toLowerCase();
              if (n.contains('revisit') || n.contains('follow')) {
                final id = int.tryParse((t['id'] ?? '').toString());
                if (id == null) continue;
                try {
                  await ApiService.updateAppointmentType(
                    id,
                    {'default_fee': revisitFee},
                  );
                  debugPrint(
                    '💰 saveFees → recovery: PATCHed Revisit type $id',
                  );
                  break;
                } catch (_) {}
              }
            }
          } catch (e) {
            debugPrint('💰 saveFees → recovery fetch failed: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('💰 saveFees → backend sync failed: $e');
    }
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
