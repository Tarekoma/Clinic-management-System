// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_patient_detail.dart
//
// DoctorPatientDetail — DraggableScrollableSheet with Overview / Reports /
// Lab / Imaging tabs.  DoctorIRow, DoctorCondChip helper widgets.
//
// Reads doctorViewModelProvider directly (ConsumerStatefulWidget) so it can
// call vm.fetchVisits / vm.assignCondition / vm.removeCondition without any
// callback chain through parent pages.
//
// Localized via AppLocalizations.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/widgets/doctor/ai_analysis_result_widget.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';
import 'package:Hakim/views/doctor/lab_reports/lab_report_viewer_page.dart';

typedef _T = DoctorTheme;

// ── Patient Detail Sheet ──────────────────────────────────────────────────────

class DoctorPatientDetail extends ConsumerStatefulWidget {
  final Map<String, dynamic> patient;
  final void Function(Map<String, dynamic>) onEditPatient;

  const DoctorPatientDetail({
    required this.patient,
    required this.onEditPatient,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DoctorPatientDetail> createState() =>
      _DoctorPatientDetailState();
}

class _DoctorPatientDetailState extends ConsumerState<DoctorPatientDetail>
    with SingleTickerProviderStateMixin {
  late DoctorThemeData _thDt;
  late TabController _tabs;
  // Lab history — loaded lazily when the user opens the Lab tab
  List<Map<String, dynamic>> _labHistory = []; // [{visit, reports:[...]}]
  bool _loadingLabHistory = false;
  bool _labHistoryLoaded = false;

  // Imaging history — loaded lazily when the user opens the Imaging tab
  List<Map<String, dynamic>> _imageHistory = []; // [{visit, images:[...]}]
  bool _loadingImageHistory = false;
  bool _imageHistoryLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index == 2 && !_labHistoryLoaded && !_loadingLabHistory) {
      _loadLabHistory();
    }
    if (_tabs.index == 3 && !_imageHistoryLoaded && !_loadingImageHistory) {
      _loadImageHistory();
    }
  }

  Future<void> _loadLabHistory({bool forceRefresh = false}) async {
    if (_labHistoryLoaded && !forceRefresh) return;
    setState(() => _loadingLabHistory = true);
    try {
      final vm = ref.read(doctorViewModelProvider.notifier);

      final pid = int.tryParse((widget.patient['id'] ?? '').toString()) ?? 0;
      var visits = <Map<String, dynamic>>[];
      if (pid > 0) {
        try {
          visits = await vm.fetchVisits(pid);
        } catch (_) {}
      }

      // Sort newest-first, then fetch all visits in parallel
      final sorted = List<Map<String, dynamic>>.from(visits)
        ..sort((a, b) => _parseVisitDate(b).compareTo(_parseVisitDate(a)));

      final visitIds = sorted
          .map((v) => int.tryParse((v['id'] ?? 0).toString()) ?? 0)
          .where((id) => id > 0)
          .toList();

      final byVisit = visitIds.isNotEmpty
          ? await vm.fetchLabReportsForVisits(visitIds)
          : <int, List<Map<String, dynamic>>>{};

      final history = <Map<String, dynamic>>[];
      for (final v in sorted) {
        final vid = int.tryParse((v['id'] ?? 0).toString()) ?? 0;
        if (vid <= 0) continue;
        final reports = byVisit[vid];
        if (reports != null && reports.isNotEmpty) {
          history.add({'visit': v, 'reports': reports});
        }
      }

      if (mounted) {
        setState(() {
          _labHistory = history;
          _labHistoryLoaded = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingLabHistory = false);
    }
  }

  DateTime _parseVisitDate(Map<String, dynamic> v) {
    try {
      return DateTime.parse(
        (v['created_at'] ?? v['start_time'] ?? '').toString(),
      );
    } catch (_) {
      return DateTime(2000);
    }
  }

  String _fileTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'JPEG';
    if (lower.endsWith('.png')) return 'PNG';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'Word';
    return path.isNotEmpty ? 'File' : '';
  }

  Future<void> _loadImageHistory() async {
    if (_imageHistoryLoaded) return;
    setState(() => _loadingImageHistory = true);
    try {
      final vm = ref.read(doctorViewModelProvider.notifier);

      final pid = int.tryParse((widget.patient['id'] ?? '').toString()) ?? 0;
      var visits = <Map<String, dynamic>>[];
      if (pid > 0) {
        try {
          visits = await vm.fetchVisits(pid);
        } catch (_) {}
      }

      final history = <Map<String, dynamic>>[];
      for (final v in visits) {
        final vid = int.tryParse((v['id'] ?? 0).toString()) ?? 0;
        if (vid <= 0) continue;
        try {
          final images = await vm.fetchVisitImages(vid);
          if (images.isNotEmpty) {
            history.add({'visit': v, 'images': images});
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _imageHistory = history;
          _imageHistoryLoaded = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingImageHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _thDt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);
    // ── LIVE state — rebuilds automatically on every provider update ──────────
    final state = ref.watch(doctorViewModelProvider);

    // Always use the freshest patient record from state. Falls back to the
    // original prop only if the record has been deleted (edge case).
    final pid = (widget.patient['id'] ?? '').toString();
    final livePatient = state.patients.firstWhere(
      (p) => p['id'].toString() == pid,
      orElse: () => widget.patient,
    );

    // Derived name / age from live patient data
    final name =
        '${livePatient['first_name'] ?? ''} ${livePatient['last_name'] ?? ''}'
            .trim();

    int? age;
    final dob = livePatient['birth_date'] ?? livePatient['date_of_birth'];
    if (dob != null) {
      try {
        age =
            ((DateTime.now()
                        .difference(DateTime.parse(dob.toString()))
                        .inDays) /
                    365.25)
                .floor();
      } catch (_) {}
    }

    // Live appointments for this patient — sorted newest-first
    final liveAppts =
        state.appointments
            .where(
              (a) =>
                  (a['patient_id'] ?? a['patient']?['id'] ?? '').toString() ==
                  pid,
            )
            .toList()
          ..sort((a, b) {
            final da = DoctorViewModel.parseDate(a['start_time']);
            final db = DoctorViewModel.parseDate(b['start_time']);
            return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
          });

    // Live reports from state
    final liveReports = state.reports;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: _thDt.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _thDt.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // ── Header ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              decoration: const BoxDecoration(gradient: _T.gNavy),
              child: Row(
                children: [
                  DoctorAvatar(name: name, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (age != null) loc.yearsCount(age),
                            if ((livePatient['gender'] ?? '')
                                .toString()
                                .isNotEmpty)
                              (livePatient['gender'].toString().toUpperCase() ==
                                      'MALE'
                                  ? loc.male
                                  : loc.female),
                            if (livePatient['phone'] != null)
                              livePatient['phone'],
                          ].join('  •  '),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha:0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onEditPatient(livePatient),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                    tooltip: loc.editPatientTooltip,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // ── Tabs ─────────────────────────────────────────────────────────
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: _T.navy,
              unselectedLabelColor: _thDt.textM,
              indicatorColor: _T.navy,
              indicatorWeight: 2.5,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: loc.overviewTab),
                Tab(text: loc.reportsTab),
                Tab(text: loc.labReportsTabLabel),
                Tab(text: loc.medicalImagesTab),
              ],
            ),
            Divider(height: 1, color: _thDt.divider),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _overviewTab(ctrl, livePatient, liveAppts, loc),
                  _reportsTab(ctrl, liveReports, loc),
                  _labHistoryTab(ctrl, loc),
                  _imagingHistoryTab(ctrl, loc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overview tab ─────────────────────────────────────────────────────────────

  Widget _overviewTab(
    ScrollController ctrl,
    Map<String, dynamic> patient,
    List<Map<String, dynamic>> appts,
    AppLocalizations loc,
  ) {
    final p = patient; // live patient passed from ref.watch in build()
    final dash = '—';

    int? age;
    final dob = p['birth_date'] ?? p['date_of_birth'];
    if (dob != null) {
      try {
        age = ((DateTime.now().difference(DateTime.parse(dob.toString())).inDays) /
                365.25)
            .floor();
      } catch (_) {}
    }
    final genderRaw = (p['gender'] ?? '').toString();
    final gender = genderRaw.isEmpty
        ? null
        : (genderRaw.toUpperCase() == 'MALE' ? loc.male : loc.female);

    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.all(20),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _T.cardOf(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.patientInformation,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _thDt.textH,
                ),
              ),
              const SizedBox(height: 12),
              DoctorIRow(loc.idLabel, p['id']?.toString() ?? dash),
              DoctorIRow(loc.nationalIdLabel, p['national_id'] ?? dash),
              DoctorIRow(loc.phoneLabel, p['phone'] ?? dash),
              if (age != null) DoctorIRow(loc.ageLabel, loc.yearsCount(age)),
              if (gender != null) DoctorIRow(loc.genderLabel, gender),
              if (p['birth_date'] != null || p['date_of_birth'] != null)
                DoctorIRow(
                  loc.dateOfBirthLabel,
                  _fmtDate(p['birth_date'] ?? p['date_of_birth'], dash),
                ),
              if ((p['email'] ?? '').toString().isNotEmpty)
                DoctorIRow(loc.emailLabel, p['email']),
              DoctorIRow(loc.addressLabel, p['address'] ?? dash),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Chronic Diseases card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _T.cardOf(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.monitor_heart_outlined,
                    size: 15,
                    color: Color(0xFF6A1B9A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.chronicDiseases,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _thDt.textH,
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (_) {
                      final count = _chronicNames(p).length;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (_) {
                  final diseases = _chronicNames(p);
                  if (diseases.isEmpty) {
                    return Text(
                      loc.noChronicDiseasesRecorded,
                      style: TextStyle(fontSize: 12, color: _thDt.textS),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: diseases
                        .map(
                          (d) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF6A1B9A).withValues(alpha:0.3),
                              ),
                            ),
                            child: Text(
                              d,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6A1B9A),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          loc.recentAppointments,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _thDt.textH,
          ),
        ),
        const SizedBox(height: 8),
        // Live appointments from ref.watch state
        ...appts.take(3).map((a) {
          DateTime? dt;
          try {
            dt = DateTime.parse(a['start_time'].toString()).toLocal();
          } catch (_) {}
          final s = (a['status'] ?? '').toUpperCase();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: _T.cardOf(context, r: 12),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: _thDt.textM,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dt != null
                        ? DateFormat('dd MMM yyyy  •  hh:mm a').format(dt)
                        : loc.unknownDate,
                    style: TextStyle(fontSize: 12, color: _thDt.textS),
                  ),
                ),
                DoctorBadge(
                  label: _T.sLabel(s, loc),
                  fg: _T.sFg(s),
                  bg: _T.sBg(s),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Reports tab ─────────────────────────────────────────────────────────────

  Widget _reportsTab(
    ScrollController ctrl,
    List<Map<String, dynamic>> reports,
    AppLocalizations loc,
  ) {
    if (reports.isEmpty) {
      return DoctorEmpty(
        icon: Icons.description_outlined,
        title: loc.noReportsYet,
        sub: loc.noReportsYetSub,
      );
    }
    return ListView.separated(
      controller: ctrl,
      padding: const EdgeInsets.all(20),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = reports[i];

        // ── Build a descriptive header ──────────────────────────────────────
        // Shows: "Visit · dd MMM yyyy  •  hh:mm a"
        // Diagnosis preview shown as subtitle so the doctor knows which visit
        // the report belongs to before opening it.
        DateTime? dt;
        try {
          dt = DateTime.parse(
            (r['created_at'] ?? r['updated_at'] ?? '').toString(),
          ).toLocal();
        } catch (_) {}

        final visitNum = i + 1; // 1-indexed position in list
        final headerDate = dt != null
            ? DateFormat('dd MMM yyyy  •  hh:mm a').format(dt)
            : loc.unknownDate;
        final diagPreview = (r['ai_diagnosis'] ?? '').toString().trim();
        final hasContent = [
          r['ai_diagnosis'],
          r['ai_medications'],
          r['ai_recommendations'],
          r['ai_follow_up'],
          r['doctor_notes'],
        ].any((v) => v != null && v.toString().trim().isNotEmpty);

        return GestureDetector(
          onTap: () => _openReportDetail(r, visitNum, dt, loc),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _thDt.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _thDt.divider),
              boxShadow: [
                BoxShadow(
                  color: _T.navy.withValues(alpha:0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _T.tealPale,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        size: 18,
                        color: _T.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.visitNumHeader(visitNum, headerDate),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _thDt.textH,
                            ),
                          ),
                          if (diagPreview.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              diagPreview,
                              style: TextStyle(
                                fontSize: 11,
                                color: _thDt.textS,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _thDt.textM,
                      size: 20,
                    ),
                  ],
                ),
                // ── Content pills ─────────────────────────────────────────
                if (hasContent) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: _thDt.divider),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if ((r['ai_diagnosis'] ?? '').toString().isNotEmpty)
                        _ReportPill(
                          loc.pillDiagnosis,
                          _T.navy,
                          const Color(0xFFEFF4FB),
                        ),
                      if (r['ai_medications'] is List &&
                          (r['ai_medications'] as List).isNotEmpty)
                        _ReportPill(
                          loc.pillMedications,
                          const Color(0xFF6A1B9A),
                          const Color(0xFFF3E5F5),
                        ),
                      if (r['ai_recommendations'] is List &&
                          (r['ai_recommendations'] as List).isNotEmpty)
                        _ReportPill(loc.pillTreatment, _T.teal, _T.tealPale),
                      if ((r['ai_follow_up'] ?? '').toString().isNotEmpty)
                        _ReportPill(
                          loc.pillFollowUp,
                          const Color(0xFFE65100),
                          const Color(0xFFFFF3E0),
                        ),
                      if ((r['doctor_notes'] ?? '').toString().isNotEmpty)
                        _ReportPill(
                          loc.pillNotes,
                          _thDt.textS,
                          const Color(0xFFF5F7FA),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Lab History tab ──────────────────────────────────────────────────────────

  Widget _labHistoryTab(ScrollController ctrl, AppLocalizations loc) {
    if (_loadingLabHistory) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }

    if (!_labHistoryLoaded) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _loadLabHistory,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(loc.retry),
          style: OutlinedButton.styleFrom(
            foregroundColor: _T.navy,
            side: const BorderSide(color: _T.navy),
          ),
        ),
      );
    }

    if (_labHistory.isEmpty) {
      return RefreshIndicator(
        color: _T.navy,
        onRefresh: () => _loadLabHistory(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: DoctorEmpty(
              icon: Icons.science_outlined,
              title: loc.noLabRecordsAvailable,
              sub: loc.noLabRecordsAvailableSub,
            ),
          ),
        ),
      );
    }

    final patientName =
        '${widget.patient['first_name'] ?? ''} ${widget.patient['last_name'] ?? ''}'
            .trim();
    final patientId =
        int.tryParse((widget.patient['id'] ?? '').toString()) ?? 0;

    return RefreshIndicator(
      color: _T.navy,
      onRefresh: () => _loadLabHistory(forceRefresh: true),
      child: ListView.separated(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        itemCount: _labHistory.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final group = _labHistory[i];
          final visit = group['visit'] as Map<String, dynamic>;
          final reports =
              (group['reports'] as List).cast<Map<String, dynamic>>();

          DateTime? visitDate;
          try {
            visitDate = DateTime.parse(
              (visit['created_at'] ?? visit['start_time'] ?? '').toString(),
            ).toLocal();
          } catch (_) {}

          return _buildLabHistoryGroup(
            visit: visit,
            reports: reports,
            visitDate: visitDate,
            patientName: patientName,
            patientId: patientId,
            loc: loc,
          );
        },
      ),
    );
  }

  Widget _buildLabHistoryGroup({
    required Map<String, dynamic> visit,
    required List<Map<String, dynamic>> reports,
    required DateTime? visitDate,
    required String patientName,
    required int patientId,
    required AppLocalizations loc,
  }) {
    final dateStr = visitDate != null
        ? DateFormat('dd MMM yyyy').format(visitDate)
        : loc.unknownDate;
    final timeStr = visitDate != null
        ? DateFormat('hh:mm a').format(visitDate)
        : '';

    return Container(
      decoration: BoxDecoration(
        color: _thDt.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _thDt.divider),
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
          // ── Visit header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: _T.navy.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_rounded,
                  size: 15,
                  color: _T.navy,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _thDt.textH,
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style:
                              TextStyle(fontSize: 11, color: _thDt.textS),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    loc.labRecordsCount(reports.length),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Reports list ────────────────────────────────────────────────
          ...reports.map((r) {
            final testName = (r['test_name'] ?? '').toString().trim();
            final fileUrl = (r['report_url'] ?? '').toString().trim();
            final fileType = _fileTypeFromPath(fileUrl);

            DateTime? uploadedAt;
            try {
              uploadedAt = DateTime.parse(
                (r['uploaded_at'] ??
                        r['created_at'] ??
                        r['updated_at'] ??
                        '')
                    .toString(),
              ).toLocal();
            } catch (_) {}

            return InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LabReportViewerPage(
                    report: r,
                    patientName: patientName,
                    patientId: patientId,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _thDt.divider),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        fileType == 'PDF'
                            ? Icons.picture_as_pdf_rounded
                            : Icons.description_rounded,
                        color: const Color(0xFFD32F2F),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + file type badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  testName.isNotEmpty
                                      ? testName
                                      : loc.labReportViewerTitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _thDt.textH,
                                  ),
                                ),
                              ),
                              if (fileType.isNotEmpty && fileType != 'File') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFD32F2F)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    fileType,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFD32F2F),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // Upload date
                          if (uploadedAt != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 11,
                                  color: _thDt.textM,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${loc.uploadedOnLabel}: ${DateFormat('dd MMM yyyy  •  hh:mm a').format(uploadedAt)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _thDt.textS,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // View link
                          const SizedBox(height: 6),
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
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _thDt.textM,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Imaging History tab ──────────────────────────────────────────────────────

  Widget _imagingHistoryTab(ScrollController ctrl, AppLocalizations loc) {
    if (_loadingImageHistory) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }

    if (!_imageHistoryLoaded) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _loadImageHistory,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(loc.retry),
          style: OutlinedButton.styleFrom(
            foregroundColor: _T.navy,
            side: const BorderSide(color: _T.navy),
          ),
        ),
      );
    }

    if (_imageHistory.isEmpty) {
      return DoctorEmpty(
        icon: Icons.biotech_outlined,
        title: loc.noImagingHistoryYet,
        sub: loc.noImagingHistoryYetSub,
      );
    }

    return ListView.separated(
      controller: ctrl,
      padding: const EdgeInsets.all(20),
      itemCount: _imageHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final group = _imageHistory[i];
        final visit = group['visit'] as Map<String, dynamic>;
        final images =
            (group['images'] as List).cast<Map<String, dynamic>>();

        DateTime? visitDate;
        try {
          visitDate = DateTime.parse(
            (visit['created_at'] ?? visit['start_time'] ?? '').toString(),
          ).toLocal();
        } catch (_) {}

        return _buildImageHistoryGroup(
          visit: visit,
          images: images,
          visitDate: visitDate,
          loc: loc,
        );
      },
    );
  }

  Widget _buildImageHistoryGroup({
    required Map<String, dynamic> visit,
    required List<Map<String, dynamic>> images,
    required DateTime? visitDate,
    required AppLocalizations loc,
  }) {
    final dateStr = visitDate != null
        ? DateFormat('dd MMM yyyy').format(visitDate)
        : loc.unknownDate;
    final timeStr =
        visitDate != null ? DateFormat('hh:mm a').format(visitDate) : '';

    return Container(
      decoration: BoxDecoration(
        color: _thDt.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _thDt.divider),
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
          // ── Visit header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: _T.navy.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.biotech_rounded,
                  size: 15,
                  color: _T.navy,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _thDt.textH,
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(fontSize: 11, color: _thDt.textS),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _T.tealPale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${images.length} image${images.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _T.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Images list ───────────────────────────────────────────────────
          ...images.map((img) {
            final imageType =
                (img['image_type'] ?? img['imageType'] ?? 'IMAGE')
                    .toString()
                    .toUpperCase();
            final hasAiReport = img['ai_report'] != null;

            DateTime? imgDate;
            try {
              imgDate = DateTime.parse(
                (img['created_at'] ?? img['updated_at'] ?? '').toString(),
              ).toLocal();
            } catch (_) {}

            return InkWell(
              onTap: () => _openImageDetail(img, imageType, imgDate, loc),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: _thDt.divider)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _T.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.medical_information_rounded,
                        color: _T.navy,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            imageType == 'XRAY' ? loc.xray : imageType == 'SKIN' ? loc.skin : imageType,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _thDt.textH,
                            ),
                          ),
                          if (imgDate != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy  •  hh:mm a')
                                  .format(imgDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: _thDt.textS,
                              ),
                            ),
                          ],
                          if (hasAiReport) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 12,
                                  color: _T.teal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  loc.aiAnalysisAvailable,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _T.teal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _thDt.textM,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openImageDetail(
    Map<String, dynamic> img,
    String imageType,
    DateTime? date,
    AppLocalizations loc,
  ) {
    // Extract AI analysis data from the image record
    Map<String, dynamic>? aiData;
    final raw = img['ai_report'];
    if (raw is Map) {
      aiData = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        aiData = {'summary': raw};
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: _thDt.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _thDt.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                decoration: const BoxDecoration(gradient: _T.gNavy),
                child: Row(
                  children: [
                    const Icon(
                      Icons.biotech_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            imageType == 'XRAY'
                                ? loc.xray
                                : imageType == 'SKIN'
                                    ? loc.skin
                                    : imageType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (date != null)
                            Text(
                              DateFormat('EEEE, dd MMM yyyy  •  hh:mm a')
                                  .format(date),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: aiData != null
                    ? ListView(
                        controller: ctrl,
                        padding: const EdgeInsets.all(16),
                        children: [
                          AIAnalysisResultWidget(
                            result: aiData,
                            isLoading: false,
                          ),
                        ],
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.hourglass_empty_rounded,
                                size: 48,
                                color: _thDt.textS.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                loc.noImagingHistoryYetSub,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _thDt.textS,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Open full report detail ───────────────────────────────────────────────

  void _openReportDetail(
    Map<String, dynamic> r,
    int visitNum,
    DateTime? dt,
    AppLocalizations loc,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: _thDt.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _thDt.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // ── Title bar ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                decoration: const BoxDecoration(gradient: _T.gNavy),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.visitReportTitle(visitNum),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (dt != null)
                            Text(
                              DateFormat(
                                'EEEE, dd MMM yyyy  •  hh:mm a',
                              ).format(dt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha:0.65),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _reportSection(
                      icon: Icons.medical_information_rounded,
                      label: loc.pillDiagnosis,
                      color: _T.navy,
                      bg: const Color(0xFFEFF4FB),
                      value: r['ai_diagnosis'],
                    ),
                    _reportSection(
                      icon: Icons.medication_rounded,
                      label: loc.pillMedications,
                      color: const Color(0xFF6A1B9A),
                      bg: const Color(0xFFF3E5F5),
                      value: r['ai_medications'],
                    ),
                    _reportSection(
                      icon: Icons.healing_rounded,
                      label: loc.treatmentRecommendations,
                      color: _T.teal,
                      bg: _T.tealPale,
                      value: r['ai_recommendations'],
                    ),
                    _reportSection(
                      icon: Icons.event_repeat_rounded,
                      label: loc.pillFollowUp,
                      color: const Color(0xFFE65100),
                      bg: const Color(0xFFFFF3E0),
                      value: r['ai_follow_up'],
                    ),
                    _reportSection(
                      icon: Icons.note_alt_rounded,
                      label: loc.doctorNotesLabel,
                      color: _thDt.textS,
                      bg: const Color(0xFFF5F7FA),
                      value: r['doctor_notes'],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Single report section card ─────────────────────────────────────────────

  Widget _reportSection({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required dynamic value,
  }) {
    if (value == null) return const SizedBox.shrink();

    String formatted = '';
    if (value is List) {
      if (value.isEmpty) return const SizedBox.shrink();
      if (value.first is Map) {
        // Medication objects
        formatted = value
            .map((item) {
              final m = Map<String, dynamic>.from(item as Map);
              final parts = <String>[];
              final name =
                  (m['name'] ?? m['drug_name'] ?? m['medication'] ?? '')
                      .toString()
                      .trim();
              final dose = (m['dose'] ?? m['dosage'] ?? '').toString().trim();
              final freq = (m['frequency'] ?? m['freq'] ?? '')
                  .toString()
                  .trim();
              final dur = (m['duration'] ?? '').toString().trim();
              final notes = (m['notes'] ?? m['note'] ?? '').toString().trim();
              if (name.isNotEmpty) parts.add(name);
              if (dose.isNotEmpty) parts.add('Dose: $dose');
              if (freq.isNotEmpty) parts.add('Frequency: $freq');
              if (dur.isNotEmpty) parts.add('Duration: $dur');
              if (notes.isNotEmpty) parts.add('Notes: $notes');
              return parts.join('  |  ');
            })
            .where((s) => s.isNotEmpty)
            .join('\n');
      } else {
        formatted = value
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .join('\n');
      }
    } else {
      formatted = value.toString().trim();
    }

    if (formatted.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _thDt.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha:0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha:0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
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
          // Section content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              formatted,
              style: TextStyle(fontSize: 13, color: _thDt.textH, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  // Extracts chronic condition names from the backend-provided patient_conditions
  // array. Handles both flattened and nested condition response shapes.
  static List<String> _chronicNames(Map<String, dynamic> patient) {
    final raw = patient['patient_conditions'];
    if (raw is! List) return [];
    final result = <String>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final cat =
          (item['category'] ?? (item['condition'] as Map?)?['category'] ?? '')
              .toString()
              .toUpperCase();
      if (cat != 'CHRONIC') continue;
      final name =
          (item['name'] ?? (item['condition'] as Map?)?['name'] ?? '')
              .toString();
      if (name.isNotEmpty) result.add(name);
    }
    return result;
  }

  String _fmtDate(dynamic v, String dash) {
    if (v == null) return dash;
    try {
      return DateFormat(
        'dd MMM yyyy',
      ).format(DateTime.parse(v.toString()).toLocal());
    } catch (_) {
      return dash;
    }
  }
}

// ── Report Pill ──────────────────────────────────────────────────────────────

class _ReportPill extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _ReportPill(this.label, this.color, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha:0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      ),
    ),
  );
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class DoctorIRow extends StatelessWidget {
  final String label, value;
  const DoctorIRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: dt.textS,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: dt.textH,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Condition Chip (kept for potential future use elsewhere) ──────────────────

class DoctorCondChip extends StatelessWidget {
  final Map<String, dynamic> cond;
  final VoidCallback onRemove;
  const DoctorCondChip({required this.cond, required this.onRemove, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _T.urgentBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _T.urgent.withValues(alpha:0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          cond['name'] ?? '',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _T.urgent,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 14, color: _T.urgent),
        ),
      ],
    ),
  );
}
