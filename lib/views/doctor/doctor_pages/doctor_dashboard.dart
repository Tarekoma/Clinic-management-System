// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_dashboard.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_profile_page.dart';

typedef _T = DoctorTheme;

class DoctorDashboardPage extends ConsumerWidget {
  final UserProfile doctorProfile;
  final void Function(int) onNav;

  const DoctorDashboardPage({
    required this.doctorProfile,
    required this.onNav,
    Key? key,
  }) : super(key: key);

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(doctorViewModelProvider.notifier);
    final state = ref.watch(doctorViewModelProvider);
    final loading = state.loadingAppointments;

    final today = vm.todayAppointments;
    final next = vm.nextAppointment;
    final completed = today
        .where((a) => (a['status'] ?? '').toUpperCase() == 'COMPLETED')
        .length;
    final totalPatients = state.patients?.length ?? 0;

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

            // ── Greeting banner ──────────────────────────────────────────
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
                            _greet(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dr. ${doctorProfile.firstName}',
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
                                  ? 'No appointments today'
                                  : '${today.length} appointment${today.length > 1 ? "s" : ""} today',
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

                    // ── CHANGED: Shield logo instead of + icon ───────────
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/icon/app_icon3.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
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

            // ── Stats row ────────────────────────────────────────────────
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(
                    color: _T.navy,
                    strokeWidth: 2,
                  ),
                ),
              )
            else ...[
              // ── CHANGED: IntrinsicHeight makes both cards equal height ─
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_alt_outlined,
                        iconBg: const Color(0xFFE8EEF6),
                        iconColor: _T.navy,
                        value: '$totalPatients',
                        label: 'Total Patients',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.calendar_month_outlined,
                        iconBg: const Color(0xFFE0F4F1),
                        iconColor: _T.teal,
                        value: '${today.length}',
                        label: 'Today',
                        subLabel: '$completed done',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Up Next ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Up Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _T.textH,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onNav(1),
                    child: const Text(
                      'All Appointments',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _T.navy,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (next == null)
                _EmptyCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'No upcoming appointments',
                  sub: "You're all caught up!",
                )
              else
                _buildTimelineRow(next),

              const SizedBox(height: 24),

              // ── Today's Schedule ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Schedule",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _T.textH,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onNav(1),
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _T.navy.withOpacity(0.75),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (today.isEmpty)
                _EmptyCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'No appointments today',
                  sub: 'Enjoy your free day!',
                  tall: true,
                )
              else
                Column(
                  children: today
                      .take(6)
                      .map((a) => _buildTimelineRow(a))
                      .toList(),
                ),
            ],

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(Map<String, dynamic> a) {
    DateTime? dt;
    try {
      dt = DateTime.parse(a['start_time'].toString()).toLocal();
    } catch (_) {}
    final time = dt != null ? DateFormat('hh:mm a').format(dt) : '--';
    final name = _apptName(a);
    final status = (a['status'] ?? 'SCHEDULED').toUpperCase();
    final urgent = a['is_urgent'] == true;
    final type =
        a['appointment_type_name'] ?? a['appointment_type'] ?? 'Consultation';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: _T.card(r: 14),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _T.navy,
              ),
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: urgent ? _T.urgent : _T.sFg(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _T.textH,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: const TextStyle(fontSize: 11, color: _T.textS),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DoctorBadge(
                label: _T.sLabel(status),
                fg: _T.sFg(status),
                bg: _T.sBg(status),
              ),
              if (urgent) ...[
                const SizedBox(height: 4),
                const DoctorBadge(
                  label: 'URGENT',
                  fg: _T.urgent,
                  bg: _T.urgentBg,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _apptName(Map<String, dynamic> a) {
    final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
    final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
    final full = '$fn $ln'.trim();
    return full.isEmpty ? 'Unknown Patient' : full;
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String? subLabel;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // No fixed height — IntrinsicHeight in parent handles equal sizing
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D6B).withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: DoctorTheme.textH,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: DoctorTheme.textS),
              ),
              if (subLabel != null)
                Text(
                  subLabel!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: DoctorTheme.textM,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool tall;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.sub,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: tall ? 48 : 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                Icon(
                  icon,
                  size: 52,
                  color: DoctorTheme.textM.withOpacity(0.45),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DoctorTheme.textH,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DoctorTheme.textS,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: DoctorTheme.textM),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DoctorTheme.textH,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DoctorTheme.textS,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
