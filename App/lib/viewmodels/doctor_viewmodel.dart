// ─────────────────────────────────────────────────────────────────────────────
// lib/viewmodels/doctor_viewmodel.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:Hakim/services/API_Service.dart';
import 'package:flutter/material.dart';
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
  final List<Map<String, dynamic>> vitals;
  final int? doctorId;

  final bool loadingPatients;
  final bool loadingAppointments;
  final bool loadingVitals;

  final bool patientsError;
  final bool appointmentsError;

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

  const DoctorState({
    this.patients = const [],
    this.appointments = const [],
    this.appointmentTypes = const [],
    this.reports = const [],
    this.vitals = const [],
    this.doctorId,
    this.loadingPatients = false,
    this.loadingAppointments = false,
    this.loadingVitals = false,
    this.patientsError = false,
    this.appointmentsError = false,
    this.patientSearchQuery = '',
    this.apptSearchQuery = '',
    this.lastCreatedPatient,
    this.patientsHasMore = true,
    this.patientsSkip = 0,
    this.loadingMorePatients = false,
    this.appointmentsHasMore = true,
    this.appointmentsSkip = 0,
    this.loadingMoreAppointments = false,
  });

  DoctorState copyWith({
    List<Map<String, dynamic>>? patients,
    List<Map<String, dynamic>>? appointments,
    List<Map<String, dynamic>>? appointmentTypes,
    List<Map<String, dynamic>>? reports,
    List<Map<String, dynamic>>? vitals,
    int? doctorId,
    bool? loadingPatients,
    bool? loadingAppointments,
    bool? loadingVitals,
    bool? patientsError,
    bool? appointmentsError,
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
  }) {
    return DoctorState(
      patients: patients ?? this.patients,
      appointments: appointments ?? this.appointments,
      appointmentTypes: appointmentTypes ?? this.appointmentTypes,
      reports: reports ?? this.reports,
      vitals: vitals ?? this.vitals,
      doctorId: doctorId ?? this.doctorId,
      loadingPatients: loadingPatients ?? this.loadingPatients,
      loadingAppointments: loadingAppointments ?? this.loadingAppointments,
      loadingVitals: loadingVitals ?? this.loadingVitals,
      patientsError: patientsError ?? this.patientsError,
      appointmentsError: appointmentsError ?? this.appointmentsError,
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
  ]);

  void setDoctorId(int id) {
    if (id > 0) state = state.copyWith(doctorId: id);
  }

  // ── Patients ───────────────────────────────────────────────────────────────

  Future<void> fetchPatients() async {
    state = state.copyWith(
      loadingPatients: true,
      patientsError: false,
      patientsSkip: 0,
      patientsHasMore: true,
    );
    try {
      final d = await ApiService.getPatients(skip: 0, limit: _pageSize);
      state = state.copyWith(
        patients: List<Map<String, dynamic>>.from(d),
        loadingPatients: false,
        patientsSkip: d.length,
        patientsHasMore: d.length >= _pageSize,
      );
    } catch (_) {
      state = state.copyWith(loadingPatients: false, patientsError: true);
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
    } catch (_) {
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

      // Read current chronic conditions from backend-provided patient_conditions.
      // The list endpoint embeds this array in each PatientResponse object.
      final patient = state.patients.firstWhere(
        (p) => p['id'].toString() == patientId.toString(),
        orElse: () => {},
      );
      final currentConditions = _extractChronicConditions(patient);
      final currentNamesLower =
          currentConditions.map((c) => _conditionName(c).toLowerCase()).toSet();

      final newNamesLower =
          newDiseaseNames.map((n) => n.toLowerCase()).toSet();

      final toAdd = newDiseaseNames
          .where((n) => !currentNamesLower.contains(n.toLowerCase()))
          .toList();
      final toRemove = currentConditions
          .where((c) => !newNamesLower.contains(_conditionName(c).toLowerCase()))
          .toList();

      // Remove deselected conditions — DELETE endpoint takes condition_id
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

      // Add newly selected conditions
      for (final name in toAdd) {
        // Find exact match in catalogue first
        Map<String, dynamic>? match;
        for (final c in catalog) {
          if ((c['name'] ?? '').toString().toLowerCase() ==
              name.toLowerCase()) {
            match = c;
            break;
          }
        }
        // Fuzzy fallback
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
        // Auto-create in catalogue if not found
        if (match == null || match['id'] == null) {
          try {
            match = await ApiService.createCondition(name, 'CHRONIC');
            catalog.add(match);
          } catch (_) {
            // 409 = already exists — fetch by name to get the id
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
          } catch (_) {} // 409 = already assigned, safe to ignore
        }
      }
    } catch (_) {}
  }

  // Extracts chronic condition assignment objects from a PatientResponse map.
  // Handles both flattened ({ name, category, condition_id }) and nested
  // ({ condition: { name, category }, condition_id }) response shapes.
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
      if (cat == 'CHRONIC') {
        result.add(Map<String, dynamic>.from(item));
      }
    }
    return result;
  }

  static String _conditionName(Map<String, dynamic> c) =>
      (c['name'] ?? (c['condition'] as Map?)?['name'] ?? '').toString();

  Future<void> deletePatient(int id) async {
    await ApiService.deletePatient(id);
    await fetchPatients();
  }

  Future<void> fetchReports(int patientId) async {
    try {
      final d = await ApiService.getMedicalReports(patientId: patientId);
      state = state.copyWith(reports: List<Map<String, dynamic>>.from(d));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchVisits(int patientId) async {
    try {
      final d = await ApiService.getVisits(
        patientId: patientId > 0 ? patientId : null,
      );
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
    state = state.copyWith(
      loadingAppointments: true,
      appointmentsError: false,
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
        loadingAppointments: false,
        appointmentsSkip: d.length,
        appointmentsHasMore: d.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        loadingAppointments: false,
        appointmentsError: true,
      );
      rethrow;
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
    } catch (_) {
      state = state.copyWith(loadingMoreAppointments: false);
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
    await fetchAppointments();
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
  //   4. Cache the result in [_cachedVisitId] so subsequent calls are instant.
  //
  // Throws on failure so the caller can show an appropriate error to the user.

  // ── In-memory cache (lives for the lifetime of the ViewModel instance) ─────
  int _cachedVisitId = 0;
  int _cachedReportId = 0;
  void clearConsultationCache() {
    _cachedVisitId = 0;
    _cachedReportId = 0;
    state = state.copyWith(loadingVitals: false, vitals: const []);
    debugPrint('🧹 clearConsultationCache: visit and report cache cleared');
  }

  Future<int> ensureVisitExists({
    required int appointmentId,
    int patientId = 0,
  }) async {
    // ── Fast path: already created ──────────────────────────────────────────
    if (_cachedVisitId > 0) {
      debugPrint('⚡ ensureVisitExists: cached visitId=$_cachedVisitId');
      return _cachedVisitId;
    }

    debugPrint(
      '🔍 ensureVisitExists: searching… apptId=$appointmentId patId=$patientId',
    );

    // ── Step 1: Check existing visits ────────────────────────────────────────
    final visits = await fetchVisits(0);
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
        _cachedVisitId = id;
        _cachedReportId = 0; // reset report cache for the new visit
        debugPrint('✅ ensureVisitExists: created visitId=$id');
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

    _cachedVisitId = newId;
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
  /// The report must be in REVIEWED status. If it is still DRAFT, this method
  /// advances it to REVIEWED first, then calls finalize.
  ///
  /// Returns a record with the finalized report map and a boolean [whatsappSent]
  /// that is always `true` from the API's perspective — the backend fires WhatsApp
  /// delivery asynchronously and will FINALIZE the report regardless of whether
  /// the WhatsApp call succeeds, so the UI should show a soft warning rather than
  /// treating WhatsApp failure as a hard error.
  Future<({Map<String, dynamic> report, bool whatsappAttempted})> finalizeReport(
    int reportId, {
    required String currentStatus,
  }) async {
    final status = currentStatus.toUpperCase();
    debugPrint(
      '📋 finalizeReport: reportId=$reportId currentStatus=$status',
    );

    // Advance DRAFT → REVIEWED so finalize endpoint accepts the request.
    if (status == 'DRAFT') {
      debugPrint('🔄 finalizeReport: advancing DRAFT → REVIEWED');
      await ApiService.updateReportStatus(reportId, 'REVIEWED');
    }

    // POST /reports/medical-reports/{id}/finalize
    // This auto-steps REVIEWED → APPROVED → FINALIZED, generates PDF,
    // and attempts WhatsApp delivery (fire-and-forget, non-fatal).
    final result = await ApiService.finalizeReport(reportId);
    debugPrint('✅ finalizeReport: report #$reportId is now FINALIZED');
    return (report: result, whatsappAttempted: true);
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

      if (matched != null && _hasVitals(matched)) {
        d = [_visitToVitals(matched)];
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
    };
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
    _cachedReportId = 0;

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
      if (reportId > 0) _cachedReportId = reportId;
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
    if (reportId > 0) _cachedReportId = reportId;
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
    return state.appointments.where((a) {
      final dt = parseDate(a['start_time']);
      final s = (a['status'] ?? '').toUpperCase();
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
        DoctorApptFilter.upcoming =>
          dt != null &&
              dt.isAfter(now) &&
              s != 'CANCELLED' &&
              s != 'NO_SHOW',
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

  Future<List<Map<String, dynamic>>> fetchLabReports(int visitId) async {
    try {
      final d = await ApiService.getVisitLabReports(visitId);
      return List<Map<String, dynamic>>.from(d);
    } catch (_) {
      return [];
    }
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
} // ← DoctorViewModel closing brace

// ══════════════════════════════════════════════════════════════════════════════
enum DoctorApptFilter { all, today, upcoming, urgent, completed }
