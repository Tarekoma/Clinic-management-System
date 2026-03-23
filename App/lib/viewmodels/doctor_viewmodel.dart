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

  void clearLastCreatedPatient() =>
      state = state.copyWith(eraseLastCreatedPatient: true);

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
    state = state.copyWith(loadingAppointments: true, appointmentsError: false);
    try {
      final d = await ApiService.getAppointments();
      final list = List<Map<String, dynamic>>.from(d);
      // Sort DESCENDING — newest/furthest-future at the top so a newly
      // created appointment is immediately visible without scrolling.
      list.sort((a, b) {
        final da = parseDate(a['start_time']);
        final db = parseDate(b['start_time']);
        return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
      });
      state = state.copyWith(appointments: list, loadingAppointments: false);
    } catch (e) {
      state = state.copyWith(
        loadingAppointments: false,
        appointmentsError: true,
      );
      rethrow; // let createOrUpdateAppointment surface errors to the form
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
        debugPrint('✅ ensureVisitExists: using existing visitId=$id');
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

  // ── Transcribe voice locally via AI service (no backend visit required) ────
  //
  // Sends audio to the AI micro-service and returns a structured string.
  // The result is shown on VoiceReportReviewPage for the doctor to edit
  // before calling saveVoiceReport() to persist it.

  // ── Transcribe voice locally via AI service ──────────────────────────────
  // Returns a structured string with sections matching the 4 fields the
  // VoiceReportReviewPage displays: Diagnosis, Treatment, Prescriptions,
  // Doctor Notes.  Uses _buildStructuredReport to map API field names onto
  // those labels regardless of what key names the backend returns.

  Future<String> transcribeAudioLocal({required File audioFile}) async {
    final r = await AIService.transcribeReport(audioFile);
    debugPrint('🎙️ AI RAW RESPONSE keys: ${r.keys.toList()}');

    final structured = _buildStructuredReport(r);
    if (structured.isNotEmpty) return structured;

    // Last resort: join all non-empty values as plain text
    return r.entries
        .where(
          (e) =>
              e.value != null &&
              e.value.toString().trim().isNotEmpty &&
              e.value.toString() != 'null',
        )
        .map((e) => e.value.toString().trim())
        .join('\n\n');
  }

  // ── Build structured report string from raw AI response map ───────────────
  // Maps every possible API key name onto one of 4 display labels.
  // Returns a string like:
  //   "Diagnosis:\nvalue\n\nTreatment:\nvalue\n\n..."

  String _buildStructuredReport(Map<String, dynamic> r) {
    debugPrint('🔍 ALL API KEYS: \${r.keys.toList()}');
    final fieldMap = <String, List<String>>{
      'Diagnosis': [
        'diagnosis',
        'diagnoses',
        'dx',
        'impression',
        'final_diagnosis',
        'primary_diagnosis',
        'ai_diagnosis',
      ],
      'Treatment': [
        'prescriptions',
        'prescription',
        'medications',
        'medication_list',
        'drugs',
        'drug_list',
        'rx',
        'prescribed_medications',
        'meds',
        'ai_medications',
      ],
      'Prescriptions': [
        'treatment',
        'treatment_plan',
        'management',
        'plan',
        'clinical_management',
        'care_plan',
        'therapeutic_plan',
        'recommendations',
        'advice',
        'ai_recommendations',
      ],
      'Doctor Notes': [
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
        'ai_follow_up',
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
