// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_interface.dart
//
// Shell widget: top bar, animated bottom nav, page router.
// Navigation index is the only local state — everything else comes from
// the ViewModel via Riverpod.
//
// CHANGES IN THIS VERSION:
//   • Top bar time/date now uses DateFormat(..., localeCode) + arDigits()
//     so it renders "م ٠٣:٠٠ / السبت، ٢٠ يونيو" in Arabic instead of
//     "PM 03:00 / Sat, 20 Jun" regardless of app language.
//   • 'Dr. {firstName} {lastName}' replaced with loc.drPrefix(fullName).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/views/auths/login_page.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_consultation_page.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/services/settings_service.dart';
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

List<_NavItem> _buildNavItems(AppLocalizations loc) => [
  _NavItem(Icons.dashboard_rounded, loc.dashboard),
  _NavItem(Icons.calendar_month_rounded, loc.appointments),
  _NavItem(Icons.people_alt_rounded, loc.patients),
  _NavItem(Icons.account_balance_wallet_rounded, loc.finance),
];

// ── DoctorInterface ───────────────────────────────────────────────────────────

class DoctorInterface extends ConsumerStatefulWidget {
  final UserProfile doctorProfile;
  final int initialTabIndex;
  const DoctorInterface({
    Key? key,
    required this.doctorProfile,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  ConsumerState<DoctorInterface> createState() => _DoctorInterfaceState();
}

class _DoctorInterfaceState extends ConsumerState<DoctorInterface> {
  late DoctorThemeData _dt; // injected in build()
  late int _selectedIndex;

  void _selectTab(int i) {
    setState(() => _selectedIndex = i);
    SettingsService.setLastTab('doctor', i); // fire-and-forget
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
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
    _dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _dt.bgPage,
      body: Column(
        children: [
          _buildTopBar(loc),
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
          _buildBottomNav(loc),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(AppLocalizations loc) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    // FIXED: was DateFormat('hh:mm a').format(now) / DateFormat('EEE, dd MMM')
    // with no locale arg — always rendered English text + Western digits
    // regardless of the app's selected language.
    final timeStr = arDigits(
      DateFormat('hh:mm a', localeCode).format(now),
      localeCode,
    );
    final dateStr = arDigits(
      DateFormat('EEE, dd MMM', localeCode).format(now),
      localeCode,
    );

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
                          // FIXED: was hardcoded
                          // 'Dr. ${firstName} ${lastName}'
                          loc.drPrefix(
                            '${widget.doctorProfile.firstName} ${widget.doctorProfile.lastName}',
                          ),
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
                              : loc.generalPractitioner,
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
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () =>
                    showDoctorSettings(context, widget.doctorProfile),
                icon: const Icon(Icons.settings_rounded, size: 20),
                color: Colors.white.withOpacity(0.85),
                tooltip: loc.settingsTitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav(AppLocalizations loc) {
    final navItems = _buildNavItems(loc);
    return Container(
      decoration: BoxDecoration(
        color: _dt.bgCard,
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
            children: List.generate(navItems.length, (i) {
              final sel = i == _selectedIndex;
              final item = navItems[i];
              return Expanded(
                child: InkWell(
                  onTap: () => _selectTab(i),
                  splashColor: _dt.accent.withOpacity(0.12),
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
                              ? _dt.accent.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          color: sel ? _dt.accent : _dt.textM,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? _dt.accent : _dt.textM,
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
          onNav: _selectTab,
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
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.signOutConfirmTitle),
        content: Text(loc.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
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
            child: Text(loc.signOut),
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
