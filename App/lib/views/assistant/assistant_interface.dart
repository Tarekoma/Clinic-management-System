// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_interface.dart
//
// Entry point for the assistant side of the app.
// Preserves the original constructor signature so Login_Page.dart needs
// zero changes:
//
//   Navigator.of(context).pushReplacement(MaterialPageRoute(
//     builder: (_) => AssistantInterface(assistantProfile: userProfile),
//   ));
//
// Architecture changes only — visual output identical:
//   • ConsumerStatefulWidget (was StatefulWidget)
//   • Tab pages are now separate view files
//   • Logout calls ApiService via ViewModel-style (no direct call in widget)
//   • ProviderScope is already above this via main.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/views/auths/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/viewmodels/assistant_viewmodel.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/widgets/assistant/assistant_shared_widgets.dart';

import 'assistant_dashboard.dart';
import 'assistant_appointments_page.dart';
import 'assistant_patients_page.dart';
import 'assistant_payments_page.dart';

typedef _T = AssistantTheme;

// ── Nav item data class ───────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ══════════════════════════════════════════════════════════════════════════════
// SHELL
// ══════════════════════════════════════════════════════════════════════════════

class AssistantInterface extends ConsumerStatefulWidget {
  final UserProfile assistantProfile;

  const AssistantInterface({Key? key, required this.assistantProfile})
    : super(key: key);

  @override
  ConsumerState<AssistantInterface> createState() => _AssistantInterfaceState();
}

class _AssistantInterfaceState extends ConsumerState<AssistantInterface> {
  int _selectedIndex = 1;

  static const _navItems = [
    _NavItem(Icons.person_rounded, 'Profile'),
    _NavItem(Icons.calendar_month_rounded, 'Appointments'),
    _NavItem(Icons.people_alt_rounded, 'Patients'),
    _NavItem(Icons.account_balance_wallet_rounded, 'Payments'),
  ];

  // ── Init ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    // Initial data load (ViewModel already calls loadAll() in constructor,
    // but an explicit call here allows pull-to-refresh to work from the shell).
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? _T.urgent : _T.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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
              await ref.read(assistantViewModelProvider.notifier).logout();
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

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(AssistantState state) => Container(
    decoration: const BoxDecoration(gradient: _T.gGreen),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 10, 12),
        child: Row(
          children: [
            // ── CHANGED: tap avatar+name to open Profile tab ─────────────
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 0),
                child: Row(
                  children: [
                    AssistantAvatar(
                      name: widget.assistantProfile.fullName,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.assistantProfile.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Assistant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ), // closes Expanded
            // ── End of tappable area ─────────────────────────────────────

            // ── Right side: doctor switch only ────────────────────────────
            _buildDoctorSwitch(state.doctors, state.activeDoctor),
            IconButton(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              color: Colors.white.withOpacity(0.75),
            ),
          ],
        ),
      ),
    ),
  );
  // ── Doctor switch widget ───────────────────────────────────────────────────

  Widget _buildDoctorSwitch(
    List<Map<String, dynamic>> doctors,
    Map<String, dynamic>? activeDoctor,
  ) {
    // Hide if there are no doctors loaded yet
    if (doctors.isEmpty) return const SizedBox.shrink();

    final firstName = (activeDoctor?['first_name'] ?? '').toString().trim();
    final label = firstName.isNotEmpty ? 'Dr. $firstName' : 'Select Doctor';

    return PopupMenuButton<Map<String, dynamic>>(
      onSelected: (doctor) =>
          ref.read(assistantViewModelProvider.notifier).setActiveDoctor(doctor),
      tooltip: 'Switch doctor',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      itemBuilder: (_) => doctors.map((d) {
        final fn = (d['first_name'] ?? '').toString().trim();
        final ln = (d['last_name'] ?? '').toString().trim();
        final fullName = 'Dr. $fn $ln'.trim();
        final isActive = activeDoctor?['id'] == d['id'];
        return PopupMenuItem<Map<String, dynamic>>(
          value: d,
          child: Row(
            children: [
              Icon(
                isActive
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: isActive ? _T.green : _T.textM,
              ),
              const SizedBox(width: 8),
              Text(
                fullName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? _T.green : const Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      // ── Button appearance ──────────────────────────────────────────────
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.medical_services_rounded,
              size: 15,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────

  Widget _buildBottomNav() => Container(
    decoration: BoxDecoration(
      color: _T.bgCard,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF00695C).withOpacity(0.10),
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
                splashColor: _T.green.withOpacity(0.08),
                highlightColor: Colors.transparent,
                child: Column(
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
                            ? _T.green.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        color: sel ? _T.green : _T.textM,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? _T.green : _T.textM,
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

  // ── Page router ────────────────────────────────────────────────────────────

  Widget _buildPage() {
    final vm = ref.read(assistantViewModelProvider.notifier);
    switch (_selectedIndex) {
      case 0:
        return AssistantDashboard(
          profile: widget.assistantProfile,
          onRefresh: vm.loadAll,
        );
      case 1:
        return const AssistantAppointmentsPage();
      case 2:
        return const AssistantPatientsPage();
      case 3:
        return const AssistantPaymentsPage();
      default:
        return const AssistantAppointmentsPage();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantViewModelProvider);
    return Scaffold(
      backgroundColor: _T.bgPage,
      body: Column(
        children: [
          _buildTopBar(state),
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
}
