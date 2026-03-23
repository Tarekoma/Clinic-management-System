// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/consultation_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:Hakim/views/doctor/consultation/voice_report_review_page.dart';
import 'package:Hakim/views/doctor/consultation/ai_tab.dart';
import 'package:Hakim/views/doctor/consultation/voice_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';
import 'package:Hakim/views/doctor/consultation/ai_imaging_tab.dart';

typedef _T = DoctorTheme;

class DoctorConsultationPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> appointment;
  final UserProfile doctorProfile;

  const DoctorConsultationPage({
    required this.appointment,
    required this.doctorProfile,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DoctorConsultationPage> createState() =>
      _DoctorConsultationPageState();
}

class _DoctorConsultationPageState extends ConsumerState<DoctorConsultationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  Map<String, dynamic>? _visit;
  bool _startingVisit = true;
  bool _saving = false;
  bool _resolvingVisit = false;

  final _notesCtrl = TextEditingController();
  bool _aiLoading = false;
  String? _aiResult;

  File? _imagingSelectedImage;
  bool _imagingAnalysisLoading = false;
  String? _imagingAnalysisResult;

  // ── IDs ───────────────────────────────────────────────────────────────────

  int get _patId =>
      int.tryParse(
        (widget.appointment['patient_id'] ??
                widget.appointment['patient']?['id'] ??
                '0')
            .toString(),
      ) ??
      0;

  int get _apptId =>
      int.tryParse(
        (widget.appointment['id'] ??
                widget.appointment['appointment_id'] ??
                widget.appointment['appt_id'] ??
                widget.appointment['pk'] ??
                '0')
            .toString(),
      ) ??
      0;

  int get _visitId => int.tryParse((_visit?['id'] ?? '0').toString()) ?? 0;

  String get _patientName {
    final fn =
        widget.appointment['patient_first_name'] ??
        widget.appointment['patient']?['first_name'] ??
        '';
    final ln =
        widget.appointment['patient_last_name'] ??
        widget.appointment['patient']?['last_name'] ??
        '';
    final full = '$fn $ln'.trim();
    return full.isEmpty ? 'Unknown Patient' : full;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _initVisit();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _initVisit() async {
    await _resolveVisit();
    if (mounted) setState(() => _startingVisit = false);
  }

  // ── _resolveVisit ─────────────────────────────────────────────────────────

  Future<void> _resolveVisit() async {
    if (_visitId > 0) return;
    if (_resolvingVisit) return;
    _resolvingVisit = true;

    try {
      final vm = ref.read(doctorViewModelProvider.notifier);

      List<Map<String, dynamic>> visits = [];
      if (_patId > 0) {
        try {
          visits = await vm.fetchVisits(_patId);
          debugPrint(
            '🔍 _resolveVisit: ${visits.length} visits for patientId=$_patId',
          );
        } catch (e) {
          debugPrint(
            '⚠️ fetchVisits(patId) failed: ${DoctorViewModel.extractError(e)}',
          );
        }
      }

      Map<String, dynamic>? match;

      if (_apptId > 0) {
        final s = _apptId.toString();
        for (final v in visits) {
          if (v['appointment_id']?.toString() == s) {
            match = v;
            debugPrint('✅ matched by appointment_id=$s');
            break;
          }
        }
      }

      if (match == null && _apptId > 0) {
        final s = _apptId.toString();
        for (final v in visits) {
          final appt = v['appointment'];
          if (appt is Map && appt['id']?.toString() == s) {
            match = v;
            debugPrint('✅ matched by appointment.id=$s');
            break;
          }
        }
      }

      if (match == null && _patId > 0) {
        final s = _patId.toString();
        for (final v in visits) {
          if (v['patient_id']?.toString() == s) {
            match = v;
            debugPrint('✅ matched by patient_id=$s');
            break;
          }
        }
      }

      if (match == null && _patId > 0) {
        final s = _patId.toString();
        for (final v in visits) {
          final pat = v['patient'];
          if (pat is Map && pat['id']?.toString() == s) {
            match = v;
            debugPrint('✅ matched by patient.id=$s');
            break;
          }
        }
      }

      if (match == null) {
        for (final v in visits) {
          if ((v['status'] ?? '').toString().toUpperCase() == 'IN_PROGRESS') {
            match = v;
            debugPrint('⚠️ matched by status=IN_PROGRESS (last resort)');
            break;
          }
        }
      }

      if (match != null && mounted) {
        setState(() => _visit = match);
        debugPrint('✅ _resolveVisit: visitId=$_visitId');
        return;
      }

      if (_apptId <= 0) return;

      final currentStatus = (widget.appointment['status'] ?? '')
          .toString()
          .toUpperCase();

      if (currentStatus == 'IN_PROGRESS') {
        debugPrint(
          '🔴 Broken state: appointment $_apptId is IN_PROGRESS with no visit.',
        );
        return;
      }

      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          await ApiService.updateAppointmentStatus(_apptId, 'CONFIRMED');
          break;
        } catch (e) {
          if (attempt == 2) return;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        final v = await ApiService.startVisit({'appointment_id': _apptId});
        if (mounted) setState(() => _visit = v);
        debugPrint('✅ _resolveVisit: created visitId=$_visitId');
        try {
          await ApiService.updateAppointmentStatus(_apptId, 'IN_PROGRESS');
        } catch (_) {}
      } catch (e) {
        debugPrint('⚠️ startVisit failed: ${DoctorViewModel.extractError(e)}');
      }
    } finally {
      _resolvingVisit = false;
    }
  }

  // ── _ensureVisit ──────────────────────────────────────────────────────────

  Future<int> _ensureVisit() async {
    if (_visitId > 0) return _visitId;
    await _resolveVisit();
    if (_visitId > 0) return _visitId;

    final currentStatus = (widget.appointment['status'] ?? '')
        .toString()
        .toUpperCase();

    if (currentStatus == 'IN_PROGRESS') {
      throw Exception(
        'This appointment has no linked visit record.\n'
        'Please contact the clinic admin to fix appointment #$_apptId.',
      );
    }
    throw Exception('Could not start a visit. Please try again.');
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? _T.urgent : _T.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── AI Imaging ────────────────────────────────────────────────────────────

  Future<void> _pickImgForAI(ImageSource src) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: src,
        imageQuality: 85,
      );
      if (picked == null) return;
      if (mounted) setState(() => _imagingSelectedImage = File(picked.path));
    } catch (e) {
      _snack('Could not pick image: $e', err: true);
    }
  }

  void _analyzeImagePlaceholder() => _snack('AI analysis coming soon.');

  // ── AI suggestion ─────────────────────────────────────────────────────────

  Future<void> _runAI() async {
    setState(() => _aiLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final result = ref
          .read(doctorViewModelProvider.notifier)
          // FIX: removed `symptoms` — param is now optional with default []
          // so both old and new call sites compile. Passing it explicitly is
          // still fine: .generateAISuggestion(complaint:'', symptoms:[], exam:'')
          .generateAISuggestion(complaint: '', exam: '');
      if (mounted) setState(() => _aiResult = result);
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _applyAIToDiagnosis(String s) => _snack('AI suggestion noted');

  // ── Voice recorded ────────────────────────────────────────────────────────

  Future<void> _onVoiceRecorded(String audioPath) async {
    setState(() => _aiLoading = true);
    try {
      final vm = ref.read(doctorViewModelProvider.notifier);
      final transcription = await vm.transcribeAudioLocal(
        audioFile: File(audioPath),
      );

      if (!mounted) return;
      if (transcription.isEmpty) {
        _snack('AI returned an empty transcription.', err: true);
        return;
      }

      final int visitId;
      try {
        visitId = await _ensureVisit();
      } catch (e) {
        _snack(DoctorViewModel.extractError(e), err: true);
        return;
      }

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => VoiceReportReviewPage(
            visitId: visitId,
            aiTranscription: transcription,
          ),
        ),
      );

      if (saved == true && mounted) _snack('Voice report saved.');
    } catch (e) {
      if (mounted) {
        _snack(
          'Transcription failed: ${DoctorViewModel.extractError(e)}',
          err: true,
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  //
  // FIX: Previously sent wrong fields to the backend:
  //   ✗ 'content'    → not a valid field for POST /reports/medical-reports
  //   ✗ 'patient_id' → not accepted by this endpoint
  //   ✗ 'status'     → cannot be set on creation; managed via PATCH /status
  //
  // Correct fields (from Postman collection):
  //   ✓ 'visit_id'    (required)
  //   ✓ 'doctor_notes' (free-text notes from the doctor)
  //   ✓ 'ai_diagnosis', 'ai_medications', 'ai_recommendations', 'ai_follow_up'
  //      (all optional; left empty for the quick-save flow)

  Future<void> _save({required bool complete}) async {
    setState(() => _saving = true);
    try {
      final int visitId;
      try {
        visitId = await _ensureVisit();
      } catch (e) {
        _snack(DoctorViewModel.extractError(e), err: true);
        return;
      }

      final vm = ref.read(doctorViewModelProvider.notifier);
      final notes = _notesCtrl.text.trim();

      await vm.createMedicalReport({
        'visit_id': visitId,
        'doctor_notes': notes.isNotEmpty ? notes : 'Consultation notes',
        'ai_diagnosis': '',
        'ai_medications': <Map<String, dynamic>>[],
        'ai_recommendations': <String>[],
        'ai_follow_up': '',
      });

      if (complete) {
        await vm.updateVisitStatus(visitId, 'COMPLETED');
        try {
          await ApiService.updateAppointmentStatus(_apptId, 'COMPLETED');
        } catch (_) {}
      }

      _snack(complete ? 'Consultation completed!' : 'Draft saved');
      if (complete && mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Error: ${DoctorViewModel.extractError(e)}', err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Confirm exit ──────────────────────────────────────────────────────────

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave Consultation?'),
        content: const Text('Save a draft before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _save(complete: false);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Draft'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.urgent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bgPage,
      body: Column(
        children: [
          _buildHeader(),
          _buildPatientBar(),
          _buildTabBar(),
          Expanded(
            child: _startingVisit
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: _T.navy,
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Starting consultation...',
                          style: TextStyle(fontSize: 13, color: _T.textS),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabs,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // FIX: voiceTab is a function widget from voice_tab.dart
                      voiceTab(
                        notesCtrl: _notesCtrl,
                        transcribing: _aiLoading,
                        onTranscribe: _onVoiceRecorded,
                      ),
                      AIImagingTab(
                        selectedImage: _imagingSelectedImage,
                        analysisLoading: _imagingAnalysisLoading,
                        analysisResult: _imagingAnalysisResult,
                        onPickImage: _pickImgForAI,
                        onAnalyze: _analyzeImagePlaceholder,
                      ),
                      // NOTE: class name must match what ai_tab.dart exports.
                      // The original code used 'AITabb' — replace this with
                      // the exact class name from ai_tab.dart once confirmed.
                      AITabb(
                        aiLoading: _aiLoading,
                        aiResult: _aiResult,
                        onRunAI: _runAI,
                        onApplyToDiagnosis: _applyAIToDiagnosis,
                        onVoiceRecorded: _onVoiceRecorded,
                      ),
                    ],
                  ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(gradient: _T.gNavy),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
              onPressed: _confirmExit,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consultation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd MMM yyyy  •  hh:mm a',
                    ).format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (_visit != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 7,
                      height: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF69F0AE),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _buildPatientBar() {
    final type =
        widget.appointment['appointment_type_name'] ??
        widget.appointment['appointment_type'] ??
        'Consultation';
    final urgent = widget.appointment['is_urgent'] == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      color: const Color(0xFF0F4C75),
      child: Row(
        children: [
          DoctorAvatar(name: _patientName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (_) {
              final diseases = List<String>.from(
                widget.appointment['patient']?['chronic_diseases'] ?? [],
              );
              if (diseases.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Wrap(
                  spacing: 4,
                  children: diseases
                      .map(
                        (d) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          if (urgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: _T.urgent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() => Container(
    color: _T.bgCard,
    child: TabBar(
      controller: _tabs,
      labelColor: _T.navy,
      unselectedLabelColor: _T.textM,
      indicatorColor: _T.navy,
      indicatorWeight: 2.5,
      isScrollable: true,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      tabs: const [
        Tab(text: 'Voice'),
        Tab(text: 'AI Imaging'),
        Tab(text: 'AI Assist'),
      ],
    ),
  );

  Widget _buildActions() => Container(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 14,
      bottom: MediaQuery.of(context).padding.bottom + 14,
    ),
    decoration: BoxDecoration(
      color: _T.bgCard,
      boxShadow: [
        BoxShadow(
          color: _T.navy.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => _save(complete: false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _T.navy),
              foregroundColor: _T.navy,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Draft',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _saving ? null : () => _save(complete: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Complete Consultation',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
          ),
        ),
      ],
    ),
  );
}
