// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_interface.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/views/auths/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pass the full UserProfile so ViewModel can use email + clinicName.
      ref
          .read(assistantViewModelProvider.notifier)
          .initForAssistant(widget.assistantProfile);
    });
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

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
              ),
            ),
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

  // ── Doctor switch ──────────────────────────────────────────────────────────
  //
  // state.doctors is already filtered to this assistant's clinic.
  // Single-doctor clinics show a plain label (no dropdown needed).

  Widget _buildDoctorSwitch(
    List<Map<String, dynamic>> doctors,
    Map<String, dynamic>? activeDoctor,
  ) {
    if (doctors.isEmpty) return const SizedBox.shrink();

    final fn = (activeDoctor?['first_name'] ?? '').toString().trim();
    final activeName = fn.isNotEmpty ? 'Dr. $fn' : 'Doctor';

    // Single doctor — plain label, no dropdown arrow.
    if (doctors.length == 1) {
      return Container(
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
              activeName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Multiple doctors — show dropdown.
    return PopupMenuButton<Map<String, dynamic>>(
      onSelected: (doc) =>
          ref.read(assistantViewModelProvider.notifier).setActiveDoctor(doc),
      tooltip: 'Switch doctor',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      itemBuilder: (_) => doctors.map((d) {
        final dfn = (d['first_name'] ?? '').toString().trim();
        final dln = (d['last_name'] ?? '').toString().trim();
        final isActive = activeDoctor?['id']?.toString() == d['id']?.toString();
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
                'Dr. $dfn $dln'.trim(),
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
              activeName,
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
          // FIX: use loadAll() for pull-to-refresh.
          // initForAssistant() re-runs the full multi-step doctor discovery
          // chain (getDoctors + appointment probes) on every refresh.  By this
          // point the doctor is already resolved; we only need to refresh the
          // data, not re-discover the doctor.  The re-entrancy guard in
          // AssistantViewModel would catch this anyway, but calling loadAll()
          // directly is semantically correct and avoids the guard overhead.
          onRefresh: () => vm.loadAll(),
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

  // ── Build ──────────────────────────────────────────────────────────────────

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
