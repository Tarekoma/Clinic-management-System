// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/manual_report_tab.dart
//
// Tab — Manual Medical Report creation and editing.
// Doctors fill in Diagnosis, Medications, Recommendations, and Follow-up
// Instructions directly without voice recording or AI imaging.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';
import 'package:Hakim/widgets/doctor/doctor_consultation_widgets.dart';

typedef _T = DoctorTheme;

class ManualReportTab extends ConsumerStatefulWidget {
  /// Current visit ID — may be 0 if visit resolution is still pending.
  final int visitId;

  /// Callable that resolves or creates the visit and returns a valid visitId.
  final Future<int> Function() ensureVisit;

  const ManualReportTab({
    required this.visitId,
    required this.ensureVisit,
    super.key,
  });

  @override
  ConsumerState<ManualReportTab> createState() => _ManualReportTabState();
}

class _ManualReportTabState extends ConsumerState<ManualReportTab> {
  final _formKey = GlobalKey<FormState>();

  final _diagnosisCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _recommendationsCtrl = TextEditingController();
  final _followUpCtrl = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  bool _saved = false;

  int? _existingReportId;
  String? _existingStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.visitId > 0) _loadExisting();
  }

  @override
  void didUpdateWidget(ManualReportTab old) {
    super.didUpdateWidget(old);
    // Pick up a newly resolved visitId without user interaction.
    if (old.visitId != widget.visitId &&
        widget.visitId > 0 &&
        _existingReportId == null &&
        !_loading) {
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _medicationsCtrl.dispose();
    _recommendationsCtrl.dispose();
    _followUpCtrl.dispose();
    super.dispose();
  }

  // ── Load existing report for this visit ───────────────────────────────────

  Future<void> _loadExisting() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await ApiService.getMedicalReports(
        visitId: widget.visitId,
      );
      if (!mounted) return;
      if (reports.isNotEmpty) {
        final r = Map<String, dynamic>.from(reports.first as Map);
        _existingReportId = int.tryParse((r['id'] ?? 0).toString());
        _existingStatus = (r['status'] ?? '').toString().toUpperCase();
        _diagnosisCtrl.text = (r['ai_diagnosis'] ?? '').toString();
        _medicationsCtrl.text = _extractMedications(r['ai_medications']);
        _recommendationsCtrl.text =
            _extractRecommendations(r['ai_recommendations']);
        _followUpCtrl.text =
            (r['ai_follow_up'] ?? r['doctor_notes'] ?? '').toString();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = DoctorViewModel.extractError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Field value extractors ─────────────────────────────────────────────────

  String _extractMedications(dynamic raw) {
    if (raw == null) return '';
    if (raw is List) {
      return raw.map((m) {
        if (m is Map) return (m['name'] ?? m['medication'] ?? '').toString();
        return m.toString();
      }).where((s) => s.isNotEmpty).join('\n');
    }
    return raw.toString();
  }

  String _extractRecommendations(dynamic raw) {
    if (raw == null) return '';
    if (raw is List) {
      return raw
          .map((r) => r.toString())
          .where((s) => s.isNotEmpty)
          .join('\n');
    }
    return raw.toString();
  }

  // ── Save / Update ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isTerminal =
        _existingStatus == 'FINALIZED' || _existingStatus == 'CANCELLED';
    if (isTerminal) {
      setState(() =>
          _error = 'This report is $_existingStatus and cannot be modified.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _saved = false;
    });

    try {
      final vm = ref.read(doctorViewModelProvider.notifier);
      final data = <String, dynamic>{
        'ai_diagnosis': _diagnosisCtrl.text.trim(),
        'ai_medications': _medicationsCtrl.text.trim().isNotEmpty
            ? _medicationsCtrl.text
                .trim()
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .map((l) => <String, dynamic>{'name': l.trim()})
                .toList()
            : <Map<String, dynamic>>[],
        'ai_recommendations': _recommendationsCtrl.text.trim().isNotEmpty
            ? _recommendationsCtrl.text
                .trim()
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .toList()
            : <String>[],
        'ai_follow_up': _followUpCtrl.text.trim(),
        'doctor_notes': _followUpCtrl.text.trim(),
      };

      if (_existingReportId != null && _existingReportId! > 0) {
        await vm.updateVoiceReport(reportId: _existingReportId!, data: data);
      } else {
        final visitId = await widget.ensureVisit();
        await vm.createMedicalReport({'visit_id': visitId, ...data});
        // Refresh to capture the newly assigned report ID.
        final refreshed =
            await ApiService.getMedicalReports(visitId: visitId);
        if (refreshed.isNotEmpty) {
          final latest =
              Map<String, dynamic>.from(refreshed.first as Map);
          _existingReportId =
              int.tryParse((latest['id'] ?? 0).toString());
          _existingStatus =
              (latest['status'] ?? '').toString().toUpperCase();
        }
      }

      // Advance to REVIEWED so the "Complete Consultation" finalize call
      // does not need to handle DRAFT → REVIEWED itself.
      // Non-fatal: finalization in consultation_page.dart handles DRAFT too.
      if (_existingReportId != null &&
          _existingReportId! > 0 &&
          _existingStatus != 'FINALIZED' &&
          _existingStatus != 'CANCELLED' &&
          _existingStatus != 'REVIEWED') {
        try {
          await ApiService.updateReportStatus(_existingReportId!, 'REVIEWED');
          _existingStatus = 'REVIEWED';
        } catch (e) {
          debugPrint(
            '⚠️ ManualReportTab: could not advance to REVIEWED: $e '
            '(will be handled during finalization)',
          );
        }
      }

      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) setState(() => _error = DoctorViewModel.extractError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _T.gradCard(),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manual Medical Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Create or edit consultation report directly',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Loading state ──────────────────────────────────────────────
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: _T.navy,
                        strokeWidth: 2,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Loading report…',
                        style: TextStyle(fontSize: 13, color: _T.navy),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // ── Status badge ─────────────────────────────────────────────
              _buildStatusBadge(dt),
              const SizedBox(height: 16),

              // ── Diagnosis ────────────────────────────────────────────────
              DoctorConsultCard(
                title: 'Diagnosis',
                icon: Icons.medical_information_rounded,
                child: _buildField(
                  controller: _diagnosisCtrl,
                  hint: 'Enter the primary diagnosis…',
                  color: _T.navy,
                  dt: dt,
                  required: true,
                ),
              ),
              const SizedBox(height: 12),

              // ── Medications ──────────────────────────────────────────────
              DoctorConsultCard(
                title: 'Medications',
                icon: Icons.medication_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'One medication per line',
                      style: TextStyle(
                        fontSize: 11,
                        color: dt.textS.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _medicationsCtrl,
                      hint: 'e.g.\nAmoxicillin 500mg\nIbuprofen 400mg',
                      color: const Color(0xFFE65100),
                      dt: dt,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Recommendations ──────────────────────────────────────────
              DoctorConsultCard(
                title: 'Recommendations',
                icon: Icons.healing_rounded,
                child: _buildField(
                  controller: _recommendationsCtrl,
                  hint: 'Clinical recommendations and care plan…',
                  color: _T.teal,
                  dt: dt,
                ),
              ),
              const SizedBox(height: 12),

              // ── Follow-up Instructions ───────────────────────────────────
              DoctorConsultCard(
                title: 'Follow-up Instructions',
                icon: Icons.event_repeat_rounded,
                child: _buildField(
                  controller: _followUpCtrl,
                  hint:
                      'Follow-up schedule, notes, and additional instructions…',
                  color: dt.textS,
                  dt: dt,
                ),
              ),
              const SizedBox(height: 20),

              // ── Error banner ─────────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _T.urgent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _T.urgent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: _T.urgent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: _T.urgent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Success banner ───────────────────────────────────────────
              if (_saved) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _T.teal.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _T.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: _T.teal,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Report saved successfully',
                          style: TextStyle(color: _T.teal, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Save button ──────────────────────────────────────────────
              _buildSaveButton(),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Status badge ──────────────────────────────────────────────────────────

  Widget _buildStatusBadge(DoctorThemeData dt) {
    final isTerminal =
        _existingStatus == 'FINALIZED' || _existingStatus == 'CANCELLED';
    final hasExisting = _existingReportId != null;

    if (hasExisting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _T.teal.withValues(alpha: 0.12),
              _T.navy.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.teal.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              isTerminal
                  ? Icons.lock_outline_rounded
                  : Icons.edit_note_rounded,
              color: _T.teal,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTerminal
                        ? 'Report is ${_existingStatus!.toLowerCase()} — read only'
                        : 'Existing report loaded — editing enabled',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _T.teal,
                    ),
                  ),
                  Text(
                    isTerminal
                        ? 'Finalized reports cannot be modified'
                        : 'Changes will update the report on save',
                    style: TextStyle(
                      fontSize: 11,
                      color: dt.textS.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _T.navy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.navy.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            color: _T.navy.withValues(alpha: 0.75),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No report yet — create one below',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.navy.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  'Fill in the fields and tap Save Report',
                  style: TextStyle(
                    fontSize: 11,
                    color: dt.textS.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    final isTerminal =
        _existingStatus == 'FINALIZED' || _existingStatus == 'CANCELLED';
    final label =
        _existingReportId != null ? 'Update Report' : 'Save Report';
    final icon =
        _existingReportId != null ? Icons.update_rounded : Icons.save_rounded;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (_saving || isTerminal) ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          _saving ? 'Saving…' : label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _T.navy.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white60,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ── Form field ─────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required Color color,
    required DoctorThemeData dt,
    bool required = false,
  }) {
    final isTerminal =
        _existingStatus == 'FINALIZED' || _existingStatus == 'CANCELLED';

    return TextFormField(
      controller: controller,
      maxLines: null,
      minLines: 2,
      enabled: !isTerminal,
      keyboardType: TextInputType.multiline,
      style: TextStyle(fontSize: 13, color: dt.textH, height: 1.7),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: dt.textS.withValues(alpha: 0.45),
          fontSize: 13,
        ),
        filled: true,
        fillColor:
            isTerminal ? dt.bgInput.withValues(alpha: 0.5) : dt.bgInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withValues(alpha: 0.35)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dt.divider.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? 'This field is required'
              : null
          : null,
    );
  }
}
