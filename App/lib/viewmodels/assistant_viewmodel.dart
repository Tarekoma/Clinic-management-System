// ─────────────────────────────────────────────────────────────────────────────
// lib/viewmodels/assistant_viewmodel.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async' show unawaited;
import 'package:Hakim/errors/error_handler.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/clinic_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════════════════════════════════════

class AssistantState {
  final List<Map<String, dynamic>> doctors;
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> allAppointments;
  final List<Map<String, dynamic>> appointmentTypes;
  final bool loadingPatients;
  final bool loadingAppointments;
  final bool patientsError;
  final bool appointmentsError;
  final String patientsErrorMessage;
  final String appointmentsErrorMessage;
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

  // ── Doctor resolution ────────────────────────────────────────────────────────
  final bool doctorResolutionFailed;

  const AssistantState({
    this.doctors = const [],
    this.patients = const [],
    this.appointments = const [],
    this.allAppointments = const [],
    this.appointmentTypes = const [],
    this.loadingPatients = false,
    this.loadingAppointments = false,
    this.patientsError = false,
    this.appointmentsError = false,
    this.patientsErrorMessage = '',
    this.appointmentsErrorMessage = '',
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
    this.doctorResolutionFailed = false,
  });

  AssistantState copyWith({
    List<Map<String, dynamic>>? doctors,
    List<Map<String, dynamic>>? patients,
    List<Map<String, dynamic>>? appointments,
    List<Map<String, dynamic>>? allAppointments,
    List<Map<String, dynamic>>? appointmentTypes,
    bool? loadingPatients,
    bool? loadingAppointments,
    bool? patientsError,
    bool? appointmentsError,
    String? patientsErrorMessage,
    String? appointmentsErrorMessage,
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
    bool? doctorResolutionFailed,
  }) {
    return AssistantState(
      doctors: doctors ?? this.doctors,
      patients: patients ?? this.patients,
      appointments: appointments ?? this.appointments,
      allAppointments: allAppointments ?? this.allAppointments,
      appointmentTypes: appointmentTypes ?? this.appointmentTypes,
      loadingPatients: loadingPatients ?? this.loadingPatients,
      loadingAppointments: loadingAppointments ?? this.loadingAppointments,
      patientsError: patientsError ?? this.patientsError,
      appointmentsError: appointmentsError ?? this.appointmentsError,
      patientsErrorMessage: patientsErrorMessage ?? this.patientsErrorMessage,
      appointmentsErrorMessage:
          appointmentsErrorMessage ?? this.appointmentsErrorMessage,
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
      doctorResolutionFailed:
          doctorResolutionFailed ?? this.doctorResolutionFailed,
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
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🚀 AssistantVM.initForAssistant');
    debugPrint('   email     : ${profile.email}');
    debugPrint('   clinicName: ${profile.clinicName}');
    debugPrint('   doctorId  : ${profile.doctorId}');
    debugPrint('   doctorEmail: ${profile.doctorEmail}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

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
      debugPrint('✅ Source 1: profile.doctorId=$doctorId');
    } else {
      debugPrint('   Source 1: profile.doctorId empty — trying Source 2');
    }

    // ── Source 2a: GET /api/v1/users/assistants/{id} (direct O(1) lookup) ──────
    // profile.id is the assistant's profile-table PK, set from u['id'] at login.
    // This is always the correct record regardless of how many assistants exist.
    if (doctorId == null) {
      final profileId = int.tryParse(profile.id.trim());
      if (profileId != null && profileId > 0) {
        try {
          final myRecord = await ApiService.getAssistantById(profileId);
          if (myRecord != null) {
            debugPrint('   📋 assistants/$profileId record: $myRecord');
            final raw =
                myRecord['doctor_id'] ??
                myRecord['linked_doctor_id'] ??
                myRecord['doctor']?['id'];
            doctorId = int.tryParse((raw ?? '').toString());
            if (doctorId != null && doctorId > 0) {
              debugPrint('✅ Source 2a: assistants/$profileId → doctor_id=$doctorId');
              if (myRecord['doctor'] is Map) {
                doctorMap = Map<String, dynamic>.from(myRecord['doctor'] as Map);
              }
            } else {
              debugPrint('   ⚠️  Source 2a: record has no doctor_id — account may be missing doctor link');
            }
          }
        } catch (e) {
          debugPrint('   Source 2a failed ($e) — falling back to list scan');
        }
      } else {
        debugPrint('   Source 2a: profile.id="${profile.id}" is not a valid int — skipping');
      }
    }

    // ── Source 2b: scan getAssistants() list, match by email ──────────────────
    // Fallback when the /me endpoint is not available on this backend version.
    if (doctorId == null) {
      try {
        final list = await ApiService.getAssistants();
        debugPrint('   getAssistants() → ${list.length} records');

        final myEmail = profile.email.trim().toLowerCase();
        Map<String, dynamic>? myRecord;
        for (final a in list) {
          if ((a['email'] ?? '').toString().trim().toLowerCase() == myEmail) {
            myRecord = Map<String, dynamic>.from(a as Map);
            break;
          }
        }

        if (myRecord != null) {
          debugPrint('   📋 My assistant record (list scan): $myRecord');

          final raw =
              myRecord['doctor_id'] ??
              myRecord['linked_doctor_id'] ??
              myRecord['doctor']?['id'];
          doctorId = int.tryParse((raw ?? '').toString());

          if (doctorId != null && doctorId > 0) {
            debugPrint('✅ Source 2b: assistant.doctor_id=$doctorId');
            if (myRecord['doctor'] is Map) {
              doctorMap = Map<String, dynamic>.from(myRecord['doctor'] as Map);
            }
          } else {
            debugPrint('   ⚠️  Source 2b: doctor_id field absent or zero in record');
            debugPrint('   ⚠️  This assistant account may be missing doctor_email on the backend.');
          }
        } else {
          debugPrint('   ⚠️  Source 2b: no record found for email=$myEmail');
          debugPrint('   ⚠️  Check if this assistant exists in /api/v1/users/assistants');
        }
      } catch (e) {
        debugPrint('   ❌ Source 2b failed: $e');
      }
    }

    // ── Source 3: getDoctors() filtered by clinic_name ───────────────────
    if (doctorId == null) {
      debugPrint('   Source 3: clinic_name filter on getDoctors()...');
      try {
        final docs = await ApiService.getDoctors();
        debugPrint('   getDoctors() → ${docs.length} records');
        for (final d in docs) {
          debugPrint(
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
          debugPrint('   clinic="$clinic" → ${matches.length} match(es)');

          if (matches.length == 1) {
            final d = Map<String, dynamic>.from(matches.first as Map);
            doctorId = int.tryParse((d['id'] ?? '').toString());
            doctorMap = d;
            debugPrint('✅ Source 3: unique clinic match id=$doctorId');
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
                debugPrint(
                  '✅ Source 3: email match among clinic doctors id=$doctorId',
                );
              } else {
                debugPrint(
                  '   ⚠️  Source 3: ${matches.length} clinic matches, '
                  'no email match — picking first as best guess',
                );
                final d = Map<String, dynamic>.from(matches.first as Map);
                doctorId = int.tryParse((d['id'] ?? '').toString());
                doctorMap = d;
              }
            } else {
              debugPrint(
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
        debugPrint('   ❌ Source 3 failed: $e');
      }
    }

    // ── Cache and commit ──────────────────────────────────────────────────
    if (doctorId == null || doctorId <= 0) {
      debugPrint('❌ RESOLUTION FAILED — no linked doctor found.');
      debugPrint(
        '   This assistant account may not have a doctor_id on the backend.',
      );
      debugPrint('   Check that it was registered with doctor_email correctly.');
      state = state.copyWith(
        loadingPatients: false,
        loadingAppointments: false,
        doctors: const [],
        activeDoctor: null,
        doctorResolutionFailed: true,
      );
      return;
    }

    _linkedDoctorId = doctorId;
    doctorMap ??= <String, dynamic>{'id': doctorId};

    state = state.copyWith(
      activeDoctor: doctorMap,
      doctors: [doctorMap],
      doctorResolutionFailed: false,
    );

    debugPrint(
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
      patientsErrorMessage: '',
      patientsSkip: 0,
      patientsHasMore: true,
    );
    try {
      // The backend auto-scopes GET /clinic/patients to the assistant's
      // assigned doctor's patients via the JWT token.  The doctor_id query
      // param has no effect for non-admin callers (API guide §6.3).
      debugPrint('👥 fetchPatients → search="$search"');
      final data = await ApiService.getPatients(
        search: search,
        skip: 0,
        limit: _pageSize,
      );
      debugPrint('👥 fetchPatients → ${data.length} records');
      state = state.copyWith(
        patients: List<Map<String, dynamic>>.from(data),
        loadingPatients: false,
        patientsSkip: data.length,
        patientsHasMore: data.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        loadingPatients: false,
        patientsError: true,
        patientsErrorMessage: ErrorHandler.friendlyMessage(e, context: 'fetchPatients'),
      );
    }
  }

  Future<void> loadMorePatients() async {
    if (state.loadingMorePatients ||
        !state.patientsHasMore ||
        state.loadingPatients) {
      return;
    }
    state = state.copyWith(loadingMorePatients: true);
    try {
      final data = await ApiService.getPatients(
        search: state.patientSearchQuery,
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
    } catch (e) {
      ErrorHandler.log(e, context: 'loadMorePatients');
      state = state.copyWith(loadingMorePatients: false);
    }
  }

  Future<void> fetchAppointments() async {
    state = state.copyWith(
      loadingAppointments: true,
      appointmentsError: false,
      appointmentsErrorMessage: '',
      appointmentsSkip: 0,
      appointmentsHasMore: true,
    );
    try {
      // The backend auto-scopes GET /clinic/appointments to the assistant's
      // assigned doctor's appointments via the JWT token.  The doctor_id param
      // is silently ignored for non-admin callers (API guide §6.3).
      debugPrint('📅 fetchAppointments (JWT-scoped)');
      final data = await ApiService.getAppointments(
        skip: 0,
        limit: _pageSize,
      );
      debugPrint('📅 fetchAppointments → ${data.length} records');

      final list = List<Map<String, dynamic>>.from(data)
        ..sort((a, b) {
          final da = ClinicHelpers.parseDate(a['start_time']);
          final db = ClinicHelpers.parseDate(b['start_time']);
          return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
        });

      state = state.copyWith(
        appointments: list,
        allAppointments: list,
        loadingAppointments: false,
        appointmentsSkip: data.length,
        appointmentsHasMore: data.length >= _pageSize,
      );
      unawaited(_refreshCountSnapshot());
      // Merge visit statuses so Waiting / In-Progress display correctly.
      // The appointments list endpoint does not return visit_status; visits
      // are a separate resource that must be fetched and joined here.
      unawaited(_mergeVisitStatuses());
    } catch (e) {
      state = state.copyWith(
        loadingAppointments: false,
        appointmentsError: true,
        appointmentsErrorMessage:
            ErrorHandler.friendlyMessage(e, context: 'fetchAppointments'),
      );
    }
  }

  // Fetches all visits (paginated) and patches visit_status into both the
  // display list and the count snapshot so that _effectiveStatus() can
  // distinguish "Waiting room" (VisitStatus=WAITING) from "With doctor"
  // (VisitStatus=IN_PROGRESS) — both share AppointmentStatus=IN_PROGRESS.
  Future<void> _mergeVisitStatuses() async {
    try {
      const visitPageSize = 100;
      final visits = <dynamic>[];
      int skip = 0;
      while (true) {
        final page = await ApiService.getVisits(
          skip: skip,
          limit: visitPageSize,
        );
        visits.addAll(page);
        if (page.length < visitPageSize) break;
        skip += page.length;
      }
      if (visits.isEmpty) return;

      final Map<String, String> visitStatusMap = {};
      for (final v in visits) {
        final apptId = v['appointment_id']?.toString();
        final vs = (v['status'] ?? '').toString().toUpperCase();
        if (apptId != null && apptId.isNotEmpty && vs.isNotEmpty) {
          visitStatusMap[apptId] = vs;
        }
      }

      if (visitStatusMap.isEmpty) return;

      List<Map<String, dynamic>> patch(List<Map<String, dynamic>> src) =>
          src.map((a) {
            final apptId = a['id']?.toString();
            if (apptId != null && visitStatusMap.containsKey(apptId)) {
              return Map<String, dynamic>.from(a)
                ..['visit_status'] = visitStatusMap[apptId];
            }
            return a;
          }).toList();

      state = state.copyWith(
        appointments: patch(state.appointments),
        allAppointments: state.allAppointments.isEmpty
            ? state.allAppointments
            : patch(state.allAppointments),
      );
    } catch (e) {
      debugPrint('⚠️ _mergeVisitStatuses: $e');
    }
  }

  static const int _countBatchSize = 100;

  Future<void> _refreshCountSnapshot() async {
    try {
      final all = <Map<String, dynamic>>[];
      int skip = 0;
      while (true) {
        final page = await ApiService.getAppointments(
          skip: skip,
          limit: _countBatchSize,
        );
        final items = List<Map<String, dynamic>>.from(page);
        all.addAll(items);
        if (items.length < _countBatchSize) break;
        skip += items.length;
      }
      state = state.copyWith(allAppointments: all);
    } catch (_) {
      // Keep the first-page seed — counts will be slightly under until next refresh.
    }
  }

  Future<void> loadMoreAppointments() async {
    if (state.loadingMoreAppointments ||
        !state.appointmentsHasMore ||
        state.loadingAppointments) {
      return;
    }
    state = state.copyWith(loadingMoreAppointments: true);
    try {
      final data = await ApiService.getAppointments(
        skip: state.appointmentsSkip,
        limit: _pageSize,
      );
      final newItems = List<Map<String, dynamic>>.from(data)
        ..sort((a, b) {
          final da = ClinicHelpers.parseDate(a['start_time']);
          final db = ClinicHelpers.parseDate(b['start_time']);
          return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
        });
      state = state.copyWith(
        appointments: [...state.appointments, ...newItems],
        loadingMoreAppointments: false,
        appointmentsSkip: state.appointmentsSkip + data.length,
        appointmentsHasMore: data.length >= _pageSize,
      );
    } catch (e) {
      ErrorHandler.log(e, context: 'loadMoreAppointments');
      state = state.copyWith(loadingMoreAppointments: false);
    }
  }

  Future<void> fetchAppointmentTypes() async {
    try {
      debugPrint('🗂️ fetchAppointmentTypes → linkedDoctorId=$_linkedDoctorId');
      final data = await ApiService.getAppointmentTypes(
        doctorId: _linkedDoctorId,
      );
      debugPrint('🗂️ fetchAppointmentTypes → ${data.length} type(s) received:');
      for (final raw in data) {
        final t = raw as Map<String, dynamic>;
        debugPrint(
          '  • id=${t["id"]}  name="${t["name"]}"  default_fee=${t["default_fee"]}',
        );
      }
      state = state.copyWith(
        appointmentTypes: List<Map<String, dynamic>>.from(data),
      );
    } catch (e) {
      debugPrint('🗂️ fetchAppointmentTypes → ERROR: $e');
      ErrorHandler.log(e, context: 'fetchAppointmentTypes');
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

  Future<void> checkInPatient(int appointmentId) async {
    final visit = await ApiService.startVisit({'appointment_id': appointmentId});
    final visitStatus = (visit['status'] ?? 'WAITING').toString().toUpperCase();

    // Full refresh — gets the authoritative server state.
    await fetchAppointments();

    // Patch the checked-in appointment with the visit status we received
    // directly from startVisit(). This is done AFTER the fetch so it is not
    // overwritten, and avoids depending on the background _mergeVisitStatuses()
    // race. Both appointments and allAppointments are updated so the count
    // chip reflects the correct number immediately.
    List<Map<String, dynamic>> applyPatch(List<Map<String, dynamic>> src) =>
        src.map((a) {
          if (a['id']?.toString() == appointmentId.toString()) {
            return Map<String, dynamic>.from(a)
              ..['status'] = 'IN_PROGRESS'
              ..['visit_status'] = visitStatus;
          }
          return a;
        }).toList();

    state = state.copyWith(
      appointments: applyPatch(state.appointments),
      allAppointments: state.allAppointments.isEmpty
          ? state.allAppointments
          : applyPatch(state.allAppointments),
    );
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
      await ClinicHelpers.syncPatientConditions(
        patientId: existingId,
        newDiseaseNames: newDiseases,
        patients: state.patients,
      );
      // Re-fetch so state reflects the condition changes just synced to the
      // backend — without this the detail screen shows stale patient_conditions.
      await fetchPatients();
      state = state.copyWith(eraseLastCreatedPatient: true);
    } else {
      final created = await ApiService.createPatient(data);
      final newId = int.tryParse((created['id'] ?? 0).toString()) ?? 0;
      state = state.copyWith(
        lastCreatedPatient: Map<String, dynamic>.from(created),
      );
      await fetchPatients();
      if (newDiseases.isNotEmpty && newId > 0) {
        await ClinicHelpers.syncPatientConditions(
          patientId: newId,
          newDiseaseNames: newDiseases,
          patients: state.patients,
        );
        // Re-fetch so the newly assigned conditions appear in state immediately.
        await fetchPatients();
      }
    }
  }

  void clearLastCreatedPatient() =>
      state = state.copyWith(eraseLastCreatedPatient: true);

  /// Fetches the full patient record by ID (includes patient_conditions).
  /// Updates the matching entry in the in-memory patients list so callers
  /// get fresh data without a full re-fetch.
  Future<Map<String, dynamic>?> fetchPatientById(int id) async {
    try {
      final fresh = await ApiService.getPatientById(id);
      final updated = state.patients.map((p) {
        if (p['id'].toString() == id.toString()) {
          return Map<String, dynamic>.from(fresh);
        }
        return p;
      }).toList();
      state = state.copyWith(patients: updated);
      return fresh;
    } catch (e) {
      debugPrint('❌ fetchPatientById($id): $e');
      return null;
    }
  }

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
    // Look up patientId from cached appointments to filter the visits query.
    final appt = state.appointments.firstWhere(
      (a) => a['id']?.toString() == appointmentId.toString(),
      orElse: () => {},
    );
    final patientId = int.tryParse(
      (appt['patient_id'] ?? appt['patient']?['id'] ?? 0).toString(),
    );
    try {
      final visits = await ApiService.getVisits(
        patientId: (patientId != null && patientId > 0) ? patientId : null,
      );
      for (final raw in visits) {
        if (raw is! Map) continue;
        final v = Map<String, dynamic>.from(raw);
        final apptId = v['appointment_id']?.toString() ??
            (v['appointment'] is Map
                ? v['appointment']['id']?.toString()
                : null);
        if (apptId == appointmentId.toString() &&
            ClinicHelpers.hasVitals(v)) {
          final vitals = {
            ...ClinicHelpers.visitToVitals(v),
            '_visit_id': v['id'],
          };
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
    updated[appointmentId] = {
      ...ClinicHelpers.visitToVitals(result),
      '_visit_id': result['id'],
    };
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

  DateTime? parseDate(dynamic v) => ClinicHelpers.parseDate(v);

  static String toIso8601WithTz(DateTime dt) =>
      ClinicHelpers.toIso8601WithTz(dt);

  // ── Filter-based appointment access ────────────────────────────────────────

  // Returns the effective display status of an appointment, combining
  // AppointmentStatus with VisitStatus when the visit has started.
  // Mirrors AssistantTheme.getDisplayStatus() — kept here to avoid importing
  // the UI layer from the viewmodel.
  static String _effectiveStatus(Map<String, dynamic> a) {
    final apptStatus = (a['status'] ?? 'SCHEDULED').toString().toUpperCase();
    if (apptStatus == 'IN_PROGRESS') {
      final visitStatus =
          (a['visit_status'] ?? a['visitStatus'] ?? '').toString().toUpperCase();
      if (visitStatus.isNotEmpty) return visitStatus;
    }
    return apptStatus;
  }

  List<Map<String, dynamic>> filteredByFilter(AssistantApptFilter filter) {
    final base = filteredAppointments; // applies search query
    final now = DateTime.now();
    final result = base.where((a) {
      final dt = parseDate(a['start_time']);
      final s = (a['status'] ?? '').toUpperCase();        // raw AppointmentStatus
      final ds = _effectiveStatus(a);                     // visit-aware status
      return switch (filter) {
        AssistantApptFilter.all => true,
        AssistantApptFilter.today =>
          dt != null &&
              dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day,
        // Waiting = appointment is IN_PROGRESS but visit is still WAITING
        // (patient sitting in waiting room, not yet called in).
        AssistantApptFilter.waiting => ds == 'WAITING',
        // In Progress = appointment is IN_PROGRESS and visit is also IN_PROGRESS
        // (patient is currently with the doctor).
        AssistantApptFilter.inProgress => ds == 'IN_PROGRESS',
        AssistantApptFilter.upcoming =>
          dt != null &&
              (dt.isAfter(now) ||
                  (dt.year == now.year &&
                      dt.month == now.month &&
                      dt.day == now.day)) &&
              s != 'CANCELLED' &&
              s != 'NO_SHOW' &&
              s != 'COMPLETED',
        AssistantApptFilter.urgent => a['is_urgent'] == true,
        AssistantApptFilter.completed => s == 'COMPLETED',
        AssistantApptFilter.cancelled => s == 'CANCELLED',
      };
    }).toList();
    // Sort chronologically ascending (earliest first)
    result.sort((a, b) {
      final da = parseDate(a['start_time']) ?? DateTime(9999);
      final db = parseDate(b['start_time']) ?? DateTime(9999);
      return da.compareTo(db);
    });
    return result;
  }

  int apptFilterCount(AssistantApptFilter filter) {
    final base = state.allAppointments.isNotEmpty
        ? state.allAppointments
        : state.appointments;
    final now = DateTime.now();
    return base.where((a) {
      final dt = ClinicHelpers.parseDate(a['start_time']);
      final s = (a['status'] ?? '').toUpperCase();
      final ds = _effectiveStatus(a);
      return switch (filter) {
        AssistantApptFilter.all => true,
        AssistantApptFilter.today =>
          dt != null &&
              dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day,
        AssistantApptFilter.waiting => ds == 'WAITING',
        AssistantApptFilter.inProgress => ds == 'IN_PROGRESS',
        AssistantApptFilter.upcoming =>
          dt != null &&
              (dt.isAfter(now) ||
                  (dt.year == now.year &&
                      dt.month == now.month &&
                      dt.day == now.day)) &&
              s != 'CANCELLED' &&
              s != 'NO_SHOW' &&
              s != 'COMPLETED',
        AssistantApptFilter.urgent => a['is_urgent'] == true,
        AssistantApptFilter.completed => s == 'COMPLETED',
        AssistantApptFilter.cancelled => s == 'CANCELLED',
      };
    }).length;
  }

  Future<void> logout() async {
    await ApiService.logout();
    // Reset all instance state so the next user who logs in starts completely
    // fresh. Without this, _linkedDoctorId and _initEmail from the previous
    // session persist in the singleton ViewModel, and the re-entrancy guard
    // could cache stale data across user switches.
    _linkedDoctorId = null;
    _initEmail = '';
    state = const AssistantState();
  }

  static String extractError(Object e) => ErrorHandler.friendlyMessage(e);
}

// ══════════════════════════════════════════════════════════════════════════════
enum AssistantApptFilter { today, waiting, inProgress, upcoming, urgent, completed, cancelled, all }
