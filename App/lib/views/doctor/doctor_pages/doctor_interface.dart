// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_interface.dart
//
// Shell widget: top bar, animated bottom nav, page router.
// Navigation index is the only local state — everything else comes from
// the ViewModel via Riverpod.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/views/auths/login_page.dart';
import 'package:Hakim/views/doctor/consultation/consultation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_dashboard.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_appointments_page.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_patients_page.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_finance_page.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_profile_page.dart';

typedef _T = DoctorTheme;

// ── Nav item data ─────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = [
  _NavItem(Icons.dashboard_rounded, 'Dashboard'),
  _NavItem(Icons.calendar_month_rounded, 'Appointments'),
  _NavItem(Icons.people_alt_rounded, 'Patients'),
  _NavItem(Icons.account_balance_wallet_rounded, 'Finance'),
];

// ── DoctorInterface ───────────────────────────────────────────────────────────

class DoctorInterface extends ConsumerStatefulWidget {
  final UserProfile doctorProfile;
  const DoctorInterface({Key? key, required this.doctorProfile})
    : super(key: key);

  @override
  ConsumerState<DoctorInterface> createState() => _DoctorInterfaceState();
}

class _DoctorInterfaceState extends ConsumerState<DoctorInterface> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(doctorViewModelProvider.notifier);
      vm.setDoctorId(int.tryParse(widget.doctorProfile.id) ?? 0);
      vm.loadAll();
    });
  }

  // ── Scaffold ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bgPage,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      ),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _buildPage(),
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(gradient: _T.gNavy),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 10, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DoctorProfilePage(doctorProfile: widget.doctorProfile),
                  ),
                ),
                child: Row(
                  children: [
                    DoctorAvatar(name: widget.doctorProfile.fullName, size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${widget.doctorProfile.firstName} ${widget.doctorProfile.lastName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.doctorProfile.specialization?.isNotEmpty ==
                                  true
                              ? widget.doctorProfile.specialization!
                              : widget.doctorProfile.clinicName?.isNotEmpty ==
                                    true
                              ? widget.doctorProfile.clinicName!
                              : 'General Practitioner',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('EEE, dd MMM').format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                color: Colors.white.withOpacity(0.75),
                tooltip: 'Sign Out',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _T.bgCard,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D6B).withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final sel = i == _selectedIndex;
              final item = _navItems[i];
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = i),
                  splashColor: _T.navy.withOpacity(0.08),
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? _T.navy.withOpacity(0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          color: sel ? _T.navy : _T.textM,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? _T.navy : _T.textM,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Page router ───────────────────────────────────────────────────────────

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return DoctorDashboardPage(
          doctorProfile: widget.doctorProfile,
          onNav: (i) => setState(() => _selectedIndex = i),
        );
      case 1:
        return DoctorAppointmentsPage(
          doctorProfile: widget.doctorProfile,
          onStartConsultation: _openConsultation,
        );
      case 2:
        return DoctorPatientsPage(doctorProfile: widget.doctorProfile);
      case 3:
        return const DoctorFinancePage();
      default:
        return const SizedBox.shrink();
    }
  }

  void _openConsultation(Map<String, dynamic> appt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorConsultationPage(
          appointment: appt,
          doctorProfile: widget.doctorProfile,
        ),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(doctorViewModelProvider.notifier).logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.urgent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
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
}
