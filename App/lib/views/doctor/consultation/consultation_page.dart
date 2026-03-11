// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/consultation_page.dart
//
// Entry-point for the full-screen consultation route.
//
// Responsibilities of THIS file only:
//   • Own every piece of mutable consultation state (controllers, lists, flags)
//   • Manage the TabController lifetime
//   • Render the gradient header, patient info bar, tab bar, bottom action bar
//   • Delegate the four tab bodies to their respective tab widgets
//   • Contain all async logic (_initVisit, _save, _transcribe, _pickImg,
//     _runAI) — delegating API calls to DoctorViewModel
//
// Zero ApiService calls. Zero UI layout code for individual tabs.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';

import 'package:Hakim/views/doctor/consultation/notes_tab.dart';
import 'package:Hakim/views/doctor/consultation/ai_imaging_tab.dart';
import 'package:Hakim/views/doctor/consultation/ai_tab.dart';

typedef _T = DoctorTheme;

// ─────────────────────────────────────────────────────────────────────────────

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
  // ── Tab controller ────────────────────────────────────────────────────────
  late TabController _tabs;

  // ── Visit state ───────────────────────────────────────────────────────────
  Map<String, dynamic>? _visit;
  bool _startingVisit = true;
  bool _saving = false;

  // ── Notes / voice state ───────────────────────────────────────────────────
  final _notesCtrl = TextEditingController();
  bool _transcribing = false;

  // ── AI state ──────────────────────────────────────────────────────────────
  bool _aiLoading = false;
  String? _aiResult;

  // ── AI Imaging state ──────────────────────────────────────────────────────
  File? _imagingSelectedImage;
  bool _imagingAnalysisLoading = false;
  String? _imagingAnalysisResult;

  // ── Computed IDs ─────────────────────────────────────────────────────────

  int get _patId =>
      int.tryParse(
        (widget.appointment['patient_id'] ??
                widget.appointment['patient']?['id'] ??
                '0')
            .toString(),
      ) ??
      0;

  int get _apptId =>
      int.tryParse((widget.appointment['id'] ?? '0').toString()) ?? 0;

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

  // ── Visit initialisation ──────────────────────────────────────────────────

  Future<void> _initVisit() async {
    final vm = ref.read(doctorViewModelProvider.notifier);
    try {
      if (_apptId > 0) {
        await vm.updateAppointmentStatus(_apptId, 'IN_PROGRESS');
      }
      final v = await vm.startVisit({
        'patient_id': _patId,
        if (_apptId > 0) 'appointment_id': _apptId,
        'status': 'IN_PROGRESS',
      });
      if (mounted) setState(() => _visit = v);
    } catch (e) {
      _snack(
        'Could not start visit: ${DoctorViewModel.extractError(e)}',
        err: true,
      );
    } finally {
      if (mounted) setState(() => _startingVisit = false);
    }
  }

  // ── Snackbar helper ───────────────────────────────────────────────────────

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

  // ── Notes / voice callbacks (passed into NotesTab) ────────────────────────

  Future<void> _transcribe(String path) async {
    if (_visitId == 0) {
      _snack('Visit not started yet.', err: true);
      return;
    }
    setState(() => _transcribing = true);
    try {
      final vm = ref.read(doctorViewModelProvider.notifier);
      final txt = await vm.transcribeAudio(
        audioFile: File(path),
        visitId: _visitId,
      );
      if (txt.isNotEmpty && mounted) {
        setState(
          () => _notesCtrl.text =
              '${_notesCtrl.text}\n\n[Voice Transcript]\n$txt'.trim(),
        );
        _snack('Transcription added to notes');
      }
    } catch (e) {
      _snack(
        'Transcription failed: ${DoctorViewModel.extractError(e)}',
        err: true,
      );
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  // ── AI Imaging callbacks (passed into AIImagingTab) ───────────────────────

  /// Picks an image for AI Imaging tab and stores it for preview.
  /// Does NOT call the old pickAndAnalyzeImage — the AI backend is not
  /// connected yet. Image analysis will be wired in a future iteration.
  Future<void> _pickImgForAI(ImageSource src) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: src, imageQuality: 85);
      if (picked == null) return; // user cancelled
      if (mounted) {
        setState(() => _imagingSelectedImage = File(picked.path));
      }
    } catch (e) {
      _snack('Could not pick image: $e', err: true);
    }
  }

  /// Placeholder for the "Analyze Image" button in AIImagingTab.
  /// Shows an informational snackbar until the backend AI is ready.
  void _analyzeImagePlaceholder() {
    _snack('AI analysis coming soon — service not connected yet.');
  }

  Future<void> _runAI() async {
    setState(() => _aiLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final vm = ref.read(doctorViewModelProvider.notifier);
      final result = vm.generateAISuggestion(
        complaint: '',
        symptoms: [],
        exam: '',
      );
      if (mounted) setState(() => _aiResult = result);
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  /// Called from AITab "Apply to Diagnosis" button.
  /// Clinical tab has been removed — suggestion is shown via snackbar.
  void _applyAIToDiagnosis(String suggestion) {
    _snack('AI suggestion noted');
  }

  // ── Save / exit ───────────────────────────────────────────────────────────

  Future<void> _save({required bool complete}) async {
    if (_visitId == 0) {
      _snack('Visit not started.', err: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final content = _notesCtrl.text.isNotEmpty
          ? 'Notes: ${_notesCtrl.text.trim()}'
          : '';

      final vm = ref.read(doctorViewModelProvider.notifier);

      await vm.createMedicalReport({
        'visit_id': _visitId,
        'patient_id': _patId,
        'content': content,
        'status': complete ? 'COMPLETED' : 'DRAFT',
      });

      if (complete) {
        await vm.updateVisitStatus(_visitId, 'COMPLETED');
        if (_apptId > 0) {
          await vm.updateAppointmentStatus(_apptId, 'COMPLETED');
        }
      }
      _snack(complete ? 'Consultation completed!' : 'Draft saved');
      if (complete && mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Error: ${DoctorViewModel.extractError(e)}', err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
                      // ── Tab 0 — Voice ─────────────────────────────────
                      NotesTab(
                        notesCtrl: _notesCtrl,
                        transcribing: _transcribing,
                        onTranscribe: _transcribe,
                      ),
                      // ── Tab 1 — AI Imaging ────────────────────────────
                      AIImagingTab(
                        selectedImage: _imagingSelectedImage,
                        analysisLoading: _imagingAnalysisLoading,
                        analysisResult: _imagingAnalysisResult,
                        onPickImage: _pickImgForAI,
                        onAnalyze: _analyzeImagePlaceholder,
                      ),
                      // ── Tab 2 — AI Assist ─────────────────────────────
                      AITab(
                        aiLoading: _aiLoading,
                        aiResult: _aiResult,
                        onRunAI: _runAI,
                        onApplyToDiagnosis: _applyAIToDiagnosis,
                      ),
                    ],
                  ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

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
            // "Live" pill — only shown once the visit record is created
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

  // ── Patient bar ───────────────────────────────────────────────────────────

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
          // Chronic disease pills
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
          // Urgent badge
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

  // ── Tab bar ───────────────────────────────────────────────────────────────

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

  // ── Bottom action bar ─────────────────────────────────────────────────────

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
