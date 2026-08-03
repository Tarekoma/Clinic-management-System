// lib/views/doctor/consultation/patient_history_tab.dart
//
// Patient History Tab — shown inside DoctorConsultationPage.
// Loads all historical data for the current patient in parallel and
// displays it in 7 collapsible medical-dashboard sections.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';
import 'package:Hakim/views/doctor/lab_reports/lab_report_viewer_page.dart';
import 'package:Hakim/widgets/doctor/ai_analysis_result_widget.dart';

typedef _T = DoctorTheme;

// ─────────────────────────────────────────────────────────────────────────────

class PatientHistoryTab extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;
  final Map<String, dynamic> appointment;

  const PatientHistoryTab({
    required this.patientId,
    required this.patientName,
    required this.appointment,
    super.key,
  });

  @override
  ConsumerState<PatientHistoryTab> createState() => _PatientHistoryTabState();
}

class _PatientHistoryTabState extends ConsumerState<PatientHistoryTab>
    with AutomaticKeepAliveClientMixin {

  // ── State ─────────────────────────────────────────────────────────────────

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _visits = [];
  List<Map<String, dynamic>> _medicalReports = [];
  List<Map<String, dynamic>> _images = [];
  bool _imagesLoading = false;
  final Map<int, List<Map<String, dynamic>>> _labsByVisit = {};
  bool _labsLoading = false;

  // Expand state for each collapsible section
  final Map<String, bool> _expanded = {
    'visits': true,
    'labs': false,
    'images': false,
    'reports': false,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Data Loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _labsLoading = false;
      _labsByVisit.clear();
    });

    try {
      final vm = ref.read(doctorViewModelProvider.notifier);
      final pid = widget.patientId;
      if (pid <= 0) throw Exception('Invalid patient ID');

      final results = await Future.wait<List<Map<String, dynamic>>>([
        vm.fetchVisits(pid),
        vm.fetchPatientMedicalReports(pid),
      ]);

      if (!mounted) return;

      final visits = results[0]
        ..sort((a, b) =>
            _parseDate(b['created_at']).compareTo(_parseDate(a['created_at'])));

      final reports = results[1]
        ..sort((a, b) =>
            _parseDate(b['created_at']).compareTo(_parseDate(a['created_at'])));

      setState(() {
        _visits = visits;
        _medicalReports = reports;
        _images = [];
        _loading = false;
        _labsLoading = true;
        _imagesLoading = true;
      });

      // Fire-and-forget background loads
      unawaited(_loadLabReports(visits.take(12).toList(), vm));
      // Images are fetched per-visit because the backend has no patient-level
      // images endpoint — only GET /visits/{id}/medical-images exists.
      unawaited(_loadImagesPerVisit(visits, vm));
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = DoctorViewModel.extractError(e);
        });
      }
    }
  }

  Future<void> _loadLabReports(
    List<Map<String, dynamic>> visits,
    DoctorViewModel vm,
  ) async {
    await Future.wait(visits.map((v) {
      final vid = int.tryParse((v['id'] ?? 0).toString()) ?? 0;
      if (vid <= 0) return Future.value();
      return vm.fetchLabReports(vid).then((labs) {
        if (mounted && labs.isNotEmpty) {
          setState(() => _labsByVisit[vid] = labs);
        }
      }).catchError((_) {});
    }));
    if (mounted) setState(() => _labsLoading = false);
  }

  Future<void> _loadImagesPerVisit(
    List<Map<String, dynamic>> visits,
    DoctorViewModel vm,
  ) async {
    final all = <Map<String, dynamic>>[];
    await Future.wait(visits.map((v) {
      final vid = int.tryParse((v['id'] ?? 0).toString()) ?? 0;
      if (vid <= 0) return Future.value();
      return vm.fetchVisitImages(vid).then((imgs) {
        if (imgs.isNotEmpty) all.addAll(imgs);
      }).catchError((_) {});
    }));
    if (!mounted) return;
    all.sort((a, b) =>
        _parseDate(b['created_at']).compareTo(_parseDate(a['created_at'])));
    setState(() {
      _images = all;
      _imagesLoading = false;
    });
  }

  // ── Computed Data ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _completedVisits => _visits
      .where((v) =>
          (v['status'] ?? '').toString().toUpperCase() != 'IN_PROGRESS')
      .toList();

  List<Map<String, dynamic>> get _allLabReports {
    final all = <Map<String, dynamic>>[];
    for (final entry in _labsByVisit.entries) {
      for (final lab in entry.value) {
        all.add({...lab, '_visit_id': entry.key});
      }
    }
    all.sort((a, b) =>
        _parseDate(b['created_at']).compareTo(_parseDate(a['created_at'])));
    return all;
  }

  // ── Format Helpers ────────────────────────────────────────────────────────

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime(2000);
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime(2000);
    }
  }

  String _fmt(dynamic v, String lc) {
    final d = _parseDate(v);
    if (d.year == 2000) return '—';
    return arDigits(DateFormat('dd MMM yyyy', lc).format(d), lc);
  }

  String _visitDate(Map<String, dynamic> v, String lc) {
    final apptTime = v['appointment']?['start_time'];
    return _fmt(apptTime ?? v['created_at'], lc);
  }

  String _visitTypeName(Map<String, dynamic> v) {
    final t = v['appointment']?['appointment_type_name'] ??
        v['appointment_type_name'] ??
        '';
    return t.toString().isEmpty ? 'Consultation' : t.toString();
  }

  String _recs(dynamic raw) {
    if (raw == null) return '';
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .join('; ');
    }
    return raw.toString().trim();
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'FINALIZED':
        return _T.success;
      case 'APPROVED':
        return _T.info;
      case 'REVIEWED':
        return _T.teal;
      case 'CANCELLED':
        return _T.urgent;
      default:
        return _T.muted;
    }
  }

  String _imageTypeLabel(String t) {
    switch (t.toUpperCase()) {
      case 'XRAY':
        return 'X-Ray';
      case 'SKIN':
        return 'Skin';
      default:
        return t;
    }
  }

  bool _isImageConfirmed(Map<String, dynamic> img) {
    final v = img['is_confirmed'];
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v.toString().toLowerCase() == 'true';
  }

  /// Returns the best available structured report data from a medical image
  /// record, using the same priority chain as the review page:
  ///   ai_report (confirmed XRayReport) → ai_report_raw (SKIN draft) → ai_diagnosis
  Map<String, dynamic>? _extractImageReportData(Map<String, dynamic> img) {
    final r = img['ai_report'];
    if (r is Map && r.isNotEmpty) return Map<String, dynamic>.from(r);

    final raw = img['ai_report_raw'];
    if (raw is Map && raw.isNotEmpty) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
      return {'summary': raw.trim()};
    }

    final diag = img['ai_diagnosis'];
    if (diag is String &&
        diag.trim().isNotEmpty &&
        !diag.trim().startsWith('[')) {
      return {'summary': diag.trim()};
    }

    return null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);
    final lc = Localizations.localeOf(context).languageCode;

    if (_loading) return _buildLoading(dt, loc);
    if (_error != null) return _buildError(dt, loc);

    return RefreshIndicator(
      color: _T.navy,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
        children: [
          _patientSummaryBanner(dt, loc, lc),
          const SizedBox(height: 14),
          _buildSection(
            context, dt,
            sectionKey: 'visits',
            icon: Icons.history_rounded,
            color: _T.navy,
            title: loc.phPreviousVisits,
            count: _completedVisits.length,
            child: _visitsContent(dt, loc, lc),
          ),
          const SizedBox(height: 8),
          _buildSection(
            context, dt,
            sectionKey: 'labs',
            icon: Icons.science_rounded,
            color: const Color(0xFF1565C0),
            title: loc.phLabReportsHistory,
            count: _allLabReports.length,
            trailing: _labsLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFF1565C0),
                    ),
                  )
                : null,
            child: _labsContent(dt, loc, lc),
          ),
          const SizedBox(height: 8),
          _buildSection(
            context, dt,
            sectionKey: 'images',
            icon: Icons.medical_information_rounded,
            color: const Color(0xFF6A1B9A),
            title: loc.phMedicalImages,
            count: _images.length,
            trailing: _imagesLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFF6A1B9A),
                    ),
                  )
                : null,
            child: _imagesContent(dt, loc, lc),
          ),
          const SizedBox(height: 8),
          _buildSection(
            context, dt,
            sectionKey: 'reports',
            icon: Icons.assignment_rounded,
            color: const Color(0xFF2E7D32),
            title: loc.phAiMedicalReports,
            count: _medicalReports.length,
            child: _reportsContent(dt, loc, lc),
          ),
        ],
      ),
    );
  }

  // ── Loading / Error states ────────────────────────────────────────────────

  Widget _buildLoading(DoctorThemeData dt, AppLocalizations loc) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: _T.navy,
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 18),
              Text(
                loc.phLoadingHistory,
                style: TextStyle(fontSize: 13, color: dt.textS),
              ),
            ],
          ),
        ),
      );

  Widget _buildError(DoctorThemeData dt, AppLocalizations loc) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 52, color: dt.textM),
              const SizedBox(height: 16),
              Text(
                loc.phErrorLoading,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: dt.textH,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 12, color: dt.textS),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(loc.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Patient summary banner ────────────────────────────────────────────────

  Widget _patientSummaryBanner(
    DoctorThemeData dt,
    AppLocalizations loc,
    String lc,
  ) {
    final totalVisits = _completedVisits.length;
    final totalReports = _medicalReports.length;
    final totalImages = _images.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _T.navy.withValues(alpha: 0.92),
            const Color(0xFF1565C0).withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_shared_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      loc.phMedicalRecord,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _summaryStatBox(
                arDigits(totalVisits.toString(), lc),
                loc.phPreviousVisits,
                Icons.history_rounded,
              ),
              const SizedBox(width: 8),
              _summaryStatBox(
                arDigits(totalReports.toString(), lc),
                loc.phAiMedicalReports,
                Icons.assignment_rounded,
              ),
              const SizedBox(width: 8),
              _summaryStatBox(
                arDigits(totalImages.toString(), lc),
                loc.phMedicalImages,
                Icons.medical_information_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStatBox(String value, String label, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  // ── Section container ─────────────────────────────────────────────────────

  Widget _buildSection(
    BuildContext context,
    DoctorThemeData dt, {
    required String sectionKey,
    required IconData icon,
    required Color color,
    required String title,
    required int count,
    required Widget child,
    Widget? trailing,
  }) {
    final isExpanded = _expanded[sectionKey] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? color.withValues(alpha: 0.25)
              : dt.divider.withValues(alpha: 0.4),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded[sectionKey] = !isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: isExpanded
                    ? color.withValues(alpha: 0.06)
                    : dt.bgCard,
                border: isExpanded
                    ? Border(
                        bottom: BorderSide(
                          color: color.withValues(alpha: 0.18),
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: color, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: dt.textH,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing,
                    const SizedBox(width: 6),
                  ],
                  if (count > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: dt.textM,
                  ),
                ],
              ),
            ),
          ),
          // ── Body ───────────────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: child,
            secondChild: const SizedBox.shrink(),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  // ── Empty / Info states ───────────────────────────────────────────────────

  Widget _emptyState(
    DoctorThemeData dt,
    IconData icon,
    String title,
    String subtitle,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Icon(icon, size: 38, color: dt.textM.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dt.textH,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: dt.textS),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _divider(DoctorThemeData dt) =>
      Divider(height: 1, color: dt.divider.withValues(alpha: 0.5));

  Widget _statusBadge(String status, {Color? color}) {
    final c = color ?? _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: c,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section A: Previous Visits
  // ─────────────────────────────────────────────────────────────────────────

  Widget _visitsContent(
    DoctorThemeData dt,
    AppLocalizations loc,
    String lc,
  ) {
    final visits = _completedVisits;
    if (visits.isEmpty) {
      return _emptyState(
        dt,
        Icons.history_rounded,
        loc.phNoVisitsYet,
        loc.phNoVisitsYetSub,
      );
    }

    return Column(
      children: visits.asMap().entries.map((entry) {
        final idx = entry.key;
        final v = entry.value;
        final status = (v['status'] ?? '').toString().toUpperCase();

        return Column(
          children: [
            if (idx > 0) _divider(dt),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _visitDate(v, lc),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dt.textH,
                      ),
                    ),
                  ),
                  _statusBadge(_visitTypeName(v), color: _T.navy),
                  const SizedBox(width: 6),
                  _statusBadge(
                    status == 'COMPLETED' ? loc.statusCompleted : status,
                    color: status == 'COMPLETED' ? _T.success : _T.muted,
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section B: Laboratory Reports
  // ─────────────────────────────────────────────────────────────────────────

  Widget _labsContent(
    DoctorThemeData dt,
    AppLocalizations loc,
    String lc,
  ) {
    const labColor = Color(0xFF1565C0);
    final labs = _allLabReports;

    if (_labsLoading && labs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 1.5,
                color: labColor,
              ),
              const SizedBox(height: 10),
              Text(
                loc.phLoadingLabs,
                style: TextStyle(fontSize: 11, color: dt.textS),
              ),
            ],
          ),
        ),
      );
    }

    if (labs.isEmpty) {
      return _emptyState(
        dt,
        Icons.science_rounded,
        loc.phNoLabReports,
        loc.phNoLabReportsSub,
      );
    }

    return Column(
      children: labs.asMap().entries.map((entry) {
        final idx = entry.key;
        final lab = entry.value;
        final testName =
            (lab['test_name'] ?? 'Lab Report').toString().trim();
        final uploadDate = _fmt(lab['created_at'], lc);
        final rawUrl = (lab['report_url'] ?? '').toString();
        final hasFile = rawUrl.isNotEmpty;

        final visitId = int.tryParse((lab['_visit_id'] ?? 0).toString()) ?? 0;
        final visit = visitId > 0
            ? _visits.firstWhere(
                (v) => int.tryParse((v['id'] ?? 0).toString()) == visitId,
                orElse: () => const {},
              )
            : const <String, dynamic>{};
        final visitDate = visit.isNotEmpty ? _visitDate(visit, lc) : null;

        void openLab() => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LabReportViewerPage(
                  report: lab,
                  patientName: widget.patientName,
                ),
              ),
            );

        return Column(
          children: [
            if (idx > 0) _divider(dt),
            InkWell(
              onTap: hasFile ? openLab : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: labColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: labColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: dt.textH,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                                  uploadDate,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: dt.textS,
                                  ),
                                ),
                              ),
                              if (hasFile) ...[
                                Text(
                                  loc.phViewReport,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: labColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: labColor,
                                ),
                              ],
                            ],
                          ),
                          if (visitDate != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.event_note_rounded,
                                  size: 11,
                                  color: dt.textM,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${loc.phVisitDateLabel}: $visitDate',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: dt.textS,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section E: Medical Images (with AI report preview)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _imagesContent(
    DoctorThemeData dt,
    AppLocalizations loc,
    String lc,
  ) {
    const imgColor = Color(0xFF6A1B9A);
    if (_images.isEmpty) {
      return _emptyState(
        dt,
        Icons.medical_information_rounded,
        loc.phNoImages,
        loc.phNoImagesSub,
      );
    }

    return Column(
      children: _images.asMap().entries.map((entry) {
        final idx = entry.key;
        final img = entry.value;
        final imgType = (img['image_type'] ?? 'Image').toString().toUpperCase();
        final imageType = _imageTypeLabel(imgType);
        final description = (img['description'] ?? '').toString().trim();
        final uploadDate = _fmt(img['created_at'], lc);
        final imageUrl = ApiService.toDisplayUrl(
          (img['image_file'] ?? '').toString(),
        );
        final confirmed = _isImageConfirmed(img);
        final reportData = _extractImageReportData(img);

        // Extract first finding or summary as a card preview snippet
        String? snippet;
        if (reportData != null) {
          final findings = reportData['findings'];
          if (findings is List && findings.isNotEmpty) {
            snippet = findings.first.toString().trim();
          } else if (findings is String && findings.trim().isNotEmpty) {
            snippet = findings.trim();
          } else {
            final s = (reportData['summary'] ??
                    reportData['clinical_summary'] ??
                    '')
                .toString()
                .trim();
            if (s.isNotEmpty) snippet = s;
          }
        }

        final statusColor =
            confirmed ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
        final statusBg =
            confirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
        final statusBorder = confirmed
            ? const Color(0xFF4CAF50)
            : const Color(0xFFFF9800);

        return Column(
          children: [
            if (idx > 0) _divider(dt),
            InkWell(
              onTap: () => _showImageReportSheet(context, img, dt, loc, lc),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail or type icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: imgColor.withValues(alpha: 0.08),
                                  child: Icon(
                                    imgType == 'XRAY'
                                        ? Icons.monitor_heart_rounded
                                        : Icons.face_rounded,
                                    color: imgColor,
                                    size: 24,
                                  ),
                                ),
                              )
                            : Container(
                                color: imgColor.withValues(alpha: 0.08),
                                child: Icon(
                                  imgType == 'XRAY'
                                      ? Icons.monitor_heart_rounded
                                      : Icons.face_rounded,
                                  color: imgColor,
                                  size: 26,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + status badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  description.isNotEmpty
                                      ? description
                                      : '$imageType Analysis',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: dt.textH,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        statusBorder.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      confirmed
                                          ? Icons.verified_rounded
                                          : Icons.pending_actions_rounded,
                                      size: 10,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      confirmed ? 'Confirmed' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Findings snippet
                          if (snippet != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              snippet,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: dt.textS,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 5),
                          // Date + action hint
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
                                  uploadDate,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: dt.textS,
                                  ),
                                ),
                              ),
                              Text(
                                loc.phViewReport,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: imgColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: imgColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Full-screen image viewer dialog ────────────────────────────────────────

  void _openImageDialog(
    BuildContext context,
    String url,
    DoctorThemeData dt,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 200,
                        color: dt.bgCard,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: _T.navy,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: dt.bgCard,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_rounded,
                          size: 40, color: dt.textM),
                      const SizedBox(height: 8),
                      Text(
                        'Could not load image',
                        style: TextStyle(fontSize: 12, color: dt.textS),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Medical Image Report Detail Sheet ──────────────────────────────────────

  void _showImageReportSheet(
    BuildContext context,
    Map<String, dynamic> img,
    DoctorThemeData dt,
    AppLocalizations loc,
    String lc,
  ) {
    const imgColor = Color(0xFF6A1B9A);
    final imgType = (img['image_type'] ?? 'Image').toString().toUpperCase();
    final imageType = _imageTypeLabel(imgType);
    final uploadDate = _fmt(img['created_at'], lc);
    final imageUrl =
        ApiService.toDisplayUrl((img['image_file'] ?? '').toString());
    final confirmed = _isImageConfirmed(img);
    final reportData = _extractImageReportData(img);
    final doctorNotes = (img['doctor_notes'] ?? '').toString().trim();

    final statusColor =
        confirmed ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final statusBg =
        confirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final statusBorder =
        confirmed ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        minChildSize: 0.40,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: dt.bgCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dt.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: imgColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        imgType == 'XRAY'
                            ? Icons.monitor_heart_rounded
                            : Icons.face_rounded,
                        color: imgColor,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$imageType Analysis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: dt.textH,
                            ),
                          ),
                          Text(
                            uploadDate,
                            style:
                                TextStyle(fontSize: 11, color: dt.textS),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusBorder.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            confirmed
                                ? Icons.verified_rounded
                                : Icons.pending_actions_rounded,
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            confirmed ? 'Confirmed' : 'Pending Review',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: dt.divider.withValues(alpha: 0.5)),

              // Scrollable body
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // ── Image thumbnail (tap for full-screen) ────────────
                    if (imageUrl.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () =>
                            _openImageDialog(context, imageUrl, dt),
                        child: Container(
                          height: 210,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, p) =>
                                      p == null
                                          ? child
                                          : Container(
                                              color: dt.bgCard,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: _T.navy,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                  errorBuilder: (_, __, ___) => Container(
                                    color: dt.bgCard,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_rounded,
                                          size: 40,
                                          color: dt.textM,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Image unavailable',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: dt.textS,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Fullscreen tap hint
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.fullscreen_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Full Screen',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── AI Analysis Report ───────────────────────────────
                    if (reportData != null) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: dt.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: dt.divider),
                          boxShadow: [
                            BoxShadow(
                              color: _T.navy.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AIAnalysisResultWidget(
                            result: reportData,
                            isLoading: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: dt.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: dt.divider),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.image_search_rounded,
                              size: 40,
                              color: dt.textM.withValues(alpha: 0.28),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              loc.phNoImagesSub,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: dt.textS,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Doctor Notes ────────────────────────────────────
                    if (doctorNotes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _T.navy.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _T.navy.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.note_alt_rounded,
                                  size: 14,
                                  color: dt.textM,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  loc.pillNotes,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: dt.textH,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doctorNotes,
                              style: TextStyle(
                                fontSize: 13,
                                color: dt.textH,
                                height: 1.5,
                              ),
                            ),
                          ],
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

  // ─────────────────────────────────────────────────────────────────────────
  // Section F: Previous AI / Medical Reports
  // ─────────────────────────────────────────────────────────────────────────

  Widget _reportsContent(
    DoctorThemeData dt,
    AppLocalizations loc,
    String lc,
  ) {
    const rptColor = Color(0xFF2E7D32);
    if (_medicalReports.isEmpty) {
      return _emptyState(
        dt,
        Icons.assignment_rounded,
        loc.phNoReports,
        loc.phNoReportsSub,
      );
    }

    return Column(
      children: _medicalReports.asMap().entries.map((entry) {
        final idx = entry.key;
        final r = entry.value;
        final status = (r['status'] ?? '').toString().toUpperCase();
        final diagnosis = (r['ai_diagnosis'] ?? '').toString().trim();
        final date = _fmt(r['created_at'], lc);

        const skip = {
          'غير مذكور',
          'not mentioned',
          'n/a',
          'not specified',
          '',
        };
        final hasRealDiagnosis =
            diagnosis.isNotEmpty && !skip.contains(diagnosis.toLowerCase());

        return Column(
          children: [
            if (idx > 0) _divider(dt),
            InkWell(
              onTap: () => _showReportDetail(context, r, dt, loc, lc),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: rptColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: rptColor,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  hasRealDiagnosis
                                      ? diagnosis
                                      : loc.phMedicalReport,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: dt.textH,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _statusBadge(
                                status,
                                color: _statusColor(status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
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
                                  date,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: dt.textS,
                                  ),
                                ),
                              ),
                              Text(
                                loc.phViewReport,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: rptColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: rptColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Medical Report Detail Sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showReportDetail(
    BuildContext context,
    Map<String, dynamic> report,
    DoctorThemeData dt,
    AppLocalizations loc,
    String lc,
  ) {
    const rptColor = Color(0xFF2E7D32);
    const skipValues = {
      'غير مذكور',
      'not mentioned',
      'n/a',
      'na',
      'not specified',
      'null',
      '-',
      '',
    };
    bool isReal(String s) =>
        s.isNotEmpty && !skipValues.contains(s.toLowerCase());

    final status = (report['status'] ?? '').toString().toUpperCase();
    final date = _fmt(report['created_at'], lc);
    final diagnosis = (report['ai_diagnosis'] ?? '').toString().trim();
    final recs = _recs(report['ai_recommendations']);
    final followUp = (report['ai_follow_up'] ?? '').toString().trim();
    final doctorNotes = (report['doctor_notes'] ?? '').toString().trim();
    final meds = report['ai_medications'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.35,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: dt.bgCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dt.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: rptColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: rptColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.phMedicalReport,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: dt.textH,
                            ),
                          ),
                          Text(
                            date,
                            style:
                                TextStyle(fontSize: 11, color: dt.textS),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(status, color: _statusColor(status)),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: dt.divider.withValues(alpha: 0.5),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    if (isReal(diagnosis)) ...[
                      _rptSection(
                        dt,
                        loc.pillDiagnosis,
                        Icons.medical_services_rounded,
                        _T.teal,
                        diagnosis,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (isReal(recs)) ...[
                      _rptSection(
                        dt,
                        loc.pillTreatment,
                        Icons.healing_rounded,
                        const Color(0xFF1565C0),
                        recs,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (meds is List && meds.isNotEmpty) ...[
                      _rptMedsSection(dt, loc, meds, skipValues),
                      const SizedBox(height: 14),
                    ],
                    if (isReal(followUp)) ...[
                      _rptSection(
                        dt,
                        loc.pillFollowUp,
                        Icons.schedule_rounded,
                        const Color(0xFF6A1B9A),
                        followUp,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (isReal(doctorNotes)) ...[
                      _rptSection(
                        dt,
                        loc.pillNotes,
                        Icons.note_rounded,
                        _T.muted,
                        doctorNotes,
                      ),
                    ],
                    if (!isReal(diagnosis) &&
                        !isReal(recs) &&
                        !isReal(followUp) &&
                        !isReal(doctorNotes) &&
                        (meds is! List || meds.isEmpty))
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            loc.phNoReportsSub,
                            style: TextStyle(
                                fontSize: 13, color: dt.textS),
                            textAlign: TextAlign.center,
                          ),
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

  Widget _rptSection(
    DoctorThemeData dt,
    String label,
    IconData icon,
    Color color,
    String content,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: dt.textH,
                height: 1.5,
              ),
            ),
          ),
        ],
      );

  Widget _rptMedsSection(
    DoctorThemeData dt,
    AppLocalizations loc,
    List meds,
    Set<String> skip,
  ) {
    final valid = meds.whereType<Map>().where((m) {
      final name = (m['name'] ?? m['drug_name'] ?? m['medication'] ?? '')
          .toString()
          .trim();
      return name.isNotEmpty && !skip.contains(name.toLowerCase());
    }).toList();
    if (valid.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medication_rounded, size: 14, color: _T.teal),
            const SizedBox(width: 6),
            Text(
              loc.pillMedications,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _T.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...valid.map((m) {
          final name =
              (m['name'] ?? m['drug_name'] ?? m['medication'] ?? '')
                  .toString()
                  .trim();
          final dose =
              (m['dose'] ?? m['dosage'] ?? '').toString().trim();
          final freq =
              (m['frequency'] ?? m['freq'] ?? '').toString().trim();
          final duration = (m['duration'] ?? '').toString().trim();
          final notes =
              (m['notes'] ?? m['note'] ?? '').toString().trim();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: _T.teal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _T.teal.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: dt.textH,
                  ),
                ),
                if (dose.isNotEmpty && !skip.contains(dose.toLowerCase())) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${loc.phDosage}: $dose',
                    style: TextStyle(fontSize: 11, color: dt.textS),
                  ),
                ],
                if (freq.isNotEmpty && !skip.contains(freq.toLowerCase()))
                  Text(
                    '${loc.phFrequency}: $freq',
                    style: TextStyle(fontSize: 11, color: dt.textS),
                  ),
                if (duration.isNotEmpty &&
                    !skip.contains(duration.toLowerCase()))
                  Text(
                    '${loc.phDuration}: $duration',
                    style: TextStyle(fontSize: 11, color: dt.textS),
                  ),
                if (notes.isNotEmpty && !skip.contains(notes.toLowerCase()))
                  Text(
                    notes,
                    style: TextStyle(
                      fontSize: 11,
                      color: dt.textM,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

}
