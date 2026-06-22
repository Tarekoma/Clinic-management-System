// ─────────────────────────────────────────────────────────────────────────────
// lib/viewmodels/assistant_viewmodel.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:flutter/foundation.dart';
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
  final Map<int, Map<String, dynamic>> vitalsCache;

  // ── Pagination ──────────────────────────────────────────────────────────────
  final bool patientsHasMore;
  final int patientsSkip;
  final bool loadingMorePatients;

  final bool appointmentsHasMore;
  final int appointmentsSkip;
  final bool loadingMoreAppointments;

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
    this.vitalsCache = const {},
    this.patientsHasMore = true,
    this.patientsSkip = 0,
    this.loadingMorePatients = false,
    this.appointmentsHasMore = true,
    this.appointmentsSkip = 0,
    this.loadingMoreAppointments = false,
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
    Map<int, Map<String, dynamic>>? vitalsCache,
    bool? patientsHasMore,
    int? patientsSkip,
    bool? loadingMorePatients,
    bool? appointmentsHasMore,
    int? appointmentsSkip,
    bool? loadingMoreAppointments,
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
      vitalsCache: vitalsCache ?? this.vitalsCache,
      patientsHasMore: patientsHasMore ?? this.patientsHasMore,
      patientsSkip: patientsSkip ?? this.patientsSkip,
      loadingMorePatients: loadingMorePatients ?? this.loadingMorePatients,
      appointmentsHasMore: appointmentsHasMore ?? this.appointmentsHasMore,
      appointmentsSkip: appointmentsSkip ?? this.appointmentsSkip,
      loadingMoreAppointments:
          loadingMoreAppointments ?? this.loadingMoreAppointments,
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

  static const int _pageSize = 20;

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
    state = state.copyWith(
      loadingPatients: true,
      patientsError: false,
      patientsSkip: 0,
      patientsHasMore: true,
    );
    try {
      print('👥 fetchPatients → doctor_id=$_linkedDoctorId search="$search"');
      final data = await ApiService.getPatients(
        search: search,
        doctorId: _linkedDoctorId,
        skip: 0,
        limit: _pageSize,
      );
      print('👥 fetchPatients → ${data.length} records');
      state = state.copyWith(
        patients: List<Map<String, dynamic>>.from(data),
        loadingPatients: false,
        patientsSkip: data.length,
        patientsHasMore: data.length >= _pageSize,
      );
    } catch (e) {
      print('❌ fetchPatients: $e');
      state = state.copyWith(loadingPatients: false, patientsError: true);
    }
  }

  Future<void> loadMorePatients() async {
    if (state.loadingMorePatients ||
        !state.patientsHasMore ||
        state.loadingPatients) return;
    state = state.copyWith(loadingMorePatients: true);
    try {
      final data = await ApiService.getPatients(
        search: state.patientSearchQuery,
        doctorId: _linkedDoctorId,
        skip: state.patientsSkip,
        limit: _pageSize,
      );
      state = state.copyWith(
        patients: [
          ...state.patients,
          ...List<Map<String, dynamic>>.from(data),
        ],
        loadingMorePatients: false,
        patientsSkip: state.patientsSkip + data.length,
        patientsHasMore: data.length >= _pageSize,
      );
    } catch (_) {
      state = state.copyWith(loadingMorePatients: false);
    }
  }

  Future<void> fetchAppointments() async {
    state = state.copyWith(
      loadingAppointments: true,
      appointmentsError: false,
      appointmentsSkip: 0,
      appointmentsHasMore: true,
    );
    try {
      print('📅 fetchAppointments → doctor_id=$_linkedDoctorId');
      final data = await ApiService.getAppointments(
        doctorId: _linkedDoctorId,
        skip: 0,
        limit: _pageSize,
      );
      print('📅 fetchAppointments → ${data.length} records');

      final list = List<Map<String, dynamic>>.from(data)
        ..sort((a, b) {
          final da = _parseDate(a['start_time']);
          final db = _parseDate(b['start_time']);
          return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
        });

      state = state.copyWith(
        appointments: list,
        loadingAppointments: false,
        appointmentsSkip: data.length,
        appointmentsHasMore: data.length >= _pageSize,
      );
    } catch (e) {
      print('❌ fetchAppointments: $e');
      state = state.copyWith(
        loadingAppointments: false,
        appointmentsError: true,
      );
    }
  }

  Future<void> loadMoreAppointments() async {
    if (state.loadingMoreAppointments ||
        !state.appointmentsHasMore ||
        state.loadingAppointments) return;
    state = state.copyWith(loadingMoreAppointments: true);
    try {
      final data = await ApiService.getAppointments(
        doctorId: _linkedDoctorId,
        skip: state.appointmentsSkip,
        limit: _pageSize,
      );
      final newItems = List<Map<String, dynamic>>.from(data)
        ..sort((a, b) {
          final da = _parseDate(a['start_time']);
          final db = _parseDate(b['start_time']);
          return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
        });
      state = state.copyWith(
        appointments: [...state.appointments, ...newItems],
        loadingMoreAppointments: false,
        appointmentsSkip: state.appointmentsSkip + data.length,
        appointmentsHasMore: data.length >= _pageSize,
      );
    } catch (_) {
      state = state.copyWith(loadingMoreAppointments: false);
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
    final newDiseases = List<String>.from(
      data.remove('chronic_diseases') ?? [],
    );
    if (existingId != null) {
      await ApiService.updatePatient(existingId, data);
      await fetchPatients();
      await _syncPatientConditions(
        patientId: existingId,
        newDiseaseNames: newDiseases,
      );
      state = state.copyWith(eraseLastCreatedPatient: true);
    } else {
      final created = await ApiService.createPatient(data);
      final newId = int.tryParse((created['id'] ?? 0).toString()) ?? 0;
      state = state.copyWith(
        lastCreatedPatient: Map<String, dynamic>.from(created),
      );
      await fetchPatients();
      if (newDiseases.isNotEmpty && newId > 0) {
        await _syncPatientConditions(
          patientId: newId,
          newDiseaseNames: newDiseases,
        );
      }
    }
  }

  void clearLastCreatedPatient() =>
      state = state.copyWith(eraseLastCreatedPatient: true);

  Future<void> _syncPatientConditions({
    required int patientId,
    required List<String> newDiseaseNames,
  }) async {
    try {
      var catalog = List<Map<String, dynamic>>.from(
        await ApiService.getConditions(),
      );
      final patient = state.patients.firstWhere(
        (p) => p['id'].toString() == patientId.toString(),
        orElse: () => {},
      );
      final currentConditions = _extractChronicConditions(patient);
      final currentNamesLower = currentConditions
          .map((c) => _conditionName(c).toLowerCase())
          .toSet();
      final newNamesLower =
          newDiseaseNames.map((n) => n.toLowerCase()).toSet();

      final toAdd = newDiseaseNames
          .where((n) => !currentNamesLower.contains(n.toLowerCase()))
          .toList();
      final toRemove = currentConditions
          .where(
            (c) => !newNamesLower.contains(_conditionName(c).toLowerCase()),
          )
          .toList();

      for (final c in toRemove) {
        final condId = int.tryParse(
              (c['condition_id'] ??
                      (c['condition'] as Map?)?['id'] ??
                      0)
                  .toString(),
            ) ??
            0;
        if (condId > 0) {
          try {
            await ApiService.removeCondition(patientId, condId);
          } catch (_) {}
        }
      }

      for (final name in toAdd) {
        Map<String, dynamic>? match;
        for (final c in catalog) {
          if ((c['name'] ?? '').toString().toLowerCase() ==
              name.toLowerCase()) {
            match = c;
            break;
          }
        }
        if (match == null) {
          for (final c in catalog) {
            final cn = (c['name'] ?? '').toString().toLowerCase();
            if (cn.contains(name.toLowerCase()) ||
                name.toLowerCase().contains(cn)) {
              match = c;
              break;
            }
          }
        }
        if (match == null || match['id'] == null) {
          try {
            match = await ApiService.createCondition(name, 'CHRONIC');
            catalog.add(match);
          } catch (_) {
            try {
              final found = List<Map<String, dynamic>>.from(
                await ApiService.getConditions(search: name),
              );
              if (found.isNotEmpty) match = found.first;
            } catch (_) {}
          }
        }
        if (match != null && match['id'] != null) {
          try {
            await ApiService.assignCondition(
              patientId,
              int.parse(match['id'].toString()),
              '',
            );
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  static List<Map<String, dynamic>> _extractChronicConditions(
    Map<String, dynamic> patient,
  ) {
    final raw = patient['patient_conditions'];
    if (raw is! List) return [];
    final result = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final cat =
          (item['category'] ??
                  (item['condition'] as Map?)?['category'] ??
                  '')
              .toString()
              .toUpperCase();
      if (cat == 'CHRONIC') result.add(Map<String, dynamic>.from(item));
    }
    return result;
  }

  static String _conditionName(Map<String, dynamic> c) =>
      (c['name'] ?? (c['condition'] as Map?)?['name'] ?? '').toString();

  Future<void> deletePatient(int id) async {
    await ApiService.deletePatient(id);
    await fetchPatients();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VITALS
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> fetchVitalsForAppointment(
    int appointmentId,
  ) async {
    try {
      final visits = await ApiService.getVisits();
      for (final raw in visits) {
        if (raw is! Map) continue;
        final v = Map<String, dynamic>.from(raw);
        final apptId = v['appointment_id']?.toString() ??
            (v['appointment'] is Map
                ? v['appointment']['id']?.toString()
                : null);
        if (apptId == appointmentId.toString() && _hasVitals(v)) {
          final vitals = _visitToVitals(v);
          final updated =
              Map<int, Map<String, dynamic>>.from(state.vitalsCache);
          updated[appointmentId] = vitals;
          state = state.copyWith(vitalsCache: updated);
          debugPrint(
            '💊 fetchVitalsForAppointment($appointmentId): found in visit ${v['id']}',
          );
          return vitals;
        }
      }
    } catch (e) {
      debugPrint('❌ fetchVitalsForAppointment error: $e');
    }
    return null;
  }

  static bool _hasVitals(Map<String, dynamic> v) =>
      v['blood_pressure'] != null ||
      v['heart_rate'] != null ||
      v['temperature'] != null ||
      v['weight'] != null ||
      v['height'] != null;

  static Map<String, dynamic> _visitToVitals(Map<String, dynamic> visit) {
    final bp = (visit['blood_pressure'] ?? '').toString().trim();
    final parts = bp.isNotEmpty ? bp.split('/') : <String>[];
    return {
      'blood_pressure_systolic': parts.isNotEmpty ? parts[0].trim() : null,
      'blood_pressure_diastolic': parts.length > 1 ? parts[1].trim() : null,
      'heart_rate': visit['heart_rate'],
      'temperature': visit['temperature'],
      'weight': visit['weight'],
      'height': visit['height'],
      'chief_complaint': visit['chief_complaint'],
      'notes': visit['notes'],
      'recorded_at': visit['updated_at'] ?? visit['created_at'],
      'created_at': visit['created_at'],
      '_visit_id': visit['id'],
    };
  }

  Future<Map<String, dynamic>> saveVitals({
    required int appointmentId,
    required int patientId,
    required Map<String, dynamic> vitalsData,
  }) async {
    // Map app field names → backend visit field names.
    // The backend stores blood pressure as a single "120/80" string.
    final sys = vitalsData['blood_pressure_systolic'];
    final dia = vitalsData['blood_pressure_diastolic'];
    final Map<String, dynamic> visitPayload = {};
    if (sys != null && dia != null) {
      visitPayload['blood_pressure'] = '$sys/$dia';
    } else if (sys != null) {
      visitPayload['blood_pressure'] = '$sys';
    }
    if (vitalsData['heart_rate'] != null) {
      visitPayload['heart_rate'] = vitalsData['heart_rate'];
    }
    if (vitalsData['temperature'] != null) {
      visitPayload['temperature'] = vitalsData['temperature'];
    }
    if (vitalsData['weight'] != null) {
      visitPayload['weight'] = vitalsData['weight'];
    }
    if (vitalsData['height'] != null) {
      visitPayload['height'] = vitalsData['height'];
    }
    if ((vitalsData['chief_complaint'] ?? '').toString().isNotEmpty) {
      visitPayload['chief_complaint'] = vitalsData['chief_complaint'];
    }
    if ((vitalsData['notes'] ?? '').toString().isNotEmpty) {
      visitPayload['notes'] = vitalsData['notes'];
    }

    debugPrint('💊 saveVitals visitPayload: $visitPayload');

    // Find an existing visit for this appointment so we PATCH it rather than
    // creating a duplicate.
    int? existingVisitId;
    try {
      final visits = await ApiService.getVisits(
        patientId: patientId > 0 ? patientId : null,
      );
      for (final raw in visits) {
        if (raw is! Map) continue;
        final v = Map<String, dynamic>.from(raw);
        final apptId = v['appointment_id']?.toString() ??
            (v['appointment'] is Map
                ? v['appointment']['id']?.toString()
                : null);
        if (apptId == appointmentId.toString()) {
          existingVisitId = int.tryParse((v['id'] ?? 0).toString());
          break;
        }
      }
    } catch (e) {
      debugPrint('⚠️ saveVitals: getVisits failed ($e) — will create visit');
    }

    final Map<String, dynamic> result;
    if (existingVisitId != null && existingVisitId > 0) {
      debugPrint('💊 PATCHing visit $existingVisitId with vitals');
      result = await ApiService.updateVisit(existingVisitId, visitPayload);
    } else {
      debugPrint('💊 POSTing new visit with vitals for appt $appointmentId');
      result = await ApiService.startVisit({
        'appointment_id': appointmentId,
        ...visitPayload,
      });
    }

    debugPrint('✅ saveVitals result: $result');

    final updated = Map<int, Map<String, dynamic>>.from(state.vitalsCache);
    updated[appointmentId] = _visitToVitals(result);
    state = state.copyWith(vitalsCache: updated);
    return result;
  }

  Map<String, dynamic>? getCachedVitals(int appointmentId) =>
      state.vitalsCache[appointmentId];

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
      final s = (a['status'] ?? '').toUpperCase();
      if (s == 'CANCELLED' || s == 'NO_SHOW') continue;
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
