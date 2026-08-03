// ─────────────────────────────────────────────────────────────────────────────
// lib/viewmodels/doctor_viewmodel.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async' show unawaited;
import 'dart:io';
import 'package:Hakim/errors/error_handler.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/services/settings_service.dart';
import 'package:Hakim/utils/clinic_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════════════════════════════════════

class DoctorState {
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> appointments;
  // Complete appointment dataset used exclusively for filter counts.
  // Kept separate from the paginated display list so counts never regress
  // when fetchAppointments() resets pagination after a mutation.
  final List<Map<String, dynamic>> allAppointments;
  final List<Map<String, dynamic>> appointmentTypes;
  final List<Map<String, dynamic>> reports;
  final List<Map<String, dynamic>> vitals;
  final int? doctorId;

  final bool loadingPatients;
  final bool loadingAppointments;
  final bool loadingVitals;

  final bool patientsError;
  final bool appointmentsError;

  /// User-friendly error message shown in ErrorRetryWidget when a list fails.
  final String patientsErrorMessage;
  final String appointmentsErrorMessage;

  final String patientSearchQuery;
  final String apptSearchQuery;

  final Map<String, dynamic>? lastCreatedPatient;

  // ── Pagination ──────────────────────────────────────────────────────────────
  final bool patientsHasMore;
  final int patientsSkip;
  final bool loadingMorePatients;

  final bool appointmentsHasMore;
  final int appointmentsSkip;
  final bool loadingMoreAppointments;

  // ── Consultation session cache (persisted in state so Riverpod tracks it) ──
  final int cachedVisitId;
  final int cachedReportId;

  const DoctorState({
    this.patients = const [],
    this.appointments = const [],
    this.allAppointments = const [],
    this.appointmentTypes = const [],
    this.reports = const [],
    this.vitals = const [],
    this.doctorId,
    this.loadingPatients = false,
    this.loadingAppointments = false,
    this.loadingVitals = false,
    this.patientsError = false,
    this.appointmentsError = false,
    this.patientsErrorMessage = '',
    this.appointmentsErrorMessage = '',
    this.patientSearchQuery = '',
    this.apptSearchQuery = '',
    this.lastCreatedPatient,
    this.patientsHasMore = true,
    this.patientsSkip = 0,
    this.loadingMorePatients = false,
    this.appointmentsHasMore = true,
    this.appointmentsSkip = 0,
    this.loadingMoreAppointments = false,
    this.cachedVisitId = 0,
    this.cachedReportId = 0,
  });

  DoctorState copyWith({
    List<Map<String, dynamic>>? patients,
    List<Map<String, dynamic>>? appointments,
    List<Map<String, dynamic>>? allAppointments,
    List<Map<String, dynamic>>? appointmentTypes,
    List<Map<String, dynamic>>? reports,
    List<Map<String, dynamic>>? vitals,
    int? doctorId,
    bool? loadingPatients,
    bool? loadingAppointments,
    bool? loadingVitals,
    bool? patientsError,
    bool? appointmentsError,
    String? patientsErrorMessage,
    String? appointmentsErrorMessage,
    String? patientSearchQuery,
    String? apptSearchQuery,
    Map<String, dynamic>? lastCreatedPatient,
    bool eraseLastCreatedPatient = false,
    bool? patientsHasMore,
    int? patientsSkip,
    bool? loadingMorePatients,
    bool? appointmentsHasMore,
    int? appointmentsSkip,
    bool? loadingMoreAppointments,
    int? cachedVisitId,
    int? cachedReportId,
  }) {
    return DoctorState(
      patients: patients ?? this.patients,
      appointments: appointments ?? this.appointments,
      allAppointments: allAppointments ?? this.allAppointments,
      appointmentTypes: appointmentTypes ?? this.appointmentTypes,
      reports: reports ?? this.reports,
      vitals: vitals ?? this.vitals,
      doctorId: doctorId ?? this.doctorId,
      loadingPatients: loadingPatients ?? this.loadingPatients,
      loadingAppointments: loadingAppointments ?? this.loadingAppointments,
      loadingVitals: loadingVitals ?? this.loadingVitals,
      patientsError: patientsError ?? this.patientsError,
      appointmentsError: appointmentsError ?? this.appointmentsError,
      patientsErrorMessage: patientsErrorMessage ?? this.patientsErrorMessage,
      appointmentsErrorMessage:
          appointmentsErrorMessage ?? this.appointmentsErrorMessage,
      patientSearchQuery: patientSearchQuery ?? this.patientSearchQuery,
      apptSearchQuery: apptSearchQuery ?? this.apptSearchQuery,
      lastCreatedPatient: eraseLastCreatedPatient
          ? null
          : (lastCreatedPatient ?? this.lastCreatedPatient),
      patientsHasMore: patientsHasMore ?? this.patientsHasMore,
      patientsSkip: patientsSkip ?? this.patientsSkip,
      loadingMorePatients: loadingMorePatients ?? this.loadingMorePatients,
      appointmentsHasMore: appointmentsHasMore ?? this.appointmentsHasMore,
      appointmentsSkip: appointmentsSkip ?? this.appointmentsSkip,
      loadingMoreAppointments:
          loadingMoreAppointments ?? this.loadingMoreAppointments,
      cachedVisitId: cachedVisitId ?? this.cachedVisitId,
      cachedReportId: cachedReportId ?? this.cachedReportId,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VIEW MODEL
// ══════════════════════════════════════════════════════════════════════════════

class DoctorViewModel extends StateNotifier<DoctorState> {
  DoctorViewModel() : super(const DoctorState());

  static const int _pageSize = 20;

  Future<void> loadAll() => Future.wait([
    fetchPatients(),
    fetchAppointments(),
    fetchAppointmentTypes(),
    _syncFeeDefaultsToApi(),
  ]);

  /// Ensures both Consultation and Revisit appointment types exist in the
  /// backend with the fees currently saved on this device.  Called every time
  /// the doctor loads data so the assistant always reads up-to-date defaults
  /// without requiring an explicit "Save fees" action by the doctor.
  Future<void> _syncFeeDefaultsToApi() async {
    try {
      final fees = await SettingsService.loadFeeDefaults();
      final consultFee = fees['consultation']!;
      final revisitFee = fees['revisit']!;

      debugPrint('💰 syncFees → consult=$consultFee  revisit=$revisitFee');

      final types = await ApiService.getAppointmentTypes(
        doctorId: state.doctorId,
      );
      debugPrint('💰 syncFees → ${types.length} type(s) fetched');

      bool consultSynced = false;
      bool revisitSynced = false;

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
            revisitSynced = true;
          } else {
            consultSynced = true;
          }
          debugPrint(
            '💰 syncFees → PATCHed type $id "$name" '
            'fee=${isRevisit ? revisitFee : consultFee}',
          );
        } catch (e) {
          debugPrint('💰 syncFees → skipping type $id "$name": $e');
        }
      }

      if (!consultSynced) {
        try {
          await ApiService.createAppointmentType({
            'name': 'Consultation',
            'default_fee': consultFee,
          });
          debugPrint('💰 syncFees → created Consultation type (fee=$consultFee)');
        } catch (e) {
          debugPrint('💰 syncFees → could not create Consultation type: $e');
        }
      }
      if (!revisitSynced) {
        try {
          await ApiService.createAppointmentType({
            'name': 'Revisit',
            'default_fee': revisitFee,
          });
          debugPrint('💰 syncFees → created Revisit type (fee=$revisitFee)');
        } catch (e) {
          debugPrint('💰 syncFees → could not create Revisit type: $e');
        }
      }
    } catch (e) {
      debugPrint('💰 syncFees → sync failed: $e');
    }
  }

  void setDoctorId(int id) {
    if (id > 0) state = state.copyWith(doctorId: id);
  }

  // ── Patients ───────────────────────────────────────────────────────────────

  Future<void> fetchPatients() async {
    state = state.copyWith(
      loadingPatients: true,
      patientsError: false,
      patientsErrorMessage: '',
      patientsSkip: 0,
      patientsHasMore: true,
    );
    try {
      final d = await ApiService.getPatients(
        skip: 0,
        limit: _pageSize,
        doctorId: state.doctorId,
      );
      state = state.copyWith(
        patients: List<Map<String, dynamic>>.from(d),
        loadingPatients: false,
        patientsSkip: d.length,
        patientsHasMore: d.length >= _pageSize,
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
        state.loadingPatients) return;
    state = state.copyWith(loadingMorePatients: true);
    try {
      final d = await ApiService.getPatients(
        skip: state.patientsSkip,
        limit: _pageSize,
        doctorId: state.doctorId,
      );
      state = state.copyWith(
        patients: [
          ...state.patients,
          ...List<Map<String, dynamic>>.from(d),
        ],
        loadingMorePatients: false,
        patientsSkip: state.patientsSkip + d.length,
        patientsHasMore: d.length >= _pageSize,
      );
    } catch (e) {
      ErrorHandler.log(e, context: 'loadMorePatients');
      state = state.copyWith(loadingMorePatients: false);
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

  Future<void> deletePatient(int id) async {
    await ApiService.deletePatient(id);
    await fetchPatients();
  }

  Future<void> fetchReports(int patientId) async {
    try {
      final d = await ApiService.getMedicalReports(patientId: patientId);
      state = state.copyWith(reports: List<Map<String, dynamic>>.from(d));
    } catch (e) {
      ErrorHandler.log(e, context: 'fetchReports');
    }
  }

  Future<List<Map<String, dynamic>>> fetchVisits(int patientId) async {
    try {
      final d = await ApiService.getVisits(
        patientId: patientId > 0 ? patientId : null,
      );
      return List<Map<String, dynamic>>.from(d);
    } catch (e) {
      ErrorHandler.log(e, context: 'fetchVisits');
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
    state = state.copyWith(
      loadingAppointments: true,
      appointmentsError: false,
      appointmentsErrorMessage: '',
      appointmentsSkip: 0,
      appointmentsHasMore: true,
    );
    try {
      final d = await ApiService.getAppointments(skip: 0, limit: _pageSize);
      final list = List<Map<String, dynamic>>.from(d);
      list.sort((a, b) {
        final da = parseDate(a['start_time']);
        final db = parseDate(b['start_time']);
        return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
      });
      state = state.copyWith(
        appointments: list,
        // Seed allAppointments from the first page so counts are immediately
        // non-zero. _refreshCountSnapshot replaces this with the full dataset.
        allAppointments: list,
        loadingAppointments: false,
        appointmentsSkip: d.length,
        appointmentsHasMore: d.length >= _pageSize,
      );
      // Load the complete appointment dataset in the background so filter
      // counts are always based on the full record set, not just the visible
      // page. This runs without blocking the UI.
      unawaited(_refreshCountSnapshot());
      // Merge visit statuses so Waiting / In-Progress display correctly.
      unawaited(_mergeVisitStatuses());
    } catch (e) {
      state = state.copyWith(
        loadingAppointments: false,
        appointmentsError: true,
        appointmentsErrorMessage:
            ErrorHandler.friendlyMessage(e, context: 'fetchAppointments'),
      );
      rethrow;
    }
  }

  Future<void> _mergeVisitStatuses() async {
    try {
      const visitPageSize = 100;
      final visits = <dynamic>[];
      int skip = 0;
      while (true) {
        final page = await ApiService.getVisits(skip: skip, limit: visitPageSize);
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

  // Fetches every appointment page in sequence and stores the full list in
  // state.allAppointments.  Only filter counts read from this list; the display
  // list (state.appointments) continues to be paginated independently.
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
      // Silently keep the first-page seed — counts will be slightly under
      // until the next successful refresh.
    }
  }

  Future<void> loadMoreAppointments() async {
    if (state.loadingMoreAppointments ||
        !state.appointmentsHasMore ||
        state.loadingAppointments) return;
    state = state.copyWith(loadingMoreAppointments: true);
    try {
      final d = await ApiService.getAppointments(
        skip: state.appointmentsSkip,
        limit: _pageSize,
      );
      final newItems = List<Map<String, dynamic>>.from(d);
      newItems.sort((a, b) {
        final da = parseDate(a['start_time']);
        final db = parseDate(b['start_time']);
        return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
      });
      state = state.copyWith(
        appointments: [...state.appointments, ...newItems],
        loadingMoreAppointments: false,
        appointmentsSkip: state.appointmentsSkip + d.length,
        appointmentsHasMore: d.length >= _pageSize,
      );
    } catch (e) {
      ErrorHandler.log(e, context: 'loadMoreAppointments');
      state = state.copyWith(loadingMoreAppointments: false);
    }
  }

  Future<void> fetchAppointmentTypes() async {
    try {
      final d = await ApiService.getAppointmentTypes(doctorId: state.doctorId);
      state = state.copyWith(
        appointmentTypes: List<Map<String, dynamic>>.from(d),
      );
    } catch (e) {
      ErrorHandler.log(e, context: 'fetchAppointmentTypes');
    }
  }

  Future<void> updateAppointmentStatus(int id, String status) async {
    await ApiService.updateAppointmentStatus(id, status);
    await fetchAppointments();
  }

  Future<void> createOrUpdateAppointment(
    Map<String, dynamic> data, {
    int? existingId,
  }) async {
    if (existingId != null) {
      // ── Find current status ──────────────────────────────────────────────
      final current = state.appointments.firstWhere(
        (a) => a['id'].toString() == existingId.toString(),
        orElse: () => {},
      );
      final currentStatus = (current['status'] ?? '').toUpperCase();

      // ── For statuses the backend won't allow direct update on,
      //    we transition through an allowed path first ──────────────────────
      if (currentStatus == 'IN_PROGRESS') {
        // IN_PROGRESS → CANCELLED (allowed per backend error message)
        try {
          await ApiService.updateAppointmentStatus(existingId, 'CANCELLED');
        } catch (_) {}
        // CANCELLED → SCHEDULED (allowed)
        try {
          await ApiService.updateAppointmentStatus(existingId, 'SCHEDULED');
        } catch (_) {}
      } else if (currentStatus == 'COMPLETED' || currentStatus == 'NO_SHOW') {
        // Try direct — if backend rejects, nothing more we can do
      }

      // ── Now perform the actual data update (status is now SCHEDULED) ─────
      await ApiService.updateAppointment(existingId, data);

      // ── Restore to IN_PROGRESS if that was the original status ───────────
      if (currentStatus == 'IN_PROGRESS') {
        try {
          // SCHEDULED → CONFIRMED → IN_PROGRESS
          await ApiService.updateAppointmentStatus(existingId, 'CONFIRMED');
          await ApiService.updateAppointmentStatus(existingId, 'IN_PROGRESS');
        } catch (_) {}
      }
    } else {
      await ApiService.createAppointment(data);
    }
    // The create/update call above already succeeded — a refresh hiccup
    // here must not be reported back to the caller as a save failure.
    try {
      await fetchAppointments();
    } catch (_) {}
  }
  // ── Consultation operations ────────────────────────────────────────────────

  Future<Map<String, dynamic>> startVisit(Map<String, dynamic> data) async {
    return ApiService.startVisit(data);
  }

  // ── Ensure a visit exists before any action that requires visit_id ────────
  //
  // Called lazily from: Start Recording, Save Draft, Complete Consultation.
  //
  // Flow:
  //   1. Return cached _visitId if already known (fast path).
  //   2. Fetch all visits → look for a match by appointment_id or patient_id.
  //   3. If still not found → POST /api/v1/clinic/visits to create one.
  //   4. Cache the result in [state.cachedVisitId] so subsequent calls are instant.
  //
  // Throws on failure so the caller can show an appropriate error to the user.

  void clearConsultationCache() {
    state = state.copyWith(
      cachedVisitId: 0,
      cachedReportId: 0,
      loadingVitals: false,
      vitals: const [],
    );
    debugPrint('🧹 clearConsultationCache: visit and report cache cleared');
  }

  Future<int> ensureVisitExists({
    required int appointmentId,
    int patientId = 0,
  }) async {
    // ── Fast path: already created ──────────────────────────────────────────
    if (state.cachedVisitId > 0) {
      debugPrint('⚡ ensureVisitExists: cached visitId=${state.cachedVisitId}');
      return state.cachedVisitId;
    }

    debugPrint(
      '🔍 ensureVisitExists: searching… apptId=$appointmentId patId=$patientId',
    );

    // ── Step 1: Check existing visits ────────────────────────────────────────
    final visits = await fetchVisits(patientId);
    Map<String, dynamic>? match;

    if (appointmentId > 0) {
      final s = appointmentId.toString();
      for (final v in visits) {
        if (v['appointment_id']?.toString() == s ||
            (v['appointment'] is Map &&
                (v['appointment'] as Map)['id']?.toString() == s)) {
          match = v;
          debugPrint('✅ ensureVisitExists: matched by appointment_id=$s');
          break;
        }
      }
    }

    if (match == null && patientId > 0) {
      final s = patientId.toString();
      for (final v in visits) {
        if (v['patient_id']?.toString() == s ||
            (v['patient'] is Map &&
                (v['patient'] as Map)['id']?.toString() == s)) {
          match = v;
          debugPrint('✅ ensureVisitExists: matched by patient_id=$s');
          break;
        }
      }
    }

    if (match != null) {
      final id = int.tryParse((match['id'] ?? 0).toString()) ?? 0;
      if (id > 0) {
        state = state.copyWith(cachedVisitId: id, cachedReportId: 0);
        debugPrint('✅ ensureVisitExists: found visitId=$id');
        return id;
      }
    }

    // ── Step 2: No visit found → create one ──────────────────────────────────
    //
    // Backend requires status = CONFIRMED or SCHEDULED before visit creation.
    // We attempt to advance/reset status, then POST the visit.
    debugPrint(
      '📝 ensureVisitExists: no existing visit → creating for apptId=$appointmentId',
    );

    if (appointmentId <= 0) {
      throw Exception('Cannot create visit: appointment_id is missing.');
    }

    // Attempt status reset (non-fatal if it fails)
    try {
      await ApiService.updateAppointmentStatus(appointmentId, 'CONFIRMED');
      debugPrint('🔄 ensureVisitExists: status → CONFIRMED');
    } catch (e) {
      debugPrint(
        '⚠️ ensureVisitExists: status update skipped (${extractError(e)})',
      );
    }

    // Create the visit
    final created = await ApiService.startVisit({
      'appointment_id': appointmentId,
    });
    final newId = int.tryParse((created['id'] ?? 0).toString()) ?? 0;
    if (newId <= 0) {
      throw Exception('Visit creation returned an invalid ID.');
    }

    // Advance to IN_PROGRESS (non-fatal)
    try {
      await ApiService.updateAppointmentStatus(appointmentId, 'IN_PROGRESS');
    } catch (_) {}

    state = state.copyWith(cachedVisitId: newId);
    debugPrint('✅ ensureVisitExists: created visitId=$newId');
    return newId;
  }
  // ── Transcribe & Save Report ───────────────────────────────────────────────
  //
  // Uses Endpoint 1: POST /api/v1/reports/transcribe
  //
  // What the backend does in one step:
  //   1. Receives audio file + visit_id
  //   2. Whisper transcribes the audio
  //   3. Medical NLP processes the transcription
  //   4. Saves a DRAFT medical report to the database
  //   5. Returns the full MedicalReportResponse
  //
  // visit_id is REQUIRED by this endpoint.
  // Returns the full report map including 'id' (report PK) for later PATCH.

  Future<Map<String, dynamic>> transcribeAndSaveReport({
    required File audioFile,
    required int visitId,
  }) async {
    debugPrint(
      '🎙️ Sending audio to backend for transcription… visitId=$visitId',
    );

    final response = await ApiService.transcribeAudio(
      audioFile: audioFile,
      visitId: visitId,
    );

    debugPrint('✅ Backend created DRAFT report: id=${response['id']}');
    debugPrint('📋 Report keys: ${response.keys.toList()}');

    return response;
  }

  // ── Update Voice Report ────────────────────────────────────────────────────
  //
  // Uses PATCH /api/v1/reports/medical-reports/{id}
  // Called from VoiceReportReviewPage after the doctor edits the DRAFT.

  Future<void> updateVoiceReport({
    required int reportId,
    required Map<String, dynamic> data,
  }) async {
    debugPrint('📝 Updating report #$reportId with: $data');
    await ApiService.updateMedicalReport(reportId, data);
    debugPrint('✅ Report #$reportId updated');
  }

  // ── Create medical report (used by Save Draft / Complete Consultation) ─────

  Future<void> createMedicalReport(Map<String, dynamic> data) async {
    await ApiService.createMedicalReport(data);
  }

  Future<void> updateVisitStatus(int visitId, String status) async {
    await ApiService.updateVisitStatus(visitId, status);
  }

  /// Finalizes a medical report, generating a PDF and triggering WhatsApp delivery.
  ///
  /// Per `Finalize_Report_Frontend_Guide.md` §2: the backend exposes two ways
  /// to reach FINALIZED (the dedicated `/finalize` endpoint, or `PATCH
  /// .../status` stepped manually) and both call the *same* internal delivery
  /// function exactly once when the report actually reaches FINALIZED — they
  /// are not additive. This app uses the dedicated `/finalize` endpoint
  /// exclusively (never the status-PATCH-to-FINALIZED path) so there is only
  /// ever one call capable of triggering delivery.
  ///
  /// `/finalize` rejects a report still in DRAFT (per guide §6, this is a
  /// guaranteed 400, not a maybe) so DRAFT reports are stepped to REVIEWED
  /// first via a plain status PATCH — that transition alone never reaches
  /// FINALIZED and therefore never triggers delivery. The result is exactly
  /// one network path per call, with no speculative retry/fallback dance.
  ///
  /// Returns a record with the finalized report map and [whatsappAttempted]
  /// — always `true` once this method returns successfully, since `/finalize`
  /// only fails the whole request for non-WhatsApp reasons; PDF/WhatsApp
  /// delivery itself is fire-and-forget server-side (report still ends up
  /// FINALIZED even if delivery fails), so the UI should treat WhatsApp
  /// failure as a soft warning rather than a hard error.
  ///
  /// Two additional guards close the timeout-induced duplicate-WhatsApp race
  /// found during the consultation finalization investigation:
  ///  1. In-flight dedup — if a finalize is already running for this exact
  ///     [reportId] (e.g. a doctor re-tapping "Complete Consultation" after
  ///     the first attempt appeared to hang), the second caller reuses the
  ///     same pending request instead of dispatching a new `POST /finalize`.
  ///  2. Verify-before-error — if `POST /finalize` itself errors (typically
  ///     a client-side timeout while the backend keeps processing), the
  ///     report is re-fetched before surfacing a failure. If the backend
  ///     actually completed it, this returns success instead of showing the
  ///     doctor a false failure that would otherwise prompt a manual retry.
  static final Map<int, Future<({Map<String, dynamic> report, bool whatsappAttempted})>>
      _inFlightFinalizes = {};

  Future<({Map<String, dynamic> report, bool whatsappAttempted})> finalizeReport(
    int reportId, {
    required String currentStatus,
  }) {
    final inFlight = _inFlightFinalizes[reportId];
    if (inFlight != null) {
      debugPrint(
        '⏳ finalizeReport: reportId=$reportId already has a finalize '
        'request in flight — reusing it instead of dispatching a second one.',
      );
      return inFlight;
    }

    final future = _finalizeReportOnce(reportId, currentStatus: currentStatus);
    _inFlightFinalizes[reportId] = future;
    future.whenComplete(() => _inFlightFinalizes.remove(reportId));
    return future;
  }

  Future<({Map<String, dynamic> report, bool whatsappAttempted})> _finalizeReportOnce(
    int reportId, {
    required String currentStatus,
  }) async {
    final status = currentStatus.toUpperCase();
    debugPrint(
      '📋 finalizeReport: reportId=$reportId currentStatus=$status',
    );

    if (status == 'DRAFT') {
      await ApiService.updateReportStatus(reportId, 'REVIEWED');
      debugPrint('🔄 finalizeReport: report #$reportId DRAFT → REVIEWED');
    }

    // POST /reports/medical-reports/{id}/finalize — the single call capable
    // of reaching FINALIZED in this app. Auto-steps REVIEWED → APPROVED →
    // FINALIZED, generates the PDF, and attempts WhatsApp delivery.
    try {
      final result = await ApiService.finalizeReport(reportId);
      debugPrint('✅ finalizeReport: report #$reportId is now FINALIZED');
      return (report: result, whatsappAttempted: true);
    } catch (e) {
      debugPrint(
        '⚠️ finalizeReport: POST /finalize errored '
        '(${extractError(e)}) — re-checking report #$reportId before '
        'surfacing a failure.',
      );
      try {
        final recheck = await ApiService.getMedicalReportById(reportId);
        final recheckStatus =
            (recheck['status'] ?? '').toString().toUpperCase();
        if (recheckStatus == 'FINALIZED') {
          debugPrint(
            '✅ finalizeReport: report #$reportId was actually FINALIZED '
            'server-side despite the client error — treating as success.',
          );
          return (report: recheck, whatsappAttempted: true);
        }
      } catch (_) {
        // Re-check itself failed too — fall through to the original error.
      }
      rethrow;
    }
  }

  // ── Vitals ─────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _toVitalsList(List<dynamic> d) {
    final result = <Map<String, dynamic>>[];
    for (final e in d) {
      if (e is Map) {
        result.add(Map<String, dynamic>.from(e));
      } else {
        debugPrint('⚠️ _toVitalsList: skipping non-Map entry: $e');
      }
    }
    return result;
  }

  Future<void> fetchVitals({
    required int appointmentId,
    required int patientId,
  }) async {
    state = state.copyWith(loadingVitals: true);
    List<dynamic> d = [];
    try {
      final visits = await ApiService.getVisits(
        patientId: patientId > 0 ? patientId : null,
      );
      debugPrint('🩺 fetchVitals: ${visits.length} visits for patId=$patientId');

      Map<String, dynamic>? matched;

      if (appointmentId > 0) {
        final s = appointmentId.toString();
        for (final v in visits) {
          if (v is! Map) continue;
          if (v['appointment_id']?.toString() == s) {
            matched = Map<String, dynamic>.from(v);
            break;
          }
          final appt = v['appointment'];
          if (appt is Map && appt['id']?.toString() == s) {
            matched = Map<String, dynamic>.from(v);
            break;
          }
        }
      }

      if (matched != null && ClinicHelpers.hasVitals(matched)) {
        d = [ClinicHelpers.visitToVitals(matched)];
        debugPrint('🩺 fetchVitals: found vitals in visit id=${matched['id']}');
      } else {
        debugPrint('🩺 fetchVitals: no vitals recorded for this visit yet');
      }
    } catch (e) {
      debugPrint('❌ fetchVitals error: $e');
      d = [];
    } finally {
      state = state.copyWith(vitals: _toVitalsList(d), loadingVitals: false);
    }
  }

  Future<Map<String, dynamic>> saveVitals(Map<String, dynamic> data) async {
    final result = await ApiService.createPatientVitals(data);
    return result;
  }

  Future<Map<String, dynamic>> updateVitals(
    int id,
    Map<String, dynamic> data,
  ) async {
    final result = await ApiService.updatePatientVitals(id, data);
    return result;
  }

  // ── Transcribe voice locally via AI service (no backend visit required) ────
  //
  // Sends audio to the AI micro-service and returns a structured string.
  // The result is shown on VoiceReportReviewPage for the doctor to edit
  // before calling saveVoiceReport() to persist it.

  // ── Transcribe voice locally via AI service ──────────────────────────────
  // Returns a structured string with sections matching the 4 fields the
  // VoiceReportReviewPage displays: Diagnosis, Medications, Recommendations,
  // Follow-up Instructions.  Uses _buildStructuredReport to map API field names onto
  // those labels regardless of what key names the backend returns.
  //
  // Strategy (each step only runs if the previous one fails):
  //   1. Attempt fresh transcription directly — succeeds when no prior report
  //      exists for this visit, or when the backend allows re-transcription.
  //   2. If blocked, try deleting the existing report then transcribe fresh.
  //   3. If delete is blocked (405), reset the existing report to DRAFT status
  //      and retry transcription.
  //   4. If all attempts fail, throw a clear error — NEVER silently fall back
  //      to old report data from a previous recording session.

  Future<({int reportId, String transcription})> transcribeAudioLocal({
    required File audioFile,
    required int visitId,
  }) async {
    if (visitId <= 0) {
      throw Exception(
        'visitId is required for transcription. '
        'Ensure a visit is started before recording.',
      );
    }

    // Reset cached report so a new recording always starts clean.
    state = state.copyWith(cachedReportId: 0);

    debugPrint(
      '🎙️ transcribeAudioLocal: new recording for visitId=$visitId '
      '— attempting fresh transcription.',
    );

    // ── Step 1: Attempt fresh transcription ──────────────────────────────────
    // Happy path: no prior report exists for this visit.
    try {
      final r = await ApiService.transcribeAudio(
        audioFile: audioFile,
        visitId: visitId,
      );
      debugPrint('🎙️ Transcription response keys: ${r.keys.toList()}');
      final reportId = int.tryParse((r['id'] ?? 0).toString()) ?? 0;
      if (reportId > 0) state = state.copyWith(cachedReportId: reportId);
      debugPrint('✅ Fresh transcription succeeded, reportId=$reportId');
      return (reportId: reportId, transcription: _buildTranscriptionString(r));
    } catch (firstError) {
      debugPrint(
        '⚠️ transcribeAudioLocal: fresh transcription blocked '
        '(${extractError(firstError)}) — fetching existing report.',
      );
    }

    // ── Retrieve the existing report with its current status ─────────────────
    // Only reached when fresh transcription returned 409 (one report per visit).
    // Sort by id descending so we always operate on the most recent report.
    List<Map<String, dynamic>> existingReports = [];
    try {
      final raw = await ApiService.getMedicalReports(visitId: visitId);
      existingReports = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
        ..sort((a, b) {
          final aId = int.tryParse((a['id'] ?? 0).toString()) ?? 0;
          final bId = int.tryParse((b['id'] ?? 0).toString()) ?? 0;
          return bId.compareTo(aId);
        });
    } catch (e) {
      debugPrint('⚠️ getMedicalReports failed: ${extractError(e)}');
    }

    if (existingReports.isEmpty) {
      throw Exception(
        'Transcription failed and no existing report was found for this visit. '
        'Please check your connection and try again.',
      );
    }

    final existingReport = existingReports.first;
    final existingReportId =
        int.tryParse((existingReport['id'] ?? 0).toString()) ?? 0;
    final existingStatus =
        (existingReport['status'] ?? '').toString().toUpperCase();

    debugPrint(
      '🔍 transcribeAudioLocal: existing report #$existingReportId '
      'status=$existingStatus for visitId=$visitId.',
    );

    if (existingReportId <= 0) {
      throw Exception('Existing report has an invalid ID. Please try again.');
    }

    // ── FINALIZED / CANCELLED: terminal states — re-recording is impossible ──
    // The backend permanently blocks deletion and all status transitions out of
    // these states. Surface a clear, actionable message instead of retrying.
    if (existingStatus == 'FINALIZED' || existingStatus == 'CANCELLED') {
      throw Exception(
        'This visit\'s medical report has already been $existingStatus '
        'and is a permanent record that cannot be modified or replaced. '
        'To record a new consultation, please start a new visit for this patient.',
      );
    }

    // ── Step 2: Regress status to DRAFT via the allowed state machine ─────────
    // Backend state machine: APPROVED → REVIEWED → DRAFT
    // FINALIZED and CANCELLED are already handled above.
    if (existingStatus == 'APPROVED') {
      try {
        await ApiService.updateReportStatus(existingReportId, 'REVIEWED');
        debugPrint('🔄 Regressed report #$existingReportId: APPROVED → REVIEWED.');
      } catch (e) {
        throw Exception(
          'Cannot re-record: the existing report is APPROVED and could not be '
          'reverted to REVIEWED. ${extractError(e)}',
        );
      }
    }

    if (existingStatus == 'APPROVED' || existingStatus == 'REVIEWED') {
      try {
        await ApiService.updateReportStatus(existingReportId, 'DRAFT');
        debugPrint('🔄 Regressed report #$existingReportId: REVIEWED → DRAFT.');
      } catch (e) {
        throw Exception(
          'Cannot re-record: the existing report could not be reset to DRAFT. '
          '${extractError(e)}',
        );
      }
    }

    // ── Step 3: Delete the DRAFT report, then transcribe fresh ────────────────
    // The report is now guaranteed to be DRAFT (either it was already, or we
    // just regressed it). The API allows deleting DRAFT reports.
    try {
      await ApiService.deleteMedicalReport(existingReportId);
      debugPrint(
        '🗑️ Deleted report #$existingReportId — submitting new audio.',
      );
    } catch (deleteError) {
      throw Exception(
        'Cannot re-record: the existing draft report could not be deleted. '
        '${extractError(deleteError)}',
      );
    }

    final r = await ApiService.transcribeAudio(
      audioFile: audioFile,
      visitId: visitId,
    );
    final reportId = int.tryParse((r['id'] ?? 0).toString()) ?? 0;
    if (reportId > 0) state = state.copyWith(cachedReportId: reportId);
    debugPrint('✅ Re-transcription succeeded, reportId=$reportId');
    return (reportId: reportId, transcription: _buildTranscriptionString(r));
  }

  // ── Helper: build transcription string from any AI response map ───────────
  String _buildTranscriptionString(Map<String, dynamic> r) {
    final structured = _buildStructuredReport(r);
    if (structured.isNotEmpty) return structured;

    final fb = StringBuffer();
    final diag = r['ai_diagnosis']?.toString().trim() ?? '';
    final recs = _formatApiValue(r['ai_recommendations'] ?? []);
    final meds = _formatApiValue(r['ai_medications'] ?? []);
    final notes = (r['ai_follow_up'] ?? r['doctor_notes'] ?? '')
        .toString()
        .trim();
    if (diag.isNotEmpty) fb.writeln('Diagnosis:\n$diag\n');
    if (recs.isNotEmpty) fb.writeln('Recommendations:\n$recs\n');
    if (meds.isNotEmpty) fb.writeln('Medications:\n$meds\n');
    if (notes.isNotEmpty) fb.writeln('Follow-up Instructions:\n$notes\n');
    return fb.toString().trim();
  }

  // ── Build structured report string from raw AI response map ───────────────
  // Maps every possible API key name onto one of 4 display labels.
  // Returns a string like:
  //   "Diagnosis:\nvalue\n\nRecommendations:\nvalue\n\n..."

  String _buildStructuredReport(Map<String, dynamic> r) {
    debugPrint('🔍 ALL API KEYS: ${r.keys.toList()}');
    final fieldMap = <String, List<String>>{
      'Diagnosis': [
        'ai_diagnosis',
        'diagnosis',
        'diagnoses',
        'dx',
        'impression',
        'final_diagnosis',
        'primary_diagnosis',
      ],
      'Recommendations': [
        'ai_recommendations',
        'treatment',
        'treatment_plan',
        'management',
        'plan',
        'clinical_management',
        'care_plan',
        'therapeutic_plan',
        'recommendations',
        'advice',
      ],
      'Medications': [
        'ai_medications',
        'prescriptions',
        'prescription',
        'medications',
        'medication_list',
        'drugs',
        'drug_list',
        'rx',
        'prescribed_medications',
        'meds',
      ],
      'Follow-up Instructions': [
        'ai_follow_up',
        'doctor_notes',
        'notes',
        'doctor_note',
        'clinical_notes',
        'remarks',
        'additional_notes',
        'follow_up',
        'follow_up_notes',
        'instructions',
        'comment',
        'comments',
      ],
    };

    bool anyFound = false;
    final buffer = StringBuffer();

    for (final entry in fieldMap.entries) {
      final label = entry.key;
      final candidates = entry.value;

      String value = '';
      for (final key in candidates) {
        final raw = r[key];
        if (raw == null) continue;
        final s = _formatApiValue(raw);
        if (s.isNotEmpty) {
          value = s;
          break;
        }
      }

      if (value.isEmpty) continue;
      anyFound = true;
      buffer.writeln('$label:');
      buffer.writeln(value);
      buffer.writeln();
    }

    return anyFound ? buffer.toString().trim() : '';
  }

  // ── Value formatter ────────────────────────────────────────────────────────

  String _formatApiValue(dynamic raw) {
    if (raw == null) return '';

    const placeholders = {
      'غير مذكور',
      'غير محدد',
      'not mentioned',
      'n/a',
      'na',
      'null',
      '-',
      '',
    };
    bool isPlaceholder(String s) =>
        placeholders.contains(s.trim().toLowerCase());

    if (raw is List) {
      if (raw.isEmpty) return '';

      if (raw.first is Map) {
        return raw
            .map((item) {
              final m = Map<String, dynamic>.from(item as Map);
              final name =
                  m['name'] ??
                  m['drug_name'] ??
                  m['medication'] ??
                  m['title'] ??
                  '';
              final dose = m['dose'] ?? m['dosage'] ?? '';
              final frequency = m['frequency'] ?? m['freq'] ?? '';
              final duration = m['duration'] ?? '';
              final notes = m['notes'] ?? m['note'] ?? '';

              final parts = <String>[];
              if (!isPlaceholder(name.toString())) parts.add(name.toString());
              if (!isPlaceholder(dose.toString())) parts.add('الجرعة: $dose');
              if (!isPlaceholder(frequency.toString()))
                parts.add('التكرار: $frequency');
              if (!isPlaceholder(duration.toString()))
                parts.add('المدة: $duration');
              if (!isPlaceholder(notes.toString()))
                parts.add('ملاحظات: $notes');
              return parts.join(' | ');
            })
            .where((s) => s.isNotEmpty)
            .join('\n');
      }

      return raw
          .map((e) => e.toString())
          .where((s) => !isPlaceholder(s))
          .join(', ');
    }

    final s = raw.toString().trim();
    return isPlaceholder(s) ? '' : s;
  }

  // ── Save voice report with correct backend field names ─────────────────────
  //
  // Backend POST /api/v1/reports/medical-reports accepts:
  //   visit_id           (int,    required)
  //   ai_diagnosis       (string, optional)
  //   ai_medications     (array,  optional) — objects: {name,dose,frequency,...}
  //   ai_recommendations (array,  optional) — strings
  //   ai_follow_up       (string, optional)
  //   doctor_notes       (string, optional)
  //
  // Fields the backend does NOT accept (formerly sent, now removed):
  //   content, title, report_type, status, patient_id
  //   (status is managed via PATCH /medical-reports/{id}/status separately)

  Future<void> saveVoiceReport({
    required int visitId,
    required String diagnosis,
    required List<String> recommendations,
    required String doctorNotes,
  }) async {
    await ApiService.createMedicalReport({
      'visit_id': visitId,
      'ai_diagnosis': diagnosis,
      'ai_medications': <Map<String, dynamic>>[],
      'ai_recommendations': recommendations,
      'doctor_notes': doctorNotes,
    });
  }

  // ── AI suggestion (local) ──────────────────────────────────────────────────

  String generateAISuggestion({
    required String complaint,
    // symptoms is accepted but optional so existing callers compile unchanged
    List<String> symptoms = const [],
    required String exam,
  }) {
    final syms = symptoms.isNotEmpty ? symptoms.join(', ') : '';
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

  // ── Medical imaging ────────────────────────────────────────────────────────

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

  // Returns the effective display status of an appointment, combining
  // AppointmentStatus with VisitStatus when the visit has started.
  // Mirrors DoctorTheme.getDisplayStatus() — kept here to avoid importing
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

  List<Map<String, dynamic>> filteredAppointments(DoctorApptFilter filter) {
    final q = state.apptSearchQuery.toLowerCase().trim();
    final now = DateTime.now();
    final result = state.appointments.where((a) {
      final dt = parseDate(a['start_time']);
      final s = (a['status'] ?? '').toUpperCase();        // raw AppointmentStatus
      final ds = _effectiveStatus(a);                     // visit-aware status
      bool ok = switch (filter) {
        DoctorApptFilter.all => true,
        // Use explicit year/month/day comparison — DateTime == checks the isUtc
        // flag too, so DateTime(y,m,d) == DateTime(y,m,d).toUtc() is FALSE even
        // when they represent the same day.  The explicit check is always safe.
        DoctorApptFilter.today =>
          dt != null &&
              dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day,
        // Waiting = appointment is IN_PROGRESS but the visit is still WAITING
        // (patient in waiting room, not yet called into the consultation room).
        DoctorApptFilter.waiting => ds == 'WAITING',
        // In Progress = appointment is IN_PROGRESS and the visit is also
        // IN_PROGRESS (patient is currently with the doctor).
        DoctorApptFilter.inProgress => ds == 'IN_PROGRESS',
        DoctorApptFilter.upcoming =>
          dt != null &&
              (dt.isAfter(now) ||
                  (dt.year == now.year &&
                      dt.month == now.month &&
                      dt.day == now.day)) &&
              s != 'CANCELLED' &&
              s != 'NO_SHOW' &&
              s != 'COMPLETED',
        DoctorApptFilter.urgent => a['is_urgent'] == true,
        DoctorApptFilter.completed => s == 'COMPLETED',
        DoctorApptFilter.cancelled => s == 'CANCELLED',
      };
      if (!ok) return false;
      if (q.isNotEmpty) return apptName(a).toLowerCase().contains(q);
      return true;
    }).toList();
    // Sort chronologically ascending (earliest appointment first)
    result.sort((a, b) {
      final da = parseDate(a['start_time']) ?? DateTime(9999);
      final db = parseDate(b['start_time']) ?? DateTime(9999);
      return da.compareTo(db);
    });
    return result;
  }

  // Counts are derived from allAppointments (the complete dataset), not from
  // the paginated display list, so they never change while scrolling and never
  // regress after a pull-to-refresh or post-mutation reload.
  int apptFilterCount(DoctorApptFilter filter) {
    final base = state.allAppointments.isNotEmpty
        ? state.allAppointments
        : state.appointments;
    final now = DateTime.now();
    return base.where((a) {
      final dt = parseDate(a['start_time']);
      final s = (a['status'] ?? '').toUpperCase();
      final ds = _effectiveStatus(a);
      return switch (filter) {
        DoctorApptFilter.all => true,
        DoctorApptFilter.today =>
          dt != null &&
              dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day,
        DoctorApptFilter.waiting => ds == 'WAITING',
        DoctorApptFilter.inProgress => ds == 'IN_PROGRESS',
        DoctorApptFilter.upcoming =>
          dt != null &&
              (dt.isAfter(now) ||
                  (dt.year == now.year &&
                      dt.month == now.month &&
                      dt.day == now.day)) &&
              s != 'CANCELLED' &&
              s != 'NO_SHOW' &&
              s != 'COMPLETED',
        DoctorApptFilter.urgent => a['is_urgent'] == true,
        DoctorApptFilter.completed => s == 'COMPLETED',
        DoctorApptFilter.cancelled => s == 'CANCELLED',
      };
    }).length;
  }

  // ── Computed: finance ──────────────────────────────────────────────────────

  Map<String, double> get financeStats {
    double total = 0, paid = 0;
    for (final a in state.appointments) {
      final s = (a['status'] ?? '').toUpperCase();
      if (s == 'CANCELLED' || s == 'NO_SHOW') continue;
      final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0;
      total += fee;
      if (a['is_paid'] == true) paid += fee;
    }
    return {'total': total, 'paid': paid, 'unpaid': total - paid};
  }

  List<Map<String, dynamic>> billableAppointments({bool unpaidOnly = false}) {
    final list =
        state.appointments
            .where((a) {
              final s = (a['status'] ?? '').toUpperCase();
              return s != 'CANCELLED' && s != 'NO_SHOW';
            })
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
      final s = (a['status'] ?? '').toUpperCase();
      return dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day &&
          s != 'CANCELLED' &&
          s != 'NO_SHOW';
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

  // ── Lab Reports ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchVisitReports(int visitId) async {
    try {
      final d = await ApiService.getMedicalReports(visitId: visitId);
      return List<Map<String, dynamic>>.from(d);
    } catch (e) {
      ErrorHandler.log(e, context: 'fetchVisitReports');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchLabReports(int visitId) async {
    try {
      final d = await ApiService.getVisitLabReports(visitId);
      return List<Map<String, dynamic>>.from(d);
    } catch (e) {
      ErrorHandler.log(e, context: 'fetchLabReports');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchVisitImages(int visitId) async {
    try {
      final d = await ApiService.getVisitImages(visitId);
      return List<Map<String, dynamic>>.from(d);
    } catch (e) {
      ErrorHandler.log(e, context: 'fetchVisitImages');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPatientMedicalReports(
    int patientId,
  ) async {
    try {
      final d = await ApiService.getMedicalReports(patientId: patientId);
      return List<Map<String, dynamic>>.from(d);
    } catch (e) {
      ErrorHandler.log(e, context: 'fetchPatientMedicalReports');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPatientMedicalImages(
    int patientId,
  ) async {
    try {
      final d = await ApiService.getPatientImages(patientId);
      return List<Map<String, dynamic>>.from(d);
    } catch (e) {
      ErrorHandler.log(e, context: 'fetchPatientMedicalImages');
      return [];
    }
  }

  Future<Map<int, List<Map<String, dynamic>>>> fetchLabReportsForVisits(
    List<int> visitIds,
  ) async {
    final result = <int, List<Map<String, dynamic>>>{};
    await Future.wait(visitIds.map((vid) async {
      try {
        final labs = await fetchLabReports(vid);
        if (labs.isNotEmpty) result[vid] = labs;
      } catch (_) {}
    }));
    return result;
  }

  Future<Map<String, dynamic>> uploadLabReport({
    required File pdfFile,
    required int visitId,
  }) async {
    return ApiService.uploadLabReport(pdfFile: pdfFile, visitId: visitId);
  }

  Future<Map<String, dynamic>> updateLabReport(
    int id,
    Map<String, dynamic> data,
  ) async {
    return ApiService.updateLabReport(id, data);
  }

  Future<Map<String, dynamic>> getLabReportById(int id) async {
    return ApiService.getLabReportById(id);
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<void> logout() async => ApiService.logout();

  // ── Utility helpers ────────────────────────────────────────────────────────

  String apptName(Map<String, dynamic> a) {
    final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
    final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
    final full = '$fn $ln'.trim();
    return full.isEmpty ? 'Unknown Patient' : full;
  }

  static DateTime? parseDate(dynamic v) => ClinicHelpers.parseDate(v);

  static String toIso8601WithTz(DateTime dt) =>
      ClinicHelpers.toIso8601WithTz(dt);

  static String extractError(Object e) => ErrorHandler.friendlyMessage(e);
} // ← DoctorViewModel closing brace

// ══════════════════════════════════════════════════════════════════════════════
enum DoctorApptFilter { today, waiting, inProgress, upcoming, urgent, completed, cancelled, all }
