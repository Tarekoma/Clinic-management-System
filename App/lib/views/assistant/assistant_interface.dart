// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_interface.dart
//
// CHANGES IN THIS VERSION:
//   1. This is now the Assistant module's theme root: build() wraps the
//      entire Scaffold in Theme(data: AppThemes.assistantLight/assistantDark)
//      driven by the global themeModeProvider. Every Assistant screen pushed
//      below this widget (Dashboard, Appointments, Patients, Payments) now
//      renders with the dedicated Assistant theme instead of sharing
//      AppThemes.light/dark with the Doctor module.
//   2. All hardcoded strings (Sign Out, Cancel, Profile, Appointments,
//      Patients, Payments, Assistant badge, tooltips) replaced with
//      AppLocalizations — same architecture as the Doctor module. Nav labels
//      are now built per-build from `loc` instead of a static const list, so
//      they rebuild instantly when localeProvider changes.
//   3. The Sign Out confirmation dialog explicitly re-wraps itself with the
//      captured Theme.of(context) — showDialog/showModalBottomSheet insert
//      their content into the Navigator's Overlay, which sits outside the
//      Theme() wrap added in (1), so without re-wrapping, dialogs would fall
//      back to the global app theme instead of the Assistant theme.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/theme_providers.dart';
import 'package:Hakim/utils/app_themes.dart';
import 'package:Hakim/views/auths/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/services/settings_service.dart';
import 'package:Hakim/viewmodels/assistant_viewmodel.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/widgets/assistant/assistant_shared_widgets.dart';

import 'assistant_dashboard.dart';
import 'assistant_appointments_page.dart';
import 'assistant_edit_profile_page.dart';
import 'assistant_patients_page.dart';
import 'assistant_payments_page.dart';
import 'assistant_settings_page.dart';

typedef _T = AssistantTheme;

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class AssistantInterface extends ConsumerStatefulWidget {
  final UserProfile assistantProfile;
  final int initialTabIndex;
  const AssistantInterface({
    Key? key,
    required this.assistantProfile,
    this.initialTabIndex = 1,
  }) : super(key: key);

  @override
  ConsumerState<AssistantInterface> createState() => _AssistantInterfaceState();
}

class _AssistantInterfaceState extends ConsumerState<AssistantInterface> {
  late int _selectedIndex;
  late UserProfile _profile;

  void _selectTab(int i) {
    setState(() => _selectedIndex = i);
    SettingsService.setLastTab('assistant', i);
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _profile = widget.assistantProfile;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assistantViewModelProvider.notifier)
          .initForAssistant(_profile);
    });
  }

  Future<void> _openEditProfile() async {
    final assistantTheme = Theme.of(context);
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => Theme(
          data: assistantTheme,
          child: AssistantEditProfilePage(profile: _profile),
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  void _confirmLogout() {
    final loc = AppLocalizations.of(context)!;
    final assistantTheme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: assistantTheme,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
              child: Text(loc.signOut),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(AssistantState state, AppLocalizations loc) => Container(
    decoration: const BoxDecoration(gradient: _T.gGreen),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 10, 12),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTab(0),
                child: Row(
                  children: [
                    AssistantAvatar(
                      name: _profile.fullName,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile.fullName,
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
                          child: Text(
                            loc.assistantRoleLabel,
                            style: const TextStyle(
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
            _buildDoctorSwitch(state.doctors, state.activeDoctor, loc),
            IconButton(
              onPressed: () =>
                  showAssistantSettings(context, _profile),
              icon: const Icon(Icons.settings_rounded, size: 20),
              color: Colors.white.withOpacity(0.85),
              tooltip: loc.settingsTitle,
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
    AppLocalizations loc,
  ) {
    if (doctors.isEmpty) return const SizedBox.shrink();

    final fn = (activeDoctor?['first_name'] ?? '').toString().trim();
    final activeName = fn.isNotEmpty ? loc.drPrefix(fn) : loc.doctorRole;

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
      tooltip: loc.switchDoctor,
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
                color: isActive
                    ? _T.green
                    : Theme.of(context).extension<AssistantThemeData>()!.textM,
              ),
              const SizedBox(width: 8),
              Text(
                loc.drPrefix('$dfn $dln'.trim()),
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

  Widget _buildBottomNav(List<_NavItem> navItems) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).extension<AssistantThemeData>()!.bgCard,
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
          children: List.generate(navItems.length, (i) {
            final sel = i == _selectedIndex;
            final item = navItems[i];
            return Expanded(
              child: InkWell(
                onTap: () => _selectTab(i),
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
                        color: sel
                            ? _T.green
                            : Theme.of(
                                context,
                              ).extension<AssistantThemeData>()!.textM,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel
                            ? _T.green
                            : Theme.of(
                                context,
                              ).extension<AssistantThemeData>()!.textM,
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
          profile: _profile,
          onRefresh: () => vm.loadAll(),
          onEdit: _openEditProfile,
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
    final loc = AppLocalizations.of(context)!;

    // ── Dedicated Assistant theme, driven by the SAME global themeModeProvider
    // used by the Doctor module — so dark mode toggled anywhere in the app
    // still flips this module too, but with Assistant's own teal/cyan slate
    // theme instead of Doctor's navy/blue AppThemes.light/dark.
    final themeMode = ref.watch(themeModeProvider);
    final assistantTheme = themeMode == ThemeMode.dark
        ? AppThemes.assistantDark
        : AppThemes.assistantLight;

    final navItems = [
      _NavItem(Icons.person_rounded, loc.profile),
      _NavItem(Icons.calendar_month_rounded, loc.appointments),
      _NavItem(Icons.people_alt_rounded, loc.patients),
      _NavItem(Icons.account_balance_wallet_rounded, loc.payments),
    ];

    return Theme(
      data: assistantTheme,
      child: Scaffold(
        backgroundColor: Theme.of(
          context,
        ).extension<AssistantThemeData>()!.bgPage,
        body: Column(
          children: [
            _buildTopBar(state, loc),
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
            _buildBottomNav(navItems),
          ],
        ),
      ),
    );
  }
}
