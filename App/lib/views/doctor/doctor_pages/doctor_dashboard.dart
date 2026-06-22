// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_pages/doctor_dashboard.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// CHANGES IN THIS VERSION:
//   + Revenue-today figure now uses NumberFormat.decimalPattern(localeCode)
//     so digits render as Arabic-Indic (١٢٣...) when the app locale is 'ar',
//     matching the date/time formatting already in place.
//   + 'EGP' replaced with loc.currencyEgp.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_profile_page.dart';

typedef _T = DoctorTheme;

class DoctorDashboardPage extends ConsumerWidget {
  final UserProfile doctorProfile;
  final void Function(int) onNav;

  /// Wire up in DoctorInterface to open ConsultationPage with the appointment.
  /// If null the "Start consultation" button renders but is disabled.
  final void Function(Map<String, dynamic>)? onStartConsultation;

  const DoctorDashboardPage({
    required this.doctorProfile,
    required this.onNav,
    this.onStartConsultation,
    Key? key,
  }) : super(key: key);

  String _greet(AppLocalizations loc) {
    final h = DateTime.now().hour;
    if (h < 12) return loc.goodMorning;
    if (h < 17) return loc.goodAfternoon;
    return loc.goodEvening;
  }

  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _typeLabel(Map<String, dynamic> a) {
    final raw = a['appointment_type_name'] ?? a['appointment_type'];
    if (raw is Map)
      return (raw['name'] ?? raw['type_name'] ?? 'Consultation').toString();
    final s = raw?.toString().trim() ?? '';
    return s.isNotEmpty ? s : 'Consultation';
  }

  static String _apptName(Map<String, dynamic> a) {
    final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
    final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
    final full = '$fn $ln'.trim();
    return full.isEmpty ? 'Unknown Patient' : full;
  }

  Widget _sectionLabel(
    DoctorThemeData dt,
    String title, {
    String? linkLabel,
    VoidCallback? onLink,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: dt.textH,
          ),
        ),
        if (linkLabel != null)
          GestureDetector(
            onTap: onLink,
            child: Text(
              linkLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _T.navy,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final vm = ref.read(doctorViewModelProvider.notifier);
    final state = ref.watch(doctorViewModelProvider);
    final loading = state.loadingAppointments || state.loadingPatients;

    final today = vm.todayAppointments;
    final next = vm.nextAppointment;
    final seenToday = today
        .where((a) => (a['status'] ?? '').toUpperCase() == 'COMPLETED')
        .length;
    final remainingToday = today.where((a) {
      final s = (a['status'] ?? '').toUpperCase();
      return s != 'COMPLETED' && s != 'CANCELLED';
    }).length;
    final totalPatients = state.patients.length;
    final revenueToday = today.fold<double>(0, (sum, a) {
      if ((a['status'] ?? '').toUpperCase() == 'CANCELLED') return sum;
      return sum + (double.tryParse((a['fee'] ?? 0).toString()) ?? 0);
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(doctorViewModelProvider.notifier).loadAll(),
      color: _T.navy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── 1. GREETING BANNER (unchanged) ───────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DoctorProfilePage(doctorProfile: doctorProfile),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: _T.gradCard(),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greet(loc),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.drPrefix(doctorProfile.firstName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              today.isEmpty
                                  ? loc.noAppointmentsToday
                                  : loc.appointmentsDoneCount(
                                      today.length,
                                      seenToday,
                                    ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Image.asset(
                        'assets/icon/app_icon3.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: CircularProgressIndicator(
                    color: _T.navy,
                    strokeWidth: 2,
                  ),
                ),
              )
            else ...[
              // ── 2. CLINIC OVERVIEW ──────────────────────────────────────────
              _sectionLabel(dt, loc.clinicOverview),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OverviewCard(
                      icon: Icons.check_circle_outline,
                      iconBg: const Color(0xFFE1F5EE),
                      iconColor: const Color(0xFF0F6E56),
                      value: arNumber(seenToday, localeCode),
                      total: arNumber(today.length, localeCode),
                      label: loc.seenToday,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OverviewCard(
                      icon: Icons.pending_actions_outlined,
                      iconBg: const Color(0xFFE6F1FB),
                      iconColor: const Color(0xFF185FA5),
                      value: arNumber(remainingToday, localeCode),
                      label: loc.remaining,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OverviewCard(
                      icon: Icons.people_alt_outlined,
                      iconBg: const Color(0xFFEEEDFE),
                      iconColor: const Color(0xFF534AB7),
                      value: arNumber(totalPatients, localeCode),
                      label: loc.patients,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OverviewCard(
                      icon: Icons.payments_outlined,
                      iconBg: const Color(0xFFFAEEDA),
                      iconColor: const Color(0xFF854F0B),
                      // FIXED: was 'EGP ${revenueToday.toStringAsFixed(0)}'
                      // — hardcoded EGP + digits that never localized because
                      // NumberFormat('ar') doesn't reliably switch numeral
                      // script. arNumber() does direct digit substitution.
                      value:
                          '${loc.currencyEgp} ${arNumber(revenueToday.round(), localeCode)}',
                      label: loc.revenueToday,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── 3. PATIENT ACTIVITY CHART ───────────────────────────────────
              _sectionLabel(dt, loc.patientActivity),
              const SizedBox(height: 10),
              _ClinicTrendChart(appointments: state.appointments),

              const SizedBox(height: 24),

              // ── 4. UP NEXT ──────────────────────────────────────────────────
              _sectionLabel(
                dt,
                loc.upNext,
                linkLabel: loc.allAppointments,
                onLink: () => onNav(1),
              ),
              const SizedBox(height: 10),
              if (next == null)
                _EmptyCard(
                  icon: Icons.calendar_today_outlined,
                  title: loc.noUpcomingAppointments,
                  sub: loc.allCaughtUp,
                )
              else
                _UpNextCard(
                  appointment: next,
                  onStartConsultation: onStartConsultation != null
                      ? () => onStartConsultation!(next)
                      : null,
                ),

              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OverviewCard
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String value, label;
  final String? total;

  const _OverviewCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D6B).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: dt.textH,
                          height: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (total != null)
                      Text(
                        ' / $total',
                        style: TextStyle(
                          fontSize: 12,
                          color: dt.textS,
                          height: 1.1,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 10, color: dt.textS)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UpNextCard
// ─────────────────────────────────────────────────────────────────────────────

class _UpNextCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onStartConsultation;

  const _UpNextCard({required this.appointment, this.onStartConsultation});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final a = appointment;
    final apptDt = DoctorDashboardPage.parseDate(a['start_time']);
    final localeCode = Localizations.localeOf(context).languageCode;
    final time = apptDt != null
        ? arDigits(DateFormat('hh:mm a', localeCode).format(apptDt), localeCode)
        : '--';
    final name = DoctorDashboardPage._apptName(a);
    final status = (a['status'] ?? 'SCHEDULED').toUpperCase();
    final urgent = a['is_urgent'] == true;
    final type = DoctorDashboardPage._typeLabel(a);
    final diseases = <String>{
      ...List<String>.from(a['chronic_diseases'] ?? []),
      ...List<String>.from(a['patient']?['chronic_diseases'] ?? []),
    }.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dt.divider),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D6B).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFE6F1FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: Color(0xFF185FA5),
                ),
                const SizedBox(width: 6),
                Text(
                  loc.startingAt(time),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0C447C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (urgent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEBEB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      loc.urgentBadge,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFA32D2D),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                DoctorBadge(
                  label: DoctorTheme.sLabel(status, loc),
                  fg: DoctorTheme.sFg(status),
                  bg: DoctorTheme.sBg(status),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: dt.textH,
                  ),
                ),
                const SizedBox(height: 3),
                Text(type, style: TextStyle(fontSize: 12, color: dt.textS)),
                if (diseases.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: diseases
                        .map(
                          (d) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCEBEB),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              d,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF791F1F),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStartConsultation,
                    style: FilledButton.styleFrom(
                      backgroundColor: DoctorTheme.navy,
                      disabledBackgroundColor: DoctorTheme.navy.withOpacity(
                        0.35,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      loc.startConsultation,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// _ClinicTrendChart  — fl_chart LineChart with Month / 6-Month toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ClinicTrendChart extends StatefulWidget {
  final List<Map<String, dynamic>> appointments;
  const _ClinicTrendChart({required this.appointments});

  @override
  State<_ClinicTrendChart> createState() => _ClinicTrendChartState();
}

class _ClinicTrendChartState extends State<_ClinicTrendChart> {
  // 0 = Month  |  1 = 6 Months  |  2 = 1 Year
  int _mode = 0;

  // ── Month: daily spots compressed to ~8 points ────────────────────────────
  List<FlSpot> _dailySpots() {
    final now = DateTime.now();
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    final counts = List<int>.filled(days, 0);
    for (final a in widget.appointments) {
      final apptDt = DoctorDashboardPage.parseDate(a['start_time']);
      if (apptDt == null) continue;
      if (apptDt.year == now.year && apptDt.month == now.month)
        counts[apptDt.day - 1]++;
    }
    final step = (days / 8).ceil();
    final spots = <FlSpot>[];
    for (int i = 0; i < days; i += step) {
      final end = (i + step).clamp(0, days);
      final total = counts.sublist(i, end).fold(0, (s, c) => s + c);
      spots.add(FlSpot((i + 1).toDouble(), total.toDouble()));
    }
    return spots;
  }

  // ── 6 Months: one point per month ────────────────────────────────────────
  List<FlSpot> _sixMonthSpots() {
    final now = DateTime.now();
    final counts = List<int>.filled(6, 0);
    for (final a in widget.appointments) {
      final apptDt = DoctorDashboardPage.parseDate(a['start_time']);
      if (apptDt == null) continue;
      final mAgo = (now.year - apptDt.year) * 12 + (now.month - apptDt.month);
      if (mAgo >= 0 && mAgo < 6) counts[5 - mAgo]++;
    }
    return List.generate(6, (i) => FlSpot(i.toDouble(), counts[i].toDouble()));
  }

  // ── 1 Year: one point per month for last 12 months ────────────────────────
  List<FlSpot> _yearlySpots() {
    final now = DateTime.now();
    final counts = List<int>.filled(12, 0);
    for (final a in widget.appointments) {
      final apptDt = DoctorDashboardPage.parseDate(a['start_time']);
      if (apptDt == null) continue;
      final mAgo = (now.year - apptDt.year) * 12 + (now.month - apptDt.month);
      if (mAgo >= 0 && mAgo < 12) counts[11 - mAgo]++;
    }
    return List.generate(12, (i) => FlSpot(i.toDouble(), counts[i].toDouble()));
  }

  // ── X-axis label per mode ─────────────────────────────────────────────────
  String _xLabel(double v) {
    final now = DateTime.now();
    if (_mode == 0) return '${v.toInt()}'; // day number
    if (_mode == 1) {
      // 6 months: index 0 = 5 months ago, index 5 = current month
      final month = DateTime(now.year, now.month - 5 + v.toInt());
      return DateFormat('MMM').format(month);
    }
    // 1 year: index 0 = 11 months ago, index 11 = current month
    final month = DateTime(now.year, now.month - 11 + v.toInt());
    return DateFormat('MMM').format(month);
  }

  String _headerLabel(AppLocalizations loc) {
    switch (_mode) {
      case 1:
        return loc.appointmentsLast6Months;
      case 2:
        return loc.appointmentsLast12Months;
      default:
        return loc.appointmentsThisMonth;
    }
  }

  List<FlSpot> get _spots {
    switch (_mode) {
      case 1:
        return _sixMonthSpots();
      case 2:
        return _yearlySpots();
      default:
        return _dailySpots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _spots;
    final maxY = spots.isEmpty
        ? 5.0
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2).clamp(
            4.0,
            double.infinity,
          );
    final total = spots.fold(0.0, (s, p) => s + p.y).toInt();
    final hasData = spots.any((s) => s.y > 0);
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D6B).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _headerLabel(loc),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: dt.textH,
                ),
              ),
              Text(
                hasData ? loc.totalVisits(total) : loc.noDataYet,
                style: TextStyle(fontSize: 11, color: dt.textS),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── 3-way toggle — full width so it never overflows ───────────────
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: dt.bgInput,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _ToggleBtn(
                    label: loc.month,
                    active: _mode == 0,
                    onTap: () => setState(() => _mode = 0),
                  ),
                ),
                Expanded(
                  child: _ToggleBtn(
                    label: loc.sixMo,
                    active: _mode == 1,
                    onTap: () => setState(() => _mode = 1),
                  ),
                ),
                Expanded(
                  child: _ToggleBtn(
                    label: loc.oneYear,
                    active: _mode == 2,
                    onTap: () => setState(() => _mode = 2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── LineChart ─────────────────────────────────────────────────────
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 4).clamp(1, double.infinity),
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFE8EEF6), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (maxY / 4).clamp(1, double.infinity),
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: TextStyle(fontSize: 10, color: dt.textS),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final has = spots.any((s) => (s.x - v).abs() < 0.01);
                        if (!has) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _xLabel(v),
                            style: TextStyle(fontSize: 10, color: dt.textS),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => dt.accent,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touched) => touched
                        .map(
                          (s) => LineTooltipItem(
                            '${s.y.toInt()} visits',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: dt.accent,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: dt.accent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          dt.accent.withOpacity(0.15),
                          dt.accent.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          ),

          // ── Legend ────────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 3,
                decoration: BoxDecoration(
                  color: dt.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                loc.appointmentsLegend,
                style: TextStyle(fontSize: 11, color: dt.textS),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? dt.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : dt.textS,
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final bool tall;
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.sub,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: tall ? 48 : 24, horizontal: 20),
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D6B).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: tall
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 52, color: dt.textM.withOpacity(0.45)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: dt.textH,
                  ),
                ),
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(fontSize: 12, color: dt.textS)),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dt.bgInput,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: dt.textM),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: dt.textH,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(sub, style: TextStyle(fontSize: 12, color: dt.textS)),
                  ],
                ),
              ],
            ),
    );
  }
}
