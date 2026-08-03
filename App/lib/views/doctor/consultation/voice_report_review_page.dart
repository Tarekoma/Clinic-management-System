// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/voice_report_review_page.dart
//
// Premium AI voice report review page — matches AI Imaging tab quality.
// Layout:
//   1. AI Transcription Complete banner
//   2. Collapsible raw transcript card
//   3. Report title field
//   4. AI-generated section cards (Diagnosis / Medications /
//      Recommendations / Follow-up)
//   5. Save & Discard actions
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

class VoiceReportReviewPage extends ConsumerStatefulWidget {
  final int visitId;
  final int reportId;
  final String aiTranscription;

  const VoiceReportReviewPage({
    required this.visitId,
    required this.reportId,
    required this.aiTranscription,
    super.key,
  });

  @override
  ConsumerState<VoiceReportReviewPage> createState() =>
      _VoiceReportReviewPageState();
}

class _VoiceReportReviewPageState extends ConsumerState<VoiceReportReviewPage> {
  late DoctorThemeData _dt;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _diagnosisCtrl;
  late final TextEditingController _recommendationsCtrl;
  late final TextEditingController _medicationsCtrl;
  late final TextEditingController _followUpCtrl;

  bool _isSaving = false;
  bool _transcriptExpanded = false;

  // ── Init ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: 'Voice Report – ${_todayLabel()}');

    final parsed = _parseStructured(widget.aiTranscription);
    _diagnosisCtrl = TextEditingController(text: parsed['Diagnosis'] ?? '');
    _recommendationsCtrl = TextEditingController(
      text: parsed['Recommendations'] ?? '',
    );
    _medicationsCtrl = TextEditingController(text: parsed['Medications'] ?? '');
    _followUpCtrl = TextEditingController(
      text: parsed['Follow-up Instructions'] ?? '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _diagnosisCtrl.dispose();
    _recommendationsCtrl.dispose();
    _medicationsCtrl.dispose();
    _followUpCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, String> _parseStructured(String raw) {
    final result = <String, String>{};
    const labels = [
      'Diagnosis',
      'Recommendations',
      'Medications',
      'Follow-up Instructions',
    ];
    const legacyAlias = {
      'treatment': 'Recommendations',
      'prescriptions': 'Medications',
      'doctor notes': 'Follow-up Instructions',
    };

    final blocks = raw.split(RegExp(r'\n{2,}'));
    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.isEmpty) continue;
      final header = lines.first.trim().toLowerCase();
      final value = lines.skip(1).join('\n').trim();
      if (value.isEmpty) continue;

      bool matched = false;
      for (final label in labels) {
        if (header.startsWith(label.toLowerCase())) {
          result[label] = value;
          matched = true;
          break;
        }
      }
      if (!matched) {
        for (final entry in legacyAlias.entries) {
          if (header.startsWith(entry.key)) {
            result[entry.value] = value;
            break;
          }
        }
      }
    }
    return result;
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final vm = ref.read(doctorViewModelProvider.notifier);

      await vm.updateVoiceReport(
        reportId: widget.reportId,
        data: {
          'ai_diagnosis': _diagnosisCtrl.text.trim(),
          'ai_recommendations': _recommendationsCtrl.text.trim().isNotEmpty
              ? [_recommendationsCtrl.text.trim()]
              : [],
          'ai_medications': _medicationsCtrl.text.trim().isNotEmpty
              ? [{'name': _medicationsCtrl.text.trim()}]
              : [],
          'ai_follow_up': _followUpCtrl.text.trim(),
          'doctor_notes': _followUpCtrl.text.trim(),
        },
      );

      // Advance to REVIEWED so the "Complete Consultation" flow can call
      // finalize directly without an extra status-transition step.
      // Non-fatal: if this fails (e.g. report was already REVIEWED) we still
      // consider the save successful — finalize in _save() handles DRAFT too.
      try {
        await ApiService.updateReportStatus(widget.reportId, 'REVIEWED');
        debugPrint(
          '✅ VoiceReportReviewPage: report #${widget.reportId} → REVIEWED',
        );
      } catch (e) {
        debugPrint('⚠️ Could not advance to REVIEWED: $e');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 10),
              Text('Report saved and marked as reviewed'),
            ],
          ),
          backgroundColor: _T.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save report: $e'),
          backgroundColor: _T.urgent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _dt = Theme.of(context).extension<DoctorThemeData>()!;

    return Scaffold(
      backgroundColor: _dt.bgPage,
      appBar: AppBar(
        backgroundColor: _T.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Review AI Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSaving
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _onSave,
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Save Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // 1. AI analysis complete banner
            _buildAnalysisBanner(),
            const SizedBox(height: 16),

            // 2. Raw transcript (collapsible)
            if (widget.aiTranscription.isNotEmpty) ...[
              _buildTranscriptCard(),
              const SizedBox(height: 16),
            ],

            // 3. Report title
            _buildReportTitleCard(),
            const SizedBox(height: 14),

            // 4. AI-generated section cards
            _buildSectionCard(
              icon: Icons.medical_information_rounded,
              label: 'Diagnosis',
              color: _T.navy,
              controller: _diagnosisCtrl,
              hint: 'AI-generated diagnosis…',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              icon: Icons.medication_rounded,
              label: 'Medications',
              color: _T.warning,
              controller: _medicationsCtrl,
              hint: 'AI-generated medications…',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              icon: Icons.healing_rounded,
              label: 'Recommendations',
              color: _T.teal,
              controller: _recommendationsCtrl,
              hint: 'AI-generated recommendations…',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              icon: Icons.event_repeat_rounded,
              label: 'Follow-up Instructions',
              color: _T.navyLight,
              controller: _followUpCtrl,
              hint: 'Follow-up instructions and additional notes…',
            ),
            const SizedBox(height: 28),

            // 5. Save / Discard
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _onSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_rounded, size: 20),
                label: Text(
                  _isSaving ? 'Saving…' : 'Save & Confirm Report',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed:
                    _isSaving ? null : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _dt.textS,
                  side: BorderSide(color: _dt.textS.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Discard & Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI analysis banner ─────────────────────────────────────────────────────

  Widget _buildAnalysisBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _T.teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.teal.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: _T.teal, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Transcription Complete',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.teal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Review and edit each section before saving to the patient record',
                  style: TextStyle(
                    fontSize: 11,
                    color: _T.teal.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Collapsible transcript card ────────────────────────────────────────────

  Widget _buildTranscriptCard() {
    return Container(
      decoration: BoxDecoration(
        color: _dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dt.divider),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tappable header
            GestureDetector(
              onTap: () => setState(
                () => _transcriptExpanded = !_transcriptExpanded,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _T.navy.withValues(alpha: 0.06),
                      _T.teal.withValues(alpha: 0.03),
                    ],
                  ),
                  border: _transcriptExpanded
                      ? Border(bottom: BorderSide(color: _dt.divider))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _T.navy.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.transcribe_rounded,
                        size: 15,
                        color: _T.navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Raw Transcript',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _dt.textH,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _T.navy.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _transcriptExpanded ? 'Hide' : 'Show',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _dt.textS,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _transcriptExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 14,
                            color: _dt.textS,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Transcript body
            if (_transcriptExpanded)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  widget.aiTranscription,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _dt.textH,
                    height: 1.7,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Report title card ──────────────────────────────────────────────────────

  Widget _buildReportTitleCard() {
    return Container(
      decoration: BoxDecoration(
        color: _dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dt.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.title_rounded, size: 14, color: _dt.textS),
                const SizedBox(width: 6),
                Text(
                  'Report Title',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _dt.textS,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: TextStyle(
                fontSize: 14,
                color: _dt.textH,
                fontWeight: FontWeight.w600,
              ),
              decoration: _inp('Enter report title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── AI section card ────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required IconData icon,
    required String label,
    required Color color,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dt.divider),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coloured section header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(color: color.withValues(alpha: 0.14)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            // Editable field
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextFormField(
                controller: controller,
                maxLines: null,
                minLines: 2,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontSize: 13,
                  color: _dt.textH,
                  height: 1.7,
                ),
                decoration: _inp(
                  hint,
                  focusColor: color,
                  borderColor: color.withValues(alpha: 0.22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Input decoration ───────────────────────────────────────────────────────

  InputDecoration _inp(
    String hint, {
    Color? focusColor,
    Color? borderColor,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: _dt.textS.withValues(alpha: 0.45),
      fontSize: 13,
    ),
    filled: true,
    fillColor: _dt.bgInput,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor ?? _dt.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor ?? _dt.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: focusColor ?? _T.navy, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _T.urgent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _T.urgent, width: 1.5),
    ),
  );
}
