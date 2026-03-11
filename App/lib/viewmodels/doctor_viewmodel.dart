// ─────────────────────────────────────────────────────────────────────────────
// lib/viewmodels/doctor_viewmodel.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:Hakim/services/API_Service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/services/AI_Service.dart';
import 'package:image_picker/image_picker.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════════════════════════════════════

class DoctorState {
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> appointmentTypes;
  final List<Map<String, dynamic>> reports;
  final int? doctorId;

  final bool loadingPatients;
  final bool loadingAppointments;

  final bool patientsError;
  final bool appointmentsError;

  final String patientSearchQuery;
  final String apptSearchQuery;

  final Map<String, dynamic>? lastCreatedPatient;

  const DoctorState({
    this.patients = const [],
    this.appointments = const [],
    this.appointmentTypes = const [],
    this.reports = const [],
    this.doctorId,
    this.loadingPatients = false,
    this.loadingAppointments = false,
    this.patientsError = false,
    this.appointmentsError = false,
    this.patientSearchQuery = '',
    this.apptSearchQuery = '',
    this.lastCreatedPatient,
  });

  DoctorState copyWith({
    List<Map<String, dynamic>>? patients,
    List<Map<String, dynamic>>? appointments,
    List<Map<String, dynamic>>? appointmentTypes,
    List<Map<String, dynamic>>? reports,
    int? doctorId,
    bool? loadingPatients,
    bool? loadingAppointments,
    bool? patientsError,
    bool? appointmentsError,
    String? patientSearchQuery,
    String? apptSearchQuery,
    Map<String, dynamic>? lastCreatedPatient,
    bool eraseLastCreatedPatient = false,
  }) {
    return DoctorState(
      patients: patients ?? this.patients,
      appointments: appointments ?? this.appointments,
      appointmentTypes: appointmentTypes ?? this.appointmentTypes,
      reports: reports ?? this.reports,
      doctorId: doctorId ?? this.doctorId,
      loadingPatients: loadingPatients ?? this.loadingPatients,
      loadingAppointments: loadingAppointments ?? this.loadingAppointments,
      patientsError: patientsError ?? this.patientsError,
      appointmentsError: appointmentsError ?? this.appointmentsError,
      patientSearchQuery: patientSearchQuery ?? this.patientSearchQuery,
      apptSearchQuery: apptSearchQuery ?? this.apptSearchQuery,
      lastCreatedPatient: eraseLastCreatedPatient
          ? null
          : (lastCreatedPatient ?? this.lastCreatedPatient),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VIEW MODEL
// ══════════════════════════════════════════════════════════════════════════════

class DoctorViewModel extends StateNotifier<DoctorState> {
  DoctorViewModel() : super(const DoctorState());

  // ── Bootstrap ──────────────────────────────────────────────────────────────

  Future<void> loadAll() => Future.wait([fetchPatients(), fetchAppointments()]);

  void setDoctorId(int id) {
    if (id > 0) state = state.copyWith(doctorId: id);
  }

  // ── Patients ───────────────────────────────────────────────────────────────

  Future<void> fetchPatients() async {
    state = state.copyWith(loadingPatients: true, patientsError: false);
    try {
      final d = await ApiService.getPatients();
      state = state.copyWith(
        patients: List<Map<String, dynamic>>.from(d),
        loadingPatients: false,
      );
    } catch (_) {
      state = state.copyWith(loadingPatients: false, patientsError: true);
    }
  }

  Future<void> createOrUpdatePatient(
    Map<String, dynamic> data, {
    int? existingId,
  }) async {
    final newDiseases = List<String>.from(
      data.remove('chronic_diseases') ?? [],
    );

    if (existingId != null) {
      await ApiService.updatePatient(existingId, data);
      await _syncPatientConditions(
        patientId: existingId,
        newDiseaseNames: newDiseases,
      );
      state = state.copyWith(eraseLastCreatedPatient: true);
    } else {
      final created = await ApiService.createPatient(data);
      if (created is Map<String, dynamic>) {
        state = state.copyWith(
          lastCreatedPatient: Map<String, dynamic>.from(created),
        );
      }
    }
    await fetchPatients();
  }

  void clearLastCreatedPatient() {
    state = state.copyWith(eraseLastCreatedPatient: true);
  }

  Future<void> _syncPatientConditions({
    required int patientId,
    required List<String> newDiseaseNames,
  }) async {
    try {
      final catalog = List<Map<String, dynamic>>.from(
        await ApiService.getConditions(),
      );

      final patient = state.patients.firstWhere(
        (p) => p['id'].toString() == patientId.toString(),
        orElse: () => {},
      );
      final currentDiseases = List<String>.from(
        patient['chronic_diseases'] ?? [],
      );

      final added = newDiseaseNames
          .where(
            (n) =>
                !currentDiseases.any((c) => c.toLowerCase() == n.toLowerCase()),
          )
          .toList();

      final removed = currentDiseases
          .where(
            (c) =>
                !newDiseaseNames.any((n) => n.toLowerCase() == c.toLowerCase()),
          )
          .toList();

      for (final name in added) {
        final match = catalog.firstWhere(
          (c) =>
              (c['name'] ?? '').toString().toLowerCase().contains(
                name.toLowerCase(),
              ) ||
              name.toLowerCase().contains(
                (c['name'] ?? '').toString().toLowerCase(),
              ),
          orElse: () => {},
        );
        if (match.isNotEmpty && match['id'] != null) {
          try {
            await ApiService.assignCondition(
              patientId,
              int.parse(match['id'].toString()),
              '',
            );
          } catch (_) {}
        }
      }

      for (final name in removed) {
        final match = catalog.firstWhere(
          (c) =>
              (c['name'] ?? '').toString().toLowerCase().contains(
                name.toLowerCase(),
              ) ||
              name.toLowerCase().contains(
                (c['name'] ?? '').toString().toLowerCase(),
              ),
          orElse: () => {},
        );
        if (match.isNotEmpty && match['id'] != null) {
          try {
            await ApiService.removeCondition(
              patientId,
              int.parse(match['id'].toString()),
            );
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> deletePatient(int id) async {
    await ApiService.deletePatient(id);
    await fetchPatients();
  }

  // FIX: was ApiService.getPatientReports — correct method is getMedicalReports
  Future<void> fetchReports(int patientId) async {
    try {
      final d = await ApiService.getMedicalReports(patientId: patientId);
      state = state.copyWith(reports: List<Map<String, dynamic>>.from(d));
    } catch (_) {}
  }

  // FIX: was ApiService.getPatientVisits — correct method is getVisits
  Future<List<Map<String, dynamic>>> fetchVisits(int patientId) async {
    try {
      final d = await ApiService.getVisits(patientId: patientId);
      return List<Map<String, dynamic>>.from(d);
    } catch (_) {
      return [];
    }
  }

  Future<void> assignCondition(
    int patientId,
    int conditionId,
    String notes,
  ) async {
    await ApiService.assignCondition(patientId, conditionId, notes);
    await fetchPatients();
  }

  Future<void> removeCondition(int patientId, int conditionId) async {
    await ApiService.removeCondition(patientId, conditionId);
    await fetchPatients();
  }

  // ── Appointments ───────────────────────────────────────────────────────────

  Future<void> fetchAppointments() async {
    state = state.copyWith(loadingAppointments: true, appointmentsError: false);
    try {
      final d = await ApiService.getAppointments();
      final list = List<Map<String, dynamic>>.from(d);
      list.sort((a, b) {
        final da = parseDate(a['start_time']);
        final db = parseDate(b['start_time']);
        return (da ?? DateTime.now()).compareTo(db ?? DateTime.now());
      });
      state = state.copyWith(appointments: list, loadingAppointments: false);
    } catch (_) {
      state = state.copyWith(
        loadingAppointments: false,
        appointmentsError: true,
      );
    }
  }

  Future<void> fetchAppointmentTypes() async {
    try {
      final d = await ApiService.getAppointmentTypes();
      state = state.copyWith(
        appointmentTypes: List<Map<String, dynamic>>.from(d),
      );
    } catch (_) {}
  }

  Future<void> updateAppointmentStatus(int id, String status) async {
    await ApiService.updateAppointmentStatus(id, status);
    await fetchAppointments();
  }

  Future<void> deleteAppointment(int id) async {
    await ApiService.deleteAppointment(id);
    await fetchAppointments();
  }

  Future<void> createOrUpdateAppointment(
    Map<String, dynamic> data, {
    int? existingId,
  }) async {
    if (existingId != null) {
      await ApiService.updateAppointment(existingId, data);
    } else {
      await ApiService.createAppointment(data);
    }
    await fetchAppointments();
  }

  // ── Consultation operations ────────────────────────────────────────────────

  Future<Map<String, dynamic>> startVisit(Map<String, dynamic> data) async {
    return ApiService.startVisit(data);
  }

  Future<String> transcribeAudio({
    required File audioFile,
    required int visitId,
  }) async {
    final r = await ApiService.transcribeAudio(
      audioFile: audioFile,
      visitId: visitId,
    );
    return r['transcription'] ?? r['text'] ?? r['content'] ?? '';
  }

  Future<Map<String, String>> pickAndAnalyzeImage(ImageSource source) async {
    final file = await AIService.pickImage(source: source);
    if (file == null) return {'error': 'cancelled'};
    final r = await AIService.scanMedicalImage(file);
    if (r['error'] != null) return {'error': r['error'].toString()};
    return {
      'file_path': file.path,
      'findings': r['findings']?.toString() ?? 'No findings',
      'severity': r['severity']?.toString() ?? '',
    };
  }

  Future<void> uploadMedicalImage({
    required File imageFile,
    required int visitId,
    required String imageType,
    required String description,
  }) async {
    await ApiService.uploadMedicalImage(
      imageFile: imageFile,
      visitId: visitId,
      imageType: imageType,
      description: description,
    );
  }

  Future<void> createMedicalReport(Map<String, dynamic> data) async {
    await ApiService.createMedicalReport(data);
  }

  Future<void> updateVisitStatus(int visitId, String status) async {
    await ApiService.updateVisitStatus(visitId, status);
  }

  String generateAISuggestion({
    required String complaint,
    required List<String> symptoms,
    required String exam,
  }) {
    final syms = symptoms.join(', ');
    return 'Based on the clinical presentation:\n'
        '${complaint.isNotEmpty ? "• Chief Complaint: $complaint\n" : ""}'
        '${syms.isNotEmpty ? "• Symptoms: $syms\n" : ""}'
        '${exam.isNotEmpty ? "• Examination: $exam\n" : ""}'
        '\nConsiderations:\n'
        '• Review patient history and previous visits\n'
        '• Consider relevant differential diagnoses\n'
        '• Order lab tests if clinically indicated\n'
        '• Schedule follow-up in 1–2 weeks\n\n'
        '⚠️ AI suggestions are advisory only. Clinical judgment prevails.';
  }

  // ── Search helpers ─────────────────────────────────────────────────────────

  void setPatientSearch(String q) =>
      state = state.copyWith(patientSearchQuery: q.toLowerCase().trim());

  void setApptSearch(String q) =>
      state = state.copyWith(apptSearchQuery: q.toLowerCase().trim());

  // ── Computed: patients ─────────────────────────────────────────────────────

  List<Map<String, dynamic>> get filteredPatients {
    final q = state.patientSearchQuery;
    if (q.isEmpty) return state.patients;
    return state.patients.where((p) {
      final nm = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
          .toLowerCase();
      final ph = (p['phone'] ?? '').toString().toLowerCase();
      final nid = (p['national_id'] ?? '').toString().toLowerCase();
      return nm.contains(q) || ph.contains(q) || nid.contains(q);
    }).toList();
  }

  // ── Computed: appointments ─────────────────────────────────────────────────

  List<Map<String, dynamic>> filteredAppointments(DoctorApptFilter filter) {
    final q = state.apptSearchQuery;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return state.appointments.where((a) {
      final dt = parseDate(a['start_time']);
      final day = dt != null ? DateTime(dt.year, dt.month, dt.day) : null;
      final s = (a['status'] ?? '').toUpperCase();

      bool ok = switch (filter) {
        DoctorApptFilter.all => true,
        DoctorApptFilter.today => day == today,
        DoctorApptFilter.upcoming =>
          dt != null && dt.isAfter(now) && s != 'CANCELLED',
        DoctorApptFilter.urgent => a['is_urgent'] == true,
        DoctorApptFilter.completed => s == 'COMPLETED',
      };
      if (!ok) return false;
      if (q.isNotEmpty) return apptName(a).toLowerCase().contains(q);
      return true;
    }).toList();
  }

  int apptFilterCount(DoctorApptFilter filter) =>
      filteredAppointments(filter).length;

  // ── Computed: finance ──────────────────────────────────────────────────────

  Map<String, double> get financeStats {
    double total = 0, paid = 0;
    for (final a in state.appointments) {
      if ((a['status'] ?? '').toUpperCase() == 'CANCELLED') continue;
      final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0;
      total += fee;
      if (a['is_paid'] == true) paid += fee;
    }
    return {'total': total, 'paid': paid, 'unpaid': total - paid};
  }

  List<Map<String, dynamic>> billableAppointments({bool unpaidOnly = false}) {
    final list =
        state.appointments
            .where((a) => (a['status'] ?? '').toUpperCase() != 'CANCELLED')
            .toList()
          ..sort(
            (a, b) => (parseDate(b['start_time']) ?? DateTime.now()).compareTo(
              parseDate(a['start_time']) ?? DateTime.now(),
            ),
          );
    return unpaidOnly ? list.where((a) => a['is_paid'] != true).toList() : list;
  }

  // ── Computed: dashboard ────────────────────────────────────────────────────

  List<Map<String, dynamic>> get todayAppointments {
    final now = DateTime.now();
    return state.appointments.where((a) {
      final dt = parseDate(a['start_time']);
      if (dt == null) return false;
      return dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day &&
          (a['status'] ?? '').toUpperCase() != 'CANCELLED';
    }).toList()..sort(
      (a, b) => (parseDate(a['start_time']) ?? DateTime.now()).compareTo(
        parseDate(b['start_time']) ?? DateTime.now(),
      ),
    );
  }

  Map<String, dynamic>? get nextAppointment {
    final now = DateTime.now();
    final upcoming =
        state.appointments.where((a) {
          final dt = parseDate(a['start_time']);
          if (dt == null) return false;
          final s = (a['status'] ?? '').toUpperCase();
          return dt.isAfter(now) && (s == 'SCHEDULED' || s == 'IN_PROGRESS');
        }).toList()..sort(
          (a, b) => parseDate(
            a['start_time'],
          )!.compareTo(parseDate(b['start_time'])!),
        );
    return upcoming.isEmpty ? null : upcoming.first;
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await ApiService.logout();
  }

  // ── Utility helpers ────────────────────────────────────────────────────────

  String apptName(Map<String, dynamic> a) {
    final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
    final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
    final full = '$fn $ln'.trim();
    return full.isEmpty ? 'Unknown Patient' : full;
  }

  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String toIso8601WithTz(DateTime dt) => dt.toUtc().toIso8601String();

  static String extractError(Object e) => ApiService.extractError(e);
}

// ══════════════════════════════════════════════════════════════════════════════
// APPOINTMENT FILTER ENUM
// ══════════════════════════════════════════════════════════════════════════════

enum DoctorApptFilter { all, today, upcoming, urgent, completed }
