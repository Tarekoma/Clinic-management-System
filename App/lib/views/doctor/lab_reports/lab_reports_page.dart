// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/lab_reports/lab_reports_page.dart
//
// Laboratory History viewer — shows ALL uploaded lab files for a patient
// across all their visits, ordered newest first.
//
// LabReportsPage = full Scaffold wrapper (used from patient-detail / visits).
// LabReportsTab  = bare widget for embedding in a TabBarView (no Scaffold).
//
// Upload still targets the current visit (visitId / ensureVisit).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'lab_report_viewer_page.dart';

typedef _T = DoctorTheme;

// ── Standalone full-screen page ───────────────────────────────────────────────

class LabReportsPage extends StatelessWidget {
  final int visitId;
  final String patientName;
  final int patientId;

  const LabReportsPage({
    required this.visitId,
    required this.patientName,
    this.patientId = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: dt.bgPage,
      body: Column(
        children: [
          _buildHeader(context, dt, loc),
          Expanded(
            child: _LabReportsBody(
              visitId: visitId,
              patientName: patientName,
              patientId: patientId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DoctorThemeData dt,
    AppLocalizations loc,
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
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.labHistoryTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      patientName,
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
      ),
    );
  }
}

// ── Tab variant (no Scaffold) ─────────────────────────────────────────────────

class LabReportsTab extends StatelessWidget {
  final int visitId;
  final String patientName;
  final int patientId;

  /// Optional callback that resolves (or creates) the visit and returns its ID.
  /// Used for upload — when the doctor uploads before any other action has
  /// triggered visit creation.
  final Future<int> Function()? ensureVisit;

  const LabReportsTab({
    required this.visitId,
    this.patientName = '',
    this.patientId = 0,
    this.ensureVisit,
    super.key,
  });

  @override
  Widget build(BuildContext context) => _LabReportsBody(
    visitId: visitId,
    patientName: patientName,
    patientId: patientId,
    ensureVisit: ensureVisit,
  );
}

// ── Shared body ───────────────────────────────────────────────────────────────

class _LabReportsBody extends ConsumerStatefulWidget {
  final int visitId;
  final String patientName;
  final int patientId;
  final Future<int> Function()? ensureVisit;

  const _LabReportsBody({
    required this.visitId,
    this.patientName = '',
    this.patientId = 0,
    this.ensureVisit,
  });

  @override
  ConsumerState<_LabReportsBody> createState() => _LabReportsBodyState();
}

class _LabReportsBodyState extends ConsumerState<_LabReportsBody> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  bool _hasError = false;

  // Resolved visitId for upload — set when ensureVisit() succeeds before
  // the parent rebuild propagates.
  int? _resolvedVisitId;
  int get _effectiveVisitId => _resolvedVisitId ?? widget.visitId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final vm = ref.read(doctorViewModelProvider.notifier);
      final List<Map<String, dynamic>> all = [];

      if (widget.patientId > 0) {
        // Fetch all visits, then aggregate lab reports across all of them.
        final visits = await vm.fetchVisits(widget.patientId);
        final visitIds = visits
            .map((v) => int.tryParse((v['id'] ?? 0).toString()) ?? 0)
            .where((id) => id > 0)
            .toList();

        if (visitIds.isNotEmpty) {
          final byVisit = await vm.fetchLabReportsForVisits(visitIds);
          for (final entry in byVisit.entries) {
            for (final lab in entry.value) {
              all.add({...lab, '_visit_id': entry.key});
            }
          }
          all.sort(
            (a, b) => _parseDate(b['created_at'])
                .compareTo(_parseDate(a['created_at'])),
          );
        }
      } else if (_effectiveVisitId > 0) {
        // Fallback: show only the current visit if patientId is unavailable.
        all.addAll(await vm.fetchLabReports(_effectiveVisitId));
      }

      if (mounted) setState(() => _reports = all);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime(2000);
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime(2000);
    }
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

  // ── Upload ────────────────────────────────────────────────────────────────

  Future<void> _showUploadSheet() async {
    final loc = AppLocalizations.of(context);
    int visitId = _effectiveVisitId;

    if (visitId <= 0) {
      if (widget.ensureVisit == null) {
        _snack('Please start the visit first.', err: true);
        return;
      }
      setState(() => _loading = true);
      try {
        visitId = await widget.ensureVisit!();
        if (visitId > 0 && mounted) {
          setState(() => _resolvedVisitId = visitId);
        }
      } catch (e) {
        _snack(
          'Could not start visit: ${DoctorViewModel.extractError(e)}',
          err: true,
        );
        return;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    if (!mounted || visitId <= 0) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadBottomSheet(
        visitId: visitId,
        onUploaded: () async {
          _snack(loc.labReportUploadSuccess);
          await _load();
        },
        onError: (msg) => _snack(loc.labReportUploadFailed(msg), err: true),
      ),
    );
  }

  void _openViewer(Map<String, dynamic> report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LabReportViewerPage(
          report: report,
          patientName: widget.patientName,
          patientId: widget.patientId,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: _T.urgent),
            const SizedBox(height: 12),
            Text(
              'Could not load laboratory records.',
              style: TextStyle(fontSize: 13, color: dt.textS),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(loc.retry),
              style: OutlinedButton.styleFrom(
                foregroundColor: _T.navy,
                side: const BorderSide(color: _T.navy),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        _reports.isEmpty ? _buildEmpty(dt, loc) : _buildList(dt, loc),
        // Upload button pinned at bottom
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showUploadSheet,
                icon: const Icon(Icons.upload_file_rounded, size: 20),
                label: Text(
                  loc.uploadLabReport,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(DoctorThemeData dt, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        children: [
          _buildBanner(loc),
          const SizedBox(height: 24),
          DoctorEmpty(
            icon: Icons.science_outlined,
            title: loc.noLabRecordsAvailable,
            sub: loc.noLabRecordsAvailableSub,
          ),
        ],
      ),
    );
  }

  Widget _buildList(DoctorThemeData dt, AppLocalizations loc) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _reports.length + 1, // +1 for the header banner
      separatorBuilder: (_, i) =>
          i == 0 ? const SizedBox(height: 16) : const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == 0) return _buildBanner(loc);
        final r = _reports[i - 1];

        DateTime? uploadedAt;
        try {
          uploadedAt = DateTime.parse(
            (r['uploaded_at'] ?? r['created_at'] ?? r['updated_at'] ?? '')
                .toString(),
          ).toLocal();
        } catch (_) {}

        final dateStr = uploadedAt != null
            ? DateFormat('dd MMM yyyy  •  hh:mm a').format(uploadedAt)
            : loc.unknownDate;

        final testName = (r['test_name'] ?? '').toString().trim();
        final fileUrl = (r['report_url'] ?? '').toString().trim();
        final hasFile = fileUrl.isNotEmpty;
        final fileType = hasFile ? _fileTypeLabel(fileUrl) : '';
        final uploadedBy =
            (r['uploaded_by'] ?? r['uploader_name'] ?? '').toString().trim();

        return GestureDetector(
          onTap: hasFile ? () => _openViewer(r) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File type icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    fileType == 'PDF'
                        ? Icons.picture_as_pdf_rounded
                        : Icons.description_rounded,
                    color: const Color(0xFFD32F2F),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File name row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              testName.isNotEmpty
                                  ? testName
                                  : loc.labReportViewerTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: dt.textH,
                              ),
                            ),
                          ),
                          if (fileType.isNotEmpty)
                            _typeBadge(fileType),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Upload date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: dt.textM,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${loc.uploadedOnLabel}: $dateStr',
                              style: TextStyle(
                                fontSize: 10,
                                color: dt.textS,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Uploaded by (if known)
                      if (uploadedBy.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 11,
                              color: dt.textM,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${loc.uploadedByLabel}: $uploadedBy',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: dt.textS,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // View link
                      if (hasFile) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 11,
                              color: _T.navy,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              loc.phViewReport,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _T.navy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasFile) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: dt.textM,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _typeBadge(String type) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          type,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD32F2F),
          ),
        ),
      );

  String _fileTypeLabel(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'JPEG';
    if (lower.endsWith('.png')) return 'PNG';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'Word';
    return 'File';
  }

  Widget _buildBanner(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _T.gradCard(),
      child: Row(
        children: [
          const Icon(Icons.science_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.labHistoryTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _reports.isEmpty
                      ? loc.noLabRecordsAvailableSub
                      : loc.labRecordsCount(_reports.length),
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
    );
  }
}

// ── Upload bottom sheet ───────────────────────────────────────────────────────

class _UploadBottomSheet extends ConsumerStatefulWidget {
  final int visitId;
  final Future<void> Function() onUploaded;
  final void Function(String) onError;

  const _UploadBottomSheet({
    required this.visitId,
    required this.onUploaded,
    required this.onError,
  });

  @override
  ConsumerState<_UploadBottomSheet> createState() =>
      _UploadBottomSheetState();
}

class _UploadBottomSheetState extends ConsumerState<_UploadBottomSheet> {
  File? _selectedFile;
  String? _selectedFileName;
  bool _uploading = false;
  bool _uploadAttempted = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
        withReadStream: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (_) {
      // file picker cancelled or permission denied — no-op
    }
  }

  Future<void> _upload() async {
    setState(() => _uploadAttempted = true);
    if (_selectedFile == null) return;

    setState(() => _uploading = true);
    try {
      final vm = ref.read(doctorViewModelProvider.notifier);
      await vm.uploadLabReport(
        pdfFile: _selectedFile!,
        visitId: widget.visitId,
      );
      if (mounted) Navigator.pop(context);
      await widget.onUploaded();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      widget.onError(DoctorViewModel.extractError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);
    final noFile = _uploadAttempted && _selectedFile == null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: dt.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dt.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.uploadLabReport,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dt.textH,
              ),
            ),
            const SizedBox(height: 20),
            // PDF picker row
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: noFile
                        ? _T.urgent
                        : _selectedFile != null
                        ? _T.navy
                        : dt.divider,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: _selectedFile != null
                      ? _T.navy.withValues(alpha: 0.05)
                      : dt.bgPage,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.picture_as_pdf_rounded
                          : Icons.upload_file_rounded,
                      color: _selectedFile != null ? _T.navy : dt.textM,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFileName ?? loc.selectPdfFile,
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedFile != null ? dt.textH : dt.textM,
                          fontWeight: _selectedFile != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedFile != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedFile = null;
                          _selectedFileName = null;
                        }),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: dt.textM,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (noFile) ...[
              const SizedBox(height: 4),
              Text(
                loc.noPdfSelected,
                style: TextStyle(fontSize: 11, color: _T.urgent),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_rounded, size: 20),
                label: Text(
                  _uploading ? '…' : loc.uploadLabReport,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.navy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _T.navy.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
