// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/lab_reports/lab_report_viewer_page.dart
//
// Read-only viewer for a single uploaded laboratory document.
// No AI analysis, interpretation, or editing — pure document view.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

class LabReportViewerPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> report;

  /// Patient display name — shown in the header and context card.
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
  bool _openingFile = false;

  @override
  void initState() {
    super.initState();
    _report = Map<String, dynamic>.from(widget.report);
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

  Future<void> _openFile() async {
    final raw = (_report['report_url'] ?? '').toString().trim();
    if (raw.isEmpty) return;
    setState(() => _openingFile = true);
    try {
      // The /uploads/* route requires the same x-api-key/JWT headers as the
      // rest of the API, so it can't be opened as a bare external-browser
      // URL — download it through the authenticated Dio client first, then
      // open the local copy with the OS's default PDF viewer.
      final localPath = await ApiService.downloadStoredFile(raw);
      final result = await OpenFilex.open(localPath);
      if (result.type != ResultType.done) {
        _snack('Could not open file: ${result.message}', err: true);
      }
    } catch (e) {
      _snack('Could not open file: $e', err: true);
    } finally {
      if (mounted) setState(() => _openingFile = false);
    }
  }

  Future<void> _downloadFile() async {
    final raw = (_report['report_url'] ?? '').toString().trim();
    if (raw.isEmpty) return;
    setState(() => _openingFile = true);
    try {
      // Android's scoped storage (and iOS's sandbox) don't let an app write
      // straight into the public Downloads folder without the MediaStore
      // API, so — same as the rest of the app's export flows — hand the
      // downloaded file to the OS share sheet and let the user pick where
      // to save it (Files, Drive, Downloads, etc.) rather than silently
      // "opening" it like the Open Report button does.
      final localPath = await ApiService.downloadStoredFile(raw);
      final testName = (_report['test_name'] ?? '').toString().trim();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(localPath)],
          subject: testName.isNotEmpty ? testName : 'Lab Report',
        ),
      );
    } catch (e) {
      _snack('Could not download file: $e', err: true);
    } finally {
      if (mounted) setState(() => _openingFile = false);
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

  String _fileTypeLabel(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'JPEG';
    if (lower.endsWith('.png')) return 'PNG';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'Word';
    return 'File';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);

    final testName = (_report['test_name'] ?? '').toString().trim();

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

    final fileUrl = (_report['report_url'] ?? '').toString().trim();
    final hasFile = fileUrl.isNotEmpty;
    final fileType = hasFile ? _fileTypeLabel(fileUrl) : '';

    final uploadedBy =
        (_report['uploaded_by'] ?? _report['uploader_name'] ?? '')
            .toString()
            .trim();

    final patient = _findPatient();
    final conditions =
        List<dynamic>.from(patient?['patient_conditions'] ?? []);
    final showContext = widget.patientName.isNotEmpty || patient != null;

    return Scaffold(
      backgroundColor: dt.bgPage,
      body: Column(
        children: [
          _buildHeader(dt, loc, testName),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Patient context ──────────────────────────────────────────
                if (showContext) ...[
                  _buildPatientContextCard(dt, patient, conditions),
                  const SizedBox(height: 14),
                ],

                // ── File info card ───────────────────────────────────────────
                _buildSectionCard(
                  dt: dt,
                  icon: hasFile && fileType == 'PDF'
                      ? Icons.picture_as_pdf_rounded
                      : Icons.description_rounded,
                  iconColor: const Color(0xFFD32F2F),
                  iconBg: const Color(0xFFFFEBEE),
                  title: loc.labReportViewerTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (testName.isNotEmpty) ...[
                        _metaRow(
                          dt,
                          Icons.label_outline_rounded,
                          loc.labReportsTitle,
                          testName,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _metaRow(
                        dt,
                        Icons.calendar_today_outlined,
                        loc.uploadedOnLabel,
                        uploadedAt != null
                            ? DateFormat('dd MMM yyyy  •  hh:mm a')
                                .format(uploadedAt)
                            : loc.unknownDate,
                      ),
                      if (fileType.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _metaRow(
                          dt,
                          Icons.attach_file_rounded,
                          loc.fileTypeLabel,
                          fileType,
                        ),
                      ],
                      if (uploadedBy.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _metaRow(
                          dt,
                          Icons.person_outline_rounded,
                          loc.uploadedByLabel,
                          uploadedBy,
                        ),
                      ],
                      if (hasFile) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openingFile ? null : _openFile,
                                icon: _openingFile
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.open_in_new_rounded,
                                        size: 18,
                                      ),
                                label: Text(loc.openReportLabel),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _T.navy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openingFile ? null : _downloadFile,
                                icon: const Icon(
                                    Icons.download_rounded,
                                    size: 18),
                                label: Text(loc.downloadLabel),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD32F2F),
                                  side: const BorderSide(
                                      color: Color(0xFFD32F2F)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Text(
                          loc.noFileAttached,
                          style: TextStyle(
                            fontSize: 13,
                            color: dt.textM,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _metaRow(
    DoctorThemeData dt,
    IconData icon,
    String label,
    String value,
  ) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: dt.textM),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: dt.textS,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: dt.textH),
            ),
          ),
        ],
      );

  Widget _buildHeader(
    DoctorThemeData dt,
    AppLocalizations loc,
    String testName,
  ) {
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
                      testName.isNotEmpty ? testName : loc.labReportViewerTitle,
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
