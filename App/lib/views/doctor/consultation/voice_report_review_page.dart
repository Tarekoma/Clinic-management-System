// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/voice_report_review_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

class VoiceReportReviewPage extends ConsumerStatefulWidget {
  final int visitId;
  final String aiTranscription;

  const VoiceReportReviewPage({
    required this.visitId,
    required this.aiTranscription,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<VoiceReportReviewPage> createState() =>
      _VoiceReportReviewPageState();
}

class _VoiceReportReviewPageState extends ConsumerState<VoiceReportReviewPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _diagnosisCtrl;
  late final TextEditingController _treatmentCtrl;
  late final TextEditingController _prescriptionsCtrl;
  late final TextEditingController _doctorNotesCtrl;

  bool _isSaving = false;

  // ── Init ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: 'Voice Report – ${_todayLabel()}');

    final parsed = _parseStructured(widget.aiTranscription);
    _diagnosisCtrl = TextEditingController(text: parsed['Diagnosis'] ?? '');
    _treatmentCtrl = TextEditingController(text: parsed['Treatment'] ?? '');
    _prescriptionsCtrl = TextEditingController(
      text: parsed['Prescriptions'] ?? '',
    );
    _doctorNotesCtrl = TextEditingController(
      text: parsed['Doctor Notes'] ?? '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _diagnosisCtrl.dispose();
    _treatmentCtrl.dispose();
    _prescriptionsCtrl.dispose();
    _doctorNotesCtrl.dispose();
    super.dispose();
  }

  // ── Parser ─────────────────────────────────────────────────────────────────
  // Parses the structured string produced by _buildStructuredReport:
  //   "Diagnosis:\nvalue\n\nTreatment:\nvalue\n\n..."

  Map<String, String> _parseStructured(String raw) {
    final result = <String, String>{};
    const labels = ['Diagnosis', 'Treatment', 'Prescriptions', 'Doctor Notes'];

    final blocks = raw.split(RegExp(r'\n{2,}'));
    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.isEmpty) continue;
      final header = lines.first.trim();
      for (final label in labels) {
        if (header.toLowerCase().startsWith(label.toLowerCase())) {
          final value = lines.skip(1).join('\n').trim();
          if (value.isNotEmpty) result[label] = value;
          break;
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

      // Treatment and Prescriptions → recommendations list
      final recommendations = <String>[
        if (_treatmentCtrl.text.trim().isNotEmpty) _treatmentCtrl.text.trim(),
        if (_prescriptionsCtrl.text.trim().isNotEmpty)
          _prescriptionsCtrl.text.trim(),
      ];

      await vm.saveVoiceReport(
        visitId: widget.visitId,
        diagnosis: _diagnosisCtrl.text.trim(),
        recommendations: recommendations,
        doctorNotes: _doctorNotesCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bgPage,
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
                      Icons.save_rounded,
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
            // ── AI badge ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _T.teal.withOpacity(0.12),
                    _T.navy.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: _T.teal,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI-Generated Report',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _T.teal,
                          ),
                        ),
                        Text(
                          'Review and edit each section before saving',
                          style: TextStyle(
                            fontSize: 11,
                            color: _T.textS.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Report title ───────────────────────────────────────────────
            _SectionLabel(
              label: 'Report Title',
              icon: Icons.title_rounded,
              color: _T.textH,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: _inp('Enter report title'),
              style: const TextStyle(
                fontSize: 14,
                color: _T.textH,
                fontWeight: FontWeight.w600,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),

            const SizedBox(height: 20),

            // ── Diagnosis ──────────────────────────────────────────────────
            _buildSection(
              icon: Icons.medical_information_rounded,
              label: 'Diagnosis',
              controller: _diagnosisCtrl,
              hint: 'AI-generated diagnosis…',
              color: _T.navy,
            ),

            // ── Treatment ──────────────────────────────────────────────────
            _buildSection(
              icon: Icons.healing_rounded,
              label: 'Treatment',
              controller: _treatmentCtrl,
              hint: 'AI-generated treatment plan…',
              color: _T.teal,
            ),

            // ── Prescriptions ──────────────────────────────────────────────
            _buildSection(
              icon: Icons.medication_rounded,
              label: 'Prescriptions',
              controller: _prescriptionsCtrl,
              hint: 'AI-generated prescriptions…',
              color: const Color(
                0xFFE65100,
              ), // deep orange — matches screenshot
              borderColor: const Color(0xFFE65100),
            ),

            // ── Doctor Notes ───────────────────────────────────────────────
            _buildSection(
              icon: Icons.note_alt_rounded,
              label: 'Doctor Notes',
              controller: _doctorNotesCtrl,
              hint: 'Additional notes, follow-up instructions…',
              color: _T.textS,
            ),

            const SizedBox(height: 28),

            // ── Save button ────────────────────────────────────────────────
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
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  _isSaving ? 'Saving…' : 'Save Report',
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

            // ── Discard button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _T.textS,
                  side: BorderSide(color: _T.textS.withOpacity(0.3)),
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

  // ── Section builder ────────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    required Color color,
    Color? borderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: label, icon: icon, color: color),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: null,
            minLines: 2,
            keyboardType: TextInputType.multiline,
            decoration: _inp(hint, borderColor: borderColor ?? color),
            style: const TextStyle(fontSize: 13, color: _T.textH, height: 1.7),
          ),
        ],
      ),
    );
  }

  // ── Input decoration ───────────────────────────────────────────────────────

  InputDecoration _inp(String hint, {Color? borderColor}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _T.textS.withOpacity(0.45), fontSize: 13),
    filled: true,
    fillColor: _T.bgInput,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: borderColor?.withOpacity(0.35) ?? _T.divider,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: borderColor?.withOpacity(0.35) ?? _T.divider,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor ?? _T.teal, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}
