// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/consultation_page.dart
//
// CHANGES IN THIS VERSION:
//   • Header date now uses DateFormat(..., localeCode) + arDigits() instead
//     of the unlocalized 'dd MMM yyyy  •  hh:mm a' — was always English.
//   • _appointmentTypeName now takes `loc` and maps known backend type-name
//     strings ("Initial Consultation", "Consultation", "Revisit") to their
//     localized equivalents — same pattern used on the finance page and
//     appointment card.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:Hakim/views/doctor/consultation/ai_imaging_review_page.dart';
import 'package:Hakim/views/doctor/consultation/manual_report_tab.dart';
import 'package:Hakim/views/doctor/consultation/voice_report_review_page.dart';
import 'package:Hakim/views/doctor/consultation/voice_tab.dart';
import 'package:Hakim/views/doctor/consultation/vitals_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';
import 'package:Hakim/views/doctor/consultation/ai_imaging_tab.dart';
import 'package:Hakim/views/doctor/consultation/patient_history_tab.dart';
import 'package:Hakim/views/doctor/lab_reports/lab_reports_page.dart';

typedef _T = DoctorTheme;

class DoctorConsultationPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> appointment;
  final UserProfile doctorProfile;

  const DoctorConsultationPage({
    required this.appointment,
    required this.doctorProfile,
    super.key,
  });

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
  bool _transcribing = false;

  File? _imagingSelectedImage;
  bool _imagingAnalyzed = false;
  String _imagingSelectedType = 'XRAY'; // default

  // Image confirmations staged by AIImagingReviewPage but not yet submitted
  // to the backend. Each entry is {'imageId': int, 'diff': Map}. Submitted
  // exactly once — via reviewMedicalImage — when the consultation completes,
  // so PDF/WhatsApp delivery for images only fires at that point.
  final List<Map<String, dynamic>> _pendingImageConfirmations = [];

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

  /// Safely resolves appointment_type — backend may return a nested Map or
  /// String. Also maps known backend type-name strings to their localized
  /// equivalent, since the backend itself isn't localized.
  String _appointmentTypeName(AppLocalizations loc) {
    final raw =
        widget.appointment['appointment_type_name'] ??
        widget.appointment['appointment_type'];
    String extracted;
    if (raw == null) {
      extracted = loc.consultationDefault;
    } else if (raw is Map) {
      extracted = (raw['name'] ?? raw['title'] ?? loc.consultationDefault)
          .toString();
    } else {
      final s = raw.toString().trim();
      extracted = s.isEmpty ? loc.consultationDefault : s;
    }
    switch (extracted.trim().toLowerCase()) {
      case 'initial consultation':
        return loc.initialConsultation;
      case 'consultation':
        return loc.visitTypeConsultation;
      case 'revisit':
      case 're-visit':
        return loc.visitTypeRevisit;
      default:
        return extracted;
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _initVisit();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _initVisit() async {
    // clearConsultationCache() modifies Riverpod state. Riverpod forbids
    // state changes during initState / the first build frame, so defer it
    // to the post-frame callback — by which point the tree is fully built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(doctorViewModelProvider.notifier).clearConsultationCache();
      }
    });
    try {
      await _resolveVisit().timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('⚠️ _initVisit: _resolveVisit error/timeout: $e');
    }
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

  Future<void> _navigateToImagingReview() async {
    if (_imagingSelectedImage == null) return;
    final confirmed = await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(
        builder: (_) => AIImagingReviewPage(
          imageFile: _imagingSelectedImage!,
          imageType: _imagingSelectedType,
          ensureVisit: _ensureVisit,
        ),
      ),
    );
    if (confirmed != null && mounted) {
      setState(() {
        _imagingAnalyzed = true;
        _pendingImageConfirmations.add(confirmed);
      });
    }
  }

  // ── Voice recorded ────────────────────────────────────────────────────────

  Future<void> _onVoiceRecorded(String audioPath) async {
    setState(() => _transcribing = true);
    try {
      debugPrint('🔍 _onVoiceRecorded: resolving visitId…');
      final int visitId;
      try {
        visitId = await _ensureVisit();
        debugPrint('✅ _onVoiceRecorded: visitId=$visitId');
      } catch (e) {
        _snack(DoctorViewModel.extractError(e), err: true);
        return;
      }

      if (visitId <= 0) {
        _snack('Could not resolve visit. Please try again.', err: true);
        return;
      }

      final vm = ref.read(doctorViewModelProvider.notifier);
      final result = await vm.transcribeAudioLocal(
        audioFile: File(audioPath),
        visitId: visitId,
      );

      if (!mounted) return;

      if (result.reportId <= 0) {
        _snack(
          'Could not get report ID from server. Please try again.',
          err: true,
        );
        return;
      }

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => VoiceReportReviewPage(
            visitId: visitId,
            reportId: result.reportId,
            aiTranscription: result.transcription,
          ),
        ),
      );

      if (saved == true && mounted) _snack('Voice report saved successfully.');
    } catch (e) {
      if (mounted) {
        _snack(
          'Transcription failed: ${DoctorViewModel.extractError(e)}',
          err: true,
        );
      }
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save({required bool complete}) async {
    if (_saving) return;
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

      if (!complete) {
        if (notes.isNotEmpty) {
          try {
            final existing = await vm.fetchVisitReports(visitId);
            if (existing.isNotEmpty) {
              final existId =
                  int.tryParse((existing.first['id'] ?? 0).toString()) ?? 0;
              if (existId > 0) {
                await vm.updateVoiceReport(
                  reportId: existId,
                  data: {'doctor_notes': notes},
                );
              }
            } else {
              await vm.createMedicalReport({
                'visit_id': visitId,
                'doctor_notes': notes,
                'ai_diagnosis': '',
                'ai_medications': <Map<String, dynamic>>[],
                'ai_recommendations': <String>[],
                'ai_follow_up': '',
              });
            }
          } catch (_) {}
        }
        _snack('Draft saved');
        return;
      }

      // ── Role guard ──────────────────────────────────────────────────────────
      if (widget.doctorProfile.userType.toUpperCase() != 'DOCTOR') {
        _snack('Only doctors can complete consultations.', err: true);
        return;
      }

      // ── Already terminal? ───────────────────────────────────────────────────
      final currentVisitStatus = (_visit?['status'] ?? '')
          .toString()
          .toUpperCase();
      if (currentVisitStatus == 'COMPLETED') {
        _snack('This consultation has already been completed.');
        if (mounted) Navigator.pop(context);
        return;
      }
      if (currentVisitStatus == 'CANCELLED') {
        _snack(
          'This consultation was cancelled and cannot be completed.',
          err: true,
        );
        return;
      }

      // ── Fetch existing reports for this visit ───────────────────────────────
      List<dynamic> existingReports = await vm.fetchVisitReports(visitId);
      final hasReport = existingReports.isNotEmpty;
      final hasImaging = _imagingAnalyzed;
      final hasNotes = notes.isNotEmpty;

      // ── Completion validation ───────────────────────────────────────────────
      if (!hasReport && !hasImaging && !hasNotes) {
        _snack(
          'Please generate a voice report, create a medical report, or '
          'perform an AI image analysis before completing the consultation.',
          err: true,
        );
        return;
      }

      // ── Persist doctor notes into the report ────────────────────────────────
      if (notes.isNotEmpty) {
        try {
          if (hasReport) {
            final existId =
                int.tryParse((existingReports.first['id'] ?? 0).toString()) ??
                0;
            if (existId > 0) {
              await vm.updateVoiceReport(
                reportId: existId,
                data: {'doctor_notes': notes},
              );
            }
          } else {
            await vm.createMedicalReport({
              'visit_id': visitId,
              'doctor_notes': notes,
              'ai_diagnosis': '',
              'ai_medications': <Map<String, dynamic>>[],
              'ai_recommendations': <String>[],
              'ai_follow_up': '',
            });
          }
        } catch (e) {
          debugPrint(
            '⚠️ _save: notes persist: ${DoctorViewModel.extractError(e)}',
          );
        }
      }

      // ── Re-fetch reports after possible creation ────────────────────────────
      if (!hasReport && notes.isNotEmpty) {
        existingReports = await vm.fetchVisitReports(visitId);
      }

      // ── Finalize report (DRAFT → REVIEWED → APPROVED → FINALIZED + WhatsApp) ─
      // Skip for terminal statuses; only call when a report actually exists.
      final reportToFinalize = existingReports.isNotEmpty
          ? existingReports.first
          : null;
      if (reportToFinalize != null) {
        final reportId =
            int.tryParse((reportToFinalize['id'] ?? 0).toString()) ?? 0;
        final reportStatus = (reportToFinalize['status'] ?? '')
            .toString()
            .toUpperCase();

        if (reportId > 0 &&
            reportStatus != 'FINALIZED' &&
            reportStatus != 'CANCELLED') {
          try {
            debugPrint(
              '📋 _save: finalizing report #$reportId (status=$reportStatus)',
            );
            await vm.finalizeReport(reportId, currentStatus: reportStatus);
            debugPrint(
              '✅ _save: report #$reportId finalized → PDF + WhatsApp triggered',
            );
          } catch (e) {
            // Finalization failed — surface a warning but do NOT block visit
            // completion: the consultation data is saved and the doctor can
            // manually finalize from patient history.
            debugPrint(
              '⚠️ _save: finalizeReport failed: ${DoctorViewModel.extractError(e)}',
            );
            _snack(
              'Report could not be finalized: ${DoctorViewModel.extractError(e)}. '
              'You can finalize it later from the patient\'s history.',
              err: true,
            );
          }
        }
      }

      // ── Visit status: WAITING → IN_PROGRESS → COMPLETED ────────────────────
      if (currentVisitStatus == 'WAITING' || currentVisitStatus.isEmpty) {
        try {
          await vm.updateVisitStatus(visitId, 'IN_PROGRESS');
          debugPrint('🔄 Visit #$visitId: WAITING → IN_PROGRESS');
          if (mounted) {
            setState(() {
              if (_visit != null) {
                _visit = Map<String, dynamic>.from(_visit!)
                  ..['status'] = 'IN_PROGRESS';
              }
            });
          }
        } catch (e) {
          debugPrint(
            '⚠️ _save: WAITING→IN_PROGRESS: ${DoctorViewModel.extractError(e)} '
            '— continuing to COMPLETED.',
          );
        }
      }

      await vm.updateVisitStatus(visitId, 'COMPLETED');
      debugPrint('✅ Visit #$visitId → COMPLETED');

      if (mounted) {
        setState(() {
          if (_visit != null) {
            _visit = Map<String, dynamic>.from(_visit!)
              ..['status'] = 'COMPLETED';
          }
        });
      }

      // ── Appointment status → COMPLETED ──────────────────────────────────────
      try {
        await vm.updateAppointmentStatus(_apptId, 'COMPLETED');
        debugPrint('✅ Appointment #$_apptId → COMPLETED');
      } catch (e) {
        debugPrint(
          '⚠️ _save: appointment sync: ${DoctorViewModel.extractError(e)}',
        );
      }

      // ── Refresh appointment list so the dashboard reflects COMPLETED ─────────
      try {
        await ref.read(doctorViewModelProvider.notifier).fetchAppointments();
      } catch (_) {}

      // ── Submit staged image confirmations (PDF + WhatsApp for images) ──────
      // Runs after the visit/appointment are already COMPLETED so it can never
      // delay the medical-report finalize call above. Each image is processed
      // exactly once: a server-side is_confirmed check guards against
      // re-sending one that already succeeded in a prior (failed) completion
      // attempt, and successes are removed from the queue so retries only
      // touch leftovers.
      if (_pendingImageConfirmations.isNotEmpty) {
        final stillPending = <Map<String, dynamic>>[];
        for (final pending in _pendingImageConfirmations) {
          final imageId = pending['imageId'] as int;
          final diff = Map<String, dynamic>.from(
            pending['diff'] as Map? ?? {},
          );
          try {
            final current = await ApiService.getMedicalImageById(imageId);
            if (current['is_confirmed'] == true) {
              debugPrint(
                '⏭️ _save: image #$imageId already confirmed, skipping',
              );
              continue;
            }
            await ApiService.reviewMedicalImage(imageId, diff);
            debugPrint('✅ _save: image #$imageId confirmed → report sent');
          } catch (e) {
            debugPrint(
              '⚠️ _save: reviewMedicalImage failed for #$imageId: '
              '${DoctorViewModel.extractError(e)}',
            );
            stillPending.add(pending);
          }
        }
        _pendingImageConfirmations
          ..clear()
          ..addAll(stillPending);
        if (stillPending.isNotEmpty) {
          _snack(
            'Some image reports could not be sent and will be retried.',
            err: true,
          );
        }
      }

      _snack('Consultation completed. Report sent via WhatsApp.');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ _save: ${DoctorViewModel.extractError(e)}');
      _snack('Failed to complete consultation. Please try again.', err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Confirm exit ──────────────────────────────────────────────────────────

  void _confirmExit() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.leaveConsultationTitle),
        content: Text(loc.leaveConsultationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.stay),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _save(complete: false);
              if (mounted) Navigator.pop(context);
            },
            child: Text(loc.saveDraftBtn),
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
            child: Text(loc.leave),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: dt.bgPage,
      body: Column(
        children: [
          _buildHeader(loc),
          _buildPatientBar(loc),
          _buildTabBar(loc),
          Expanded(
            child: _startingVisit
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: _T.navy,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          loc.startingConsultationEllipsis,
                          style: TextStyle(fontSize: 13, color: dt.textS),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabs,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      VitalsTab(appointmentId: _apptId, patientId: _patId),
                      PatientHistoryTab(
                        patientId: _patId,
                        patientName: _patientName,
                        appointment: widget.appointment,
                      ),
                      VoiceTab(
                        notesCtrl: _notesCtrl,
                        transcribing: _transcribing,
                        onTranscribe: _onVoiceRecorded,
                      ),
                      AIImagingTab(
                        selectedImage: _imagingSelectedImage,
                        onPickImage: _pickImgForAI,
                        onAnalyze: _navigateToImagingReview,
                        selectedImageType: _imagingSelectedType,
                        onImageTypeChanged: (t) =>
                            setState(() => _imagingSelectedType = t),
                      ),
                      LabReportsTab(
                        visitId: _visitId,
                        patientName: _patientName,
                        patientId: _patId,
                        ensureVisit: _ensureVisit,
                      ),
                      ManualReportTab(
                        visitId: _visitId,
                        ensureVisit: _ensureVisit,
                      ),
                    ],
                  ),
          ),
          _buildActions(loc),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    final localeCode = Localizations.localeOf(context).languageCode;
    // FIXED: was DateFormat('dd MMM yyyy  •  hh:mm a').format(now) with no
    // locale arg — always English month name + Western digits.
    final headerDate = arDigits(
      DateFormat('dd MMM yyyy  •  hh:mm a', localeCode).format(DateTime.now()),
      localeCode,
    );

    return Container(
      decoration: const BoxDecoration(gradient: _T.gNavy),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white70,
                ),
                onPressed: _confirmExit,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.consultationTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      headerDate,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
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
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 7,
                        height: 7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF69F0AE),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        loc.liveBadge,
                        style: const TextStyle(
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
  }

  Widget _buildPatientBar(AppLocalizations loc) {
    final type = _appointmentTypeName(loc); // FIXED: now localized
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
                    color: Colors.white.withValues(alpha: 0.65),
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
                            color: Colors.white.withValues(alpha: 0.15),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    loc.urgentBadge,
                    style: const TextStyle(
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

  Widget _buildTabBar(AppLocalizations loc) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return Container(
      color: dt.bgCard,
      child: TabBar(
        controller: _tabs,
        labelColor: dt.accent,
        unselectedLabelColor: dt.textM,
        indicatorColor: dt.accent,
        indicatorWeight: 2.5,
        isScrollable: true,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: loc.vitalsTabLabel),
          Tab(text: loc.patientHistoryTabLabel),
          Tab(text: loc.voiceTabLabel),
          Tab(text: loc.aiImagingTabLabel),
          Tab(text: loc.labReportsTabLabel),
          Tab(text: loc.manualReportTabLabel),
        ],
      ),
    );
  }

  Widget _buildActions(AppLocalizations loc) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final isDoctor = widget.doctorProfile.userType.toUpperCase() == 'DOCTOR';
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: dt.bgCard,
        boxShadow: [
          BoxShadow(
            color: _T.navy.withValues(alpha: 0.08),
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
              child: Text(
                loc.saveDraftBtn,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (isDoctor) ...[
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
                    : Text(
                        loc.completeConsultationBtn,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
