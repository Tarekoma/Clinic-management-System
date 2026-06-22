// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/lab_reports/lab_report_viewer_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';

typedef _T = DoctorTheme;

// The AI service always returns this placeholder when lab interpretation is
// unavailable. Treat any text starting with '[' as a stub (no real content).
bool _isStub(String? text) {
  if (text == null || text.trim().isEmpty) return true;
  return text.trim().startsWith('[');
}

class LabReportViewerPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> report;

  /// Patient display name — shown in header and context card.
  final String patientName;

  /// Patient primary key — used to look up conditions from Riverpod state.
  final int patientId;

  const LabReportViewerPage({
    required this.report,
    this.patientName = '',
    this.patientId = 0,
    super.key,
  });

  @override
  ConsumerState<LabReportViewerPage> createState() =>
      _LabReportViewerPageState();
}

class _LabReportViewerPageState extends ConsumerState<LabReportViewerPage> {
  late Map<String, dynamic> _report;
  late TextEditingController _interpretCtrl;
  bool _editing = false;
  bool _saving = false;
  bool _openingPdf = false;

  @override
  void initState() {
    super.initState();
    _report = Map<String, dynamic>.from(widget.report);
    // Pre-fill the editor only when a real (non-stub) summary exists.
    final raw = (_report['ai_interpreted_summary'] ?? '').toString();
    _interpretCtrl = TextEditingController(
      text: _isStub(raw) ? '' : raw,
    );
  }

  @override
  void dispose() {
    _interpretCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _saveInterpretation() async {
    final loc = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final id = int.tryParse((_report['id'] ?? 0).toString()) ?? 0;
      if (id <= 0) throw Exception('Invalid report ID');
      final vm = ref.read(doctorViewModelProvider.notifier);
      // PATCH /reports/lab-reports/{id} only accepts ai_interpreted_summary.
      final updated = await vm.updateLabReport(id, {
        'ai_interpreted_summary': _interpretCtrl.text.trim(),
      });
      setState(() {
        _report = Map<String, dynamic>.from(updated);
        _editing = false;
      });
      _snack(loc.interpretationSaved);
    } catch (e) {
      _snack(
        loc.interpretationSaveFailed(DoctorViewModel.extractError(e)),
        err: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openPdf() async {
    final raw =
        (_report['report_file'] ?? _report['file_url'] ?? '').toString().trim();
    if (raw.isEmpty) return;
    // Backend returns a relative storage path — convert to the public URL.
    final url = ApiService.toDisplayUrl(raw);
    setState(() => _openingPdf = true);
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _snack('Could not open PDF', err: true);
      }
    } catch (e) {
      _snack('Could not open PDF: $e', err: true);
    } finally {
      if (mounted) setState(() => _openingPdf = false);
    }
  }

  // ── Patient lookup ────────────────────────────────────────────────────────

  Map<String, dynamic>? _findPatient() {
    if (widget.patientId <= 0) return null;
    final patients = ref.read(doctorViewModelProvider).patients;
    try {
      return patients.firstWhere(
        (p) => int.tryParse((p['id'] ?? 0).toString()) == widget.patientId,
      );
    } catch (_) {
      return null;
    }
  }

  String? _calcAge(dynamic dob) {
    try {
      final birth = DateTime.parse(dob.toString());
      final now = DateTime.now();
      final age = now.year -
          birth.year -
          (now.month < birth.month ||
                  (now.month == birth.month && now.day < birth.day)
              ? 1
              : 0);
      return '$age y/o';
    } catch (_) {
      return null;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);

    DateTime? uploadedAt;
    try {
      uploadedAt = DateTime.parse(
        (_report['uploaded_at'] ??
                _report['created_at'] ??
                _report['updated_at'] ??
                '')
            .toString(),
      ).toLocal();
    } catch (_) {}

    final fileUrl =
        (_report['report_file'] ?? _report['file_url'] ?? '').toString().trim();
    final hasFile = fileUrl.isNotEmpty;

    final rawSummary =
        (_report['ai_interpreted_summary'] ?? '').toString().trim();
    final hasSummary = !_isStub(rawSummary);

    final doctorNotes = (_report['doctor_notes'] ?? '').toString().trim();
    final hasDoctorNotes = doctorNotes.isNotEmpty && !_isStub(doctorNotes);

    final patient = _findPatient();
    final conditions =
        List<dynamic>.from(patient?['patient_conditions'] ?? []);
    final showContext = widget.patientName.isNotEmpty || patient != null;

    return Scaffold(
      backgroundColor: dt.bgPage,
      body: Column(
        children: [
          _buildHeader(dt, loc, uploadedAt),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Patient context ────────────────────────────────────────
                if (showContext) ...[
                  _buildPatientContextCard(dt, patient, conditions),
                  const SizedBox(height: 14),
                ],

                // ── PDF card ───────────────────────────────────────────────
                if (hasFile) ...[
                  _buildSectionCard(
                    dt: dt,
                    icon: Icons.picture_as_pdf_rounded,
                    iconColor: const Color(0xFFD32F2F),
                    iconBg: const Color(0xFFFFEBEE),
                    title: loc.labReportViewerTitle,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openingPdf ? null : _openPdf,
                        icon: _openingPdf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(loc.openReportLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Doctor's Summary card ──────────────────────────────────
                _buildSectionCard(
                  dt: dt,
                  icon: Icons.assignment_outlined,
                  iconColor: _T.navy,
                  iconBg: _T.navy.withValues(alpha: 0.08),
                  title: loc.aiInterpretationLabel,
                  trailing: _editing
                      ? null
                      : TextButton.icon(
                          onPressed: () => setState(() => _editing = true),
                          icon: const Icon(Icons.edit_rounded, size: 15),
                          label: Text(loc.editInterpretation),
                          style: TextButton.styleFrom(
                            foregroundColor: _T.navy,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                  child: _editing
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _interpretCtrl,
                              maxLines: 8,
                              style: TextStyle(
                                fontSize: 13,
                                color: dt.textH,
                                height: 1.6,
                              ),
                              decoration: _T.inpOf(
                                context,
                                '',
                                hint: loc.aiInterpretationLabel,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _saving ? null : _saveInterpretation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _T.teal,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                                      loc.saveInterpretation,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            TextButton(
                              onPressed: () {
                                _interpretCtrl.text =
                                    hasSummary ? rawSummary : '';
                                setState(() => _editing = false);
                              },
                              child: Text(loc.cancel),
                            ),
                          ],
                        )
                      : hasSummary
                          ? Text(
                              rawSummary,
                              style: TextStyle(
                                fontSize: 13,
                                color: dt.textH,
                                height: 1.7,
                              ),
                            )
                          : Text(
                              loc.noInterpretationYet,
                              style: TextStyle(
                                fontSize: 13,
                                color: dt.textM,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                ),

                // ── Doctor Notes (read-only legacy field) ──────────────────
                if (hasDoctorNotes) ...[
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    dt: dt,
                    icon: Icons.note_alt_rounded,
                    iconColor: dt.textS,
                    iconBg: const Color(0xFFF5F7FA),
                    title: loc.doctorNotesLabel,
                    child: Text(
                      doctorNotes,
                      style: TextStyle(
                        fontSize: 13,
                        color: dt.textH,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildHeader(
    DoctorThemeData dt,
    AppLocalizations loc,
    DateTime? uploadedAt,
  ) {
    final dateStr = uploadedAt != null
        ? DateFormat('dd MMM yyyy  •  hh:mm a').format(uploadedAt)
        : '';
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
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.labReportViewerTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.patientName.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.patientName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${loc.uploadedOnLabel}: $dateStr',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientContextCard(
    DoctorThemeData dt,
    Map<String, dynamic>? patient,
    List<dynamic> conditions,
  ) {
    final name = patient != null
        ? '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim()
        : widget.patientName;

    final age = patient?['date_of_birth'] != null
        ? _calcAge(patient!['date_of_birth'])
        : null;

    final chronic = conditions
        .where((c) =>
            (c['category'] ?? '').toString().toUpperCase() == 'CHRONIC')
        .toList();
    final allergies = conditions
        .where((c) =>
            (c['category'] ?? '').toString().toUpperCase() == 'ALLERGY')
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: _T.navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.navy.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: _T.gNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? '—' : name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dt.textH,
                      ),
                    ),
                    if (age != null)
                      Text(
                        age,
                        style: TextStyle(fontSize: 11, color: dt.textM),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (chronic.isNotEmpty || allergies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final c in chronic)
                  _conditionChip(
                    (c['condition_name'] ?? c['name'] ?? '').toString(),
                    const Color(0xFFE53935),
                    const Color(0xFFFFEBEE),
                  ),
                for (final c in allergies)
                  _conditionChip(
                    (c['condition_name'] ?? c['name'] ?? '').toString(),
                    const Color(0xFFE65100),
                    const Color(0xFFFFF3E0),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _conditionChip(String label, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );

  Widget _buildSectionCard({
    required DoctorThemeData dt,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dt.divider),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}
