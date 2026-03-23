// ─────────────────────────────────────────────────────────────────────────────
// lib/viewmodels/assistant_viewmodel.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════════════════════════════════════

class AssistantState {
  final List<Map<String, dynamic>> doctors;
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> appointmentTypes;
  final bool loadingPatients;
  final bool loadingAppointments;
  final bool patientsError;
  final bool appointmentsError;
  final Map<String, dynamic>? activeDoctor;
  final String patientSearchQuery;
  final String apptSearchQuery;
  final Map<String, dynamic>? lastCreatedPatient;

  const AssistantState({
    this.doctors = const [],
    this.patients = const [],
    this.appointments = const [],
    this.appointmentTypes = const [],
    this.loadingPatients = false,
    this.loadingAppointments = false,
    this.patientsError = false,
    this.appointmentsError = false,
    this.activeDoctor,
    this.patientSearchQuery = '',
    this.apptSearchQuery = '',
    this.lastCreatedPatient,
  });

  AssistantState copyWith({
    List<Map<String, dynamic>>? doctors,
    List<Map<String, dynamic>>? patients,
    List<Map<String, dynamic>>? appointments,
    List<Map<String, dynamic>>? appointmentTypes,
    bool? loadingPatients,
    bool? loadingAppointments,
    bool? patientsError,
    bool? appointmentsError,
    Map<String, dynamic>? activeDoctor,
    String? patientSearchQuery,
    String? apptSearchQuery,
    Map<String, dynamic>? lastCreatedPatient,
    bool eraseLastCreatedPatient = false,
  }) {
    return AssistantState(
      doctors: doctors ?? this.doctors,
      patients: patients ?? this.patients,
      appointments: appointments ?? this.appointments,
      appointmentTypes: appointmentTypes ?? this.appointmentTypes,
      loadingPatients: loadingPatients ?? this.loadingPatients,
      loadingAppointments: loadingAppointments ?? this.loadingAppointments,
      patientsError: patientsError ?? this.patientsError,
      appointmentsError: appointmentsError ?? this.appointmentsError,
      activeDoctor: activeDoctor ?? this.activeDoctor,
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

class AssistantViewModel extends StateNotifier<AssistantState> {
  AssistantViewModel()
    : super(
        const AssistantState(loadingPatients: true, loadingAppointments: true),
      );

  // The linked doctor's PK — resolved once and cached for the session.
  int? _linkedDoctorId;
  String _initEmail = '';

  // ══════════════════════════════════════════════════════════════════════════
  // ENTRY POINT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> initForAssistant(UserProfile profile) async {
    // Re-entrancy guard: skip resolution if already done for this user.
    if (_linkedDoctorId != null && _initEmail == profile.email) {
      await loadAll();
      return;
    }

    _initEmail = profile.email;
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 AssistantVM.initForAssistant');
    print('   email     : ${profile.email}');
    print('   clinicName: ${profile.clinicName}');
    print('   doctorId  : ${profile.doctorId}');
    print('   doctorEmail: ${profile.doctorEmail}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    state = state.copyWith(loadingPatients: true, loadingAppointments: true);

    // ── Resolution: find the linked doctor's PK ──────────────────────────
    // Three independent sources tried in order.  Each one logs what it finds
    // so the exact failure point is visible in the console.

    int? doctorId;
    Map<String, dynamic>? doctorMap;

    // ── Source 1: profile.doctorId (set from u['doctor_id'] at login) ────
    final profileDocId = int.tryParse((profile.doctorId ?? '').trim());
    if (profileDocId != null && profileDocId > 0) {
      doctorId = profileDocId;
      print('✅ Source 1: profile.doctorId=$doctorId');
    } else {
      print('   Source 1: profile.doctorId empty — trying Source 2');
    }

    // ── Source 2: fetch own assistant record, read doctor_id field ───────
    if (doctorId == null) {
      try {
        final list = await ApiService.getAssistants();
        print('   getAssistants() → ${list.length} records');

        final myEmail = profile.email.trim().toLowerCase();
        Map<String, dynamic>? myRecord;
        for (final a in list) {
          if ((a['email'] ?? '').toString().trim().toLowerCase() == myEmail) {
            myRecord = Map<String, dynamic>.from(a as Map);
            break;
          }
        }

        if (myRecord != null) {
          // Log ALL fields so we can see the exact key name the backend uses
          print('   📋 My assistant record: $myRecord');

          // Try all common field names the backend might use
          final raw =
              myRecord['doctor_id'] ??
              myRecord['linked_doctor_id'] ??
              myRecord['doctor']?['id'];
          doctorId = int.tryParse((raw ?? '').toString());

          if (doctorId != null && doctorId > 0) {
            print('✅ Source 2: assistant.doctor_id=$doctorId');
            // Try to also get doctor map if nested
            if (myRecord['doctor'] is Map) {
              doctorMap = Map<String, dynamic>.from(myRecord['doctor'] as Map);
            }
          } else {
            print('   ⚠️  Source 2: doctor_id field absent or zero in record');
          }
        } else {
          print('   ⚠️  Source 2: no record found for email=$myEmail');
        }
      } catch (e) {
        print('   ❌ Source 2 failed: $e');
      }
    }

    // ── Source 3: getDoctors() filtered by clinic_name ───────────────────
    if (doctorId == null) {
      print('   Source 3: clinic_name filter on getDoctors()...');
      try {
        final docs = await ApiService.getDoctors();
        print('   getDoctors() → ${docs.length} records');
        for (final d in docs) {
          print(
            '     doctor id=${d["id"]} clinic="${d["clinic_name"]}" '
            'email="${d["email"]}" name=${d["first_name"]}',
          );
        }

        final clinic = (profile.clinicName ?? '').trim().toLowerCase();
        if (clinic.isNotEmpty) {
          final matches = docs
              .where(
                (d) =>
                    (d['clinic_name'] ?? '').toString().trim().toLowerCase() ==
                    clinic,
              )
              .toList();
          print('   clinic="$clinic" → ${matches.length} match(es)');

          if (matches.length == 1) {
            final d = Map<String, dynamic>.from(matches.first as Map);
            doctorId = int.tryParse((d['id'] ?? '').toString());
            doctorMap = d;
            print('✅ Source 3: unique clinic match id=$doctorId');
          } else if (matches.length > 1) {
            // Multiple doctors share this clinic — pick by doctorEmail if available
            final docEmail = (profile.doctorEmail ?? '').toLowerCase();
            if (docEmail.isNotEmpty) {
              final em =
                  matches.firstWhere(
                        (d) =>
                            (d['email'] ?? '').toString().toLowerCase() ==
                            docEmail,
                        orElse: () => <String, dynamic>{},
                      )
                      as Map<String, dynamic>;
              if (em.isNotEmpty) {
                doctorId = int.tryParse((em['id'] ?? '').toString());
                doctorMap = Map<String, dynamic>.from(em);
                print(
                  '✅ Source 3: email match among clinic doctors id=$doctorId',
                );
              } else {
                print(
                  '   ⚠️  Source 3: ${matches.length} clinic matches, '
                  'no email match — picking first as best guess',
                );
                final d = Map<String, dynamic>.from(matches.first as Map);
                doctorId = int.tryParse((d['id'] ?? '').toString());
                doctorMap = d;
              }
            } else {
              print(
                '   ⚠️  Source 3: ${matches.length} clinic matches, '
                'no doctorEmail — picking first',
              );
              final d = Map<String, dynamic>.from(matches.first as Map);
              doctorId = int.tryParse((d['id'] ?? '').toString());
              doctorMap = d;
            }
          }
        }
      } catch (e) {
        print('   ❌ Source 3 failed: $e');
      }
    }

    // ── Cache and commit ──────────────────────────────────────────────────
    if (doctorId == null || doctorId <= 0) {
      print('❌ RESOLUTION FAILED — no linked doctor found.');
      print(
        '   This assistant account may not have a doctor_id on the backend.',
      );
      print('   Check that it was registered with doctor_email correctly.');
      state = state.copyWith(
        loadingPatients: false,
        loadingAppointments: false,
        doctors: const [],
        activeDoctor: null,
      );
      return;
    }

    _linkedDoctorId = doctorId;
    doctorMap ??= <String, dynamic>{'id': doctorId};

    state = state.copyWith(activeDoctor: doctorMap, doctors: [doctorMap]);

    print(
      '✅ Resolved doctor id=$_linkedDoctorId '
      'name=${doctorMap['first_name']} ${doctorMap['last_name']}',
    );

    await loadAll();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOAD SEQUENCE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> loadAll() async {
    await Future.wait([
      fetchPatients(),
      fetchAppointments(),
      fetchAppointmentTypes(),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DOCTOR SWITCHING
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> setActiveDoctor(Map<String, dynamic> doctor) async {
    // Assistant has exactly one doctor — switching is not allowed.
    // Just refresh data.
    await loadAll();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FETCHERS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchPatients({String search = ''}) async {
    state = state.copyWith(loadingPatients: true, patientsError: false);
    try {
      // Pass _linkedDoctorId explicitly so the backend filters by this doctor.
      // The assistant JWT alone doesn't scope patients — the doctor's patients
      // endpoint requires an explicit doctor_id filter from the assistant.
      // The doctor interface works without it because the doctor JWT scopes it.
      print('👥 fetchPatients → doctor_id=$_linkedDoctorId');
      final data = await ApiService.getPatients(
        search: search,
        doctorId: _linkedDoctorId,
      );
      print('👥 fetchPatients → ${data.length} records');
      state = state.copyWith(
        patients: List<Map<String, dynamic>>.from(data),
        loadingPatients: false,
      );
    } catch (e) {
      print('❌ fetchPatients: $e');
      state = state.copyWith(loadingPatients: false, patientsError: true);
    }
  }

  Future<void> fetchAppointments() async {
    state = state.copyWith(loadingAppointments: true, appointmentsError: false);
    try {
      // Always filter by _linkedDoctorId so we only see this doctor's appointments.
      print('📅 fetchAppointments → doctor_id=$_linkedDoctorId');
      final data = await ApiService.getAppointments(doctorId: _linkedDoctorId);
      print('📅 fetchAppointments → ${data.length} records');

      final list = List<Map<String, dynamic>>.from(data)
        ..sort((a, b) {
          final da = _parseDate(a['start_time']);
          final db = _parseDate(b['start_time']);
          return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
        });

      state = state.copyWith(appointments: list, loadingAppointments: false);
    } catch (e) {
      print('❌ fetchAppointments: $e');
      state = state.copyWith(
        loadingAppointments: false,
        appointmentsError: true,
      );
    }
  }

  Future<void> fetchAppointmentTypes() async {
    try {
      final data = await ApiService.getAppointmentTypes(
        doctorId: _linkedDoctorId,
      );
      state = state.copyWith(
        appointmentTypes: List<Map<String, dynamic>>.from(data),
      );
    } catch (e) {
      print('⚠️  fetchAppointmentTypes: $e');
      state = state.copyWith(appointmentTypes: const []);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APPOINTMENT ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════════
  // PATIENT ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> createOrUpdatePatient(
    Map<String, dynamic> data, {
    int? existingId,
  }) async {
    if (existingId != null) {
      await ApiService.updatePatient(existingId, data);
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

  void clearLastCreatedPatient() =>
      state = state.copyWith(eraseLastCreatedPatient: true);

  Future<void> deletePatient(int id) async {
    await ApiService.deletePatient(id);
    await fetchPatients();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEARCH
  // ══════════════════════════════════════════════════════════════════════════

  void setApptSearch(String q) => state = state.copyWith(apptSearchQuery: q);

  void setPatientSearch(String q) =>
      state = state.copyWith(patientSearchQuery: q);

  // ══════════════════════════════════════════════════════════════════════════
  // COMPUTED
  // ══════════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════════
  // UTILITY
  // ══════════════════════════════════════════════════════════════════════════

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

  Future<void> logout() async => ApiService.logout();

  static String extractError(Object e) => ApiService.extractError(e);

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE
  // ══════════════════════════════════════════════════════════════════════════

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }
}
