// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_patient_detail.dart
//
// DoctorPatientDetail — DraggableScrollableSheet with Overview / Visits /
// Reports tabs.  DoctorIRow, DoctorCondChip helper widgets.
//
// Reads doctorViewModelProvider directly (ConsumerStatefulWidget) so it can
// call vm.fetchVisits / vm.assignCondition / vm.removeCondition without any
// callback chain through parent pages.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';

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
  late TabController _tabs;
  List<Map<String, dynamic>> _visits = [];
  bool _loadingVisits = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadVisits();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadVisits() async {
    final pid = int.tryParse((widget.patient['id'] ?? '').toString()) ?? 0;
    if (pid == 0) {
      setState(() => _loadingVisits = false);
      return;
    }
    try {
      final vm = ref.read(doctorViewModelProvider.notifier);
      final d = await vm.fetchVisits(pid);
      if (mounted)
        setState(() {
          _visits = d;
          _loadingVisits = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingVisits = false);
    }
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

  @override
  Widget build(BuildContext context) {
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
        decoration: const BoxDecoration(
          color: _T.bgCard,
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
                    color: _T.divider,
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
                            if (age != null) '$age yrs',
                            if ((livePatient['gender'] ?? '')
                                .toString()
                                .isNotEmpty)
                              (livePatient['gender'].toString().toUpperCase() ==
                                      'MALE'
                                  ? 'Male'
                                  : 'Female'),
                            if (livePatient['phone'] != null)
                              livePatient['phone'],
                          ].join('  •  '),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onEditPatient(livePatient),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                    tooltip: 'Edit Patient',
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
              labelColor: _T.navy,
              unselectedLabelColor: _T.textM,
              indicatorColor: _T.navy,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Visits'),
                Tab(text: 'Reports'),
              ],
            ),
            const Divider(height: 1, color: _T.divider),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _overviewTab(ctrl, livePatient, liveAppts),
                  _visitsTab(ctrl),
                  _reportsTab(ctrl, liveReports),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overview tab ─────────────────────────────────────────────────────────────

  // ── Overview tab ─────────────────────────────────────────────────────────────

  Widget _overviewTab(
    ScrollController ctrl,
    Map<String, dynamic> patient,
    List<Map<String, dynamic>> appts,
  ) {
    final p = patient; // live patient passed from ref.watch in build()
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.all(20),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _T.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _T.textH,
                ),
              ),
              const SizedBox(height: 12),
              DoctorIRow('National ID', p['national_id'] ?? '—'),
              DoctorIRow('Phone', p['phone'] ?? '—'),
              DoctorIRow('Region', p['region'] ?? '—'),
              if (p['birth_date'] != null || p['date_of_birth'] != null)
                DoctorIRow(
                  'Date of Birth',
                  _fmtDate(p['birth_date'] ?? p['date_of_birth']),
                ),
              if ((p['email'] ?? '').toString().isNotEmpty)
                DoctorIRow('Email', p['email']),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Chronic Diseases card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _T.card(),
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
                  const Text(
                    'Chronic Diseases',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _T.textH,
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (_) {
                      final count =
                          (p['chronic_diseases'] as List?)?.length ?? 0;
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
                          '$count/5',
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
                  final diseases = List<String>.from(
                    p['chronic_diseases'] ?? [],
                  );
                  if (diseases.isEmpty) {
                    return const Text(
                      'No chronic diseases recorded',
                      style: TextStyle(fontSize: 12, color: _T.textS),
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
                                color: const Color(0xFF6A1B9A).withOpacity(0.3),
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
        const Text(
          'Recent Appointments',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _T.textH,
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
            decoration: _T.card(r: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: _T.textM,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dt != null
                        ? DateFormat('dd MMM yyyy  •  hh:mm a').format(dt)
                        : 'Unknown date',
                    style: const TextStyle(fontSize: 12, color: _T.textS),
                  ),
                ),
                DoctorBadge(label: _T.sLabel(s), fg: _T.sFg(s), bg: _T.sBg(s)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Visits tab ────────────────────────────────────────────────────────────────

  Widget _visitsTab(ScrollController ctrl) {
    if (_loadingVisits) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }
    if (_visits.isEmpty) {
      return const DoctorEmpty(
        icon: Icons.assignment_outlined,
        title: 'No visits recorded',
        sub: 'Visits appear here after consultations.',
      );
    }
    return ListView.separated(
      controller: ctrl,
      padding: const EdgeInsets.all(20),
      itemCount: _visits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final v = _visits[i];
        DateTime? dt;
        try {
          dt = DateTime.parse(
            (v['created_at'] ?? v['start_time'] ?? '').toString(),
          ).toLocal();
        } catch (_) {}
        final s = (v['status'] ?? '').toUpperCase();
        final diag = v['diagnosis'] ?? v['chief_complaint'] ?? '';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _T.card(r: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.assignment_rounded,
                    size: 15,
                    color: _T.navy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dt != null ? DateFormat('dd MMM yyyy').format(dt) : '—',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.textH,
                      ),
                    ),
                  ),
                  DoctorBadge(
                    label: _T.sLabel(s),
                    fg: _T.sFg(s),
                    bg: _T.sBg(s),
                  ),
                ],
              ),
              if (diag.toString().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  diag.toString(),
                  style: const TextStyle(fontSize: 12, color: _T.textS),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Reports tab ───────────────────────────────────────────────────────────────

  Widget _reportsTab(
    ScrollController ctrl,
    List<Map<String, dynamic>> reports,
  ) {
    if (reports.isEmpty) {
      return const DoctorEmpty(
        icon: Icons.description_outlined,
        title: 'No reports yet',
      );
    }
    return ListView.separated(
      controller: ctrl,
      padding: const EdgeInsets.all(20),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = reports[i];
        DateTime? dt;
        try {
          dt = DateTime.parse(r['created_at'].toString()).toLocal();
        } catch (_) {}
        final content = r['content'] ?? r['transcription'] ?? r['notes'] ?? '';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _T.card(r: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    size: 15,
                    color: _T.teal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r['report_type'] ?? 'Medical Report',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.textH,
                      ),
                    ),
                  ),
                  if (dt != null)
                    Text(
                      DateFormat('dd MMM').format(dt),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _T.textM,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
              if (content.toString().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  content.toString(),
                  style: const TextStyle(fontSize: 12, color: _T.textS),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    try {
      return DateFormat(
        'dd MMM yyyy',
      ).format(DateTime.parse(v.toString()).toLocal());
    } catch (_) {
      return '—';
    }
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class DoctorIRow extends StatelessWidget {
  final String label, value;
  const DoctorIRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _T.textS,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _T.textH,
            ),
          ),
        ),
      ],
    ),
  );
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
      border: Border.all(color: _T.urgent.withOpacity(0.3)),
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
