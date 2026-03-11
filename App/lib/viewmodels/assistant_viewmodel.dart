// ─────────────────────────────────────────────────────────────────────────────
// lib/viewmodels/assistant_viewmodel.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/services/API_Service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════════════════════════════════════

class AssistantState {
  // Raw server data
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> doctors;
  final List<Map<String, dynamic>> appointmentTypes;

  // Loading flags
  final bool loadingPatients;
  final bool loadingAppointments;

  // Error flags
  final bool patientsError;
  final bool appointmentsError;

  // Active doctor selected in the header switch
  final Map<String, dynamic>? activeDoctor;

  // Search queries (set by view, consumed by computed getters)
  final String patientSearchQuery;
  final String apptSearchQuery;

  // ── NEW ──────────────────────────────────────────────────────────────────────
  // Holds the API response for the most recently CREATED patient.
  // Set by createOrUpdatePatient (new only), cleared by clearLastCreatedPatient.
  // The patients page reads this after the form sheet closes to auto-open the
  // appointment form with the patient already selected.
  final Map<String, dynamic>? lastCreatedPatient;
  // ─────────────────────────────────────────────────────────────────────────────

  const AssistantState({
    this.patients = const [],
    this.appointments = const [],
    this.doctors = const [],
    this.appointmentTypes = const [],
    this.loadingPatients = false,
    this.loadingAppointments = false,
    this.patientsError = false,
    this.appointmentsError = false,
    this.activeDoctor,
    this.patientSearchQuery = '',
    this.apptSearchQuery = '',
    this.lastCreatedPatient, // defaults to null
  });

  // ── copyWith ─────────────────────────────────────────────────────────────────
  // Uses an explicit `eraseLastCreatedPatient` flag so the caller can set the
  // field to null without the usual `?? this.x` idiom hiding the intent.
  AssistantState copyWith({
    List<Map<String, dynamic>>? patients,
    List<Map<String, dynamic>>? appointments,
    List<Map<String, dynamic>>? doctors,
    List<Map<String, dynamic>>? appointmentTypes,
    bool? loadingPatients,
    bool? loadingAppointments,
    bool? patientsError,
    bool? appointmentsError,
    Map<String, dynamic>? activeDoctor,
    String? patientSearchQuery,
    String? apptSearchQuery,
    // ── NEW ──
    Map<String, dynamic>? lastCreatedPatient,
    bool eraseLastCreatedPatient = false,
  }) {
    return AssistantState(
      patients: patients ?? this.patients,
      appointments: appointments ?? this.appointments,
      doctors: doctors ?? this.doctors,
      appointmentTypes: appointmentTypes ?? this.appointmentTypes,
      loadingPatients: loadingPatients ?? this.loadingPatients,
      loadingAppointments: loadingAppointments ?? this.loadingAppointments,
      patientsError: patientsError ?? this.patientsError,
      appointmentsError: appointmentsError ?? this.appointmentsError,
      activeDoctor: activeDoctor ?? this.activeDoctor,
      patientSearchQuery: patientSearchQuery ?? this.patientSearchQuery,
      apptSearchQuery: apptSearchQuery ?? this.apptSearchQuery,
      // If eraseLastCreatedPatient is true, force null; otherwise keep or set.
      lastCreatedPatient: eraseLastCreatedPatient
          ? null
          : (lastCreatedPatient ?? this.lastCreatedPatient),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VIEW MODEL
// ══════════════════════════════════════════════════════════════════════════════

class AssistantViewModel extends StateNotifier<AssistantState> {
  AssistantViewModel() : super(const AssistantState()) {
    loadAll();
  }

  // ── Initial load ────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    await Future.wait([
      fetchPatients(),
      fetchAppointmentTypes(),
      fetchDoctors(),
    ]);
    await fetchAppointments();
  }

  // ── Data fetchers ───────────────────────────────────────────────────────────

  Future<void> fetchPatients({String search = ''}) async {
    state = state.copyWith(loadingPatients: true, patientsError: false);
    try {
      final data = await ApiService.getPatients(search: search);
      state = state.copyWith(
        patients: List<Map<String, dynamic>>.from(data),
        loadingPatients: false,
      );
    } catch (_) {
      state = state.copyWith(loadingPatients: false, patientsError: true);
      rethrow;
    }
  }

  Future<void> fetchAppointments() async {
    state = state.copyWith(loadingAppointments: true, appointmentsError: false);
    try {
      final activeDoctorId = state.activeDoctor != null
          ? int.tryParse(state.activeDoctor!['id'].toString())
          : null;
      final data = await ApiService.getAppointments(doctorId: activeDoctorId);
      final list = List<Map<String, dynamic>>.from(data);
      list.sort((a, b) {
        final da = _parseDate(a['start_time']);
        final db = _parseDate(b['start_time']);
        return (da ?? DateTime.now()).compareTo(db ?? DateTime.now());
      });
      state = state.copyWith(appointments: list, loadingAppointments: false);
    } catch (_) {
      state = state.copyWith(
        loadingAppointments: false,
        appointmentsError: true,
      );
      rethrow;
    }
  }

  Future<void> fetchAppointmentTypes() async {
    try {
      final data = await ApiService.getAppointmentTypes();
      state = state.copyWith(
        appointmentTypes: List<Map<String, dynamic>>.from(data),
      );
    } catch (e) {
      print('⚠️ fetchAppointmentTypes failed: $e — leaving list empty');
      state = state.copyWith(appointmentTypes: const []);
    }
  }

  Future<void> fetchDoctors() async {
    try {
      final data = await ApiService.getDoctors();
      final list = List<Map<String, dynamic>>.from(data);
      state = state.copyWith(
        doctors: list,
        activeDoctor:
            state.activeDoctor ?? (list.isNotEmpty ? list.first : null),
      );
    } catch (_) {
      // silent
    }
  }

  Future<void> setActiveDoctor(Map<String, dynamic> doctor) async {
    state = state.copyWith(activeDoctor: doctor);
    await fetchAppointments();
  }

  // ── Appointment actions ─────────────────────────────────────────────────────

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

  Future<void> togglePayment(int id, {required bool currentlyPaid}) async {
    await ApiService.updateAppointment(id, {'is_paid': !currentlyPaid});
    await fetchAppointments();
  }

  // ── Patient actions ─────────────────────────────────────────────────────────

  /// Create (existingId == null) or update (existingId != null) a patient.
  ///
  /// NEW BEHAVIOUR on creation:
  /// The API response is stored in [AssistantState.lastCreatedPatient].
  /// The patients page reads this after the form sheet closes and, if set,
  /// automatically opens the appointment form with that patient pre-selected.
  /// Call [clearLastCreatedPatient] once the value has been consumed.
  Future<void> createOrUpdatePatient(
    Map<String, dynamic> data, {
    int? existingId,
  }) async {
    if (existingId != null) {
      // Update — no auto-open behaviour; clear any stale value.
      await ApiService.updatePatient(existingId, data);
      state = state.copyWith(eraseLastCreatedPatient: true);
    } else {
      // Create — capture the API response so the view can open the appt form.
      final created = await ApiService.createPatient(data);
      if (created is Map<String, dynamic>) {
        state = state.copyWith(
          lastCreatedPatient: Map<String, dynamic>.from(created),
        );
      }
    }
    await fetchPatients();
  }

  /// Call this after the patients page has consumed [lastCreatedPatient].
  void clearLastCreatedPatient() {
    state = state.copyWith(eraseLastCreatedPatient: true);
  }

  Future<void> deletePatient(int id) async {
    await ApiService.deletePatient(id);
    await fetchPatients();
  }

  // ── Search ──────────────────────────────────────────────────────────────────

  void setApptSearch(String q) => state = state.copyWith(apptSearchQuery: q);

  void setPatientSearch(String q) =>
      state = state.copyWith(patientSearchQuery: q);

  // ── Computed lists ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get filteredPatients {
    final q = state.patientSearchQuery.toLowerCase().trim();
    if (q.isEmpty) return state.patients;
    return state.patients.where((p) {
      final nm = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
          .toLowerCase();
      final ph = (p['phone'] ?? '').toString().toLowerCase();
      final nid = (p['national_id'] ?? '').toString().toLowerCase();
      return nm.contains(q) || ph.contains(q) || nid.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredAppointments {
    final q = state.apptSearchQuery.toLowerCase().trim();
    if (q.isEmpty) return state.appointments;
    return state.appointments.where((a) {
      final nm = apptName(a).toLowerCase();
      final ph = (a['patient']?['phone'] ?? '').toString().toLowerCase();
      final nid = (a['patient']?['national_id'] ?? '').toString().toLowerCase();
      return nm.contains(q) || ph.contains(q) || nid.contains(q);
    }).toList();
  }

  // ── Payment stats ───────────────────────────────────────────────────────────

  Map<String, double> paymentStats() {
    double total = 0, paid = 0;
    for (final a in state.appointments) {
      if ((a['status'] ?? '').toUpperCase() == 'CANCELLED') continue;
      final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0.0;
      total += fee;
      if (a['is_paid'] == true) paid += fee;
    }
    return {'total': total, 'paid': paid, 'unpaid': total - paid};
  }

  // ── Utility helpers ─────────────────────────────────────────────────────────

  String patName(Map<String, dynamic> p) =>
      '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();

  String apptName(Map<String, dynamic> a) {
    if (a['patient_name'] != null) return a['patient_name'].toString();
    final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
    final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
    final full = '$fn $ln'.trim();
    return full.isEmpty ? 'Unknown Patient' : full;
  }

  DateTime? parseDate(dynamic v) => _parseDate(v);

  static String toIso8601WithTz(DateTime dt) {
    final tz = dt.timeZoneOffset;
    final sign = tz.isNegative ? '-' : '+';
    final hh = tz.inHours.abs().toString().padLeft(2, '0');
    final mm = (tz.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${DateFormat("yyyy-MM-ddTHH:mm:ss").format(dt)}$sign$hh:$mm';
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await ApiService.logout();
  }

  // ── Error extraction ─────────────────────────────────────────────────────────

  static String extractError(Object e) => ApiService.extractError(e);
}
