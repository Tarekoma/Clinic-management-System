// lib/views/admin/admin_interface.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/admin_providers.dart';
import 'package:Hakim/providers/theme_providers.dart';
import 'package:Hakim/utils/admin_theme.dart';
import 'package:Hakim/utils/app_themes.dart';
import 'package:Hakim/views/admin/admin_dashboard.dart';
import 'package:Hakim/views/admin/admin_users_page.dart';
import 'package:Hakim/views/admin/admin_audit_logs_page.dart';
import 'package:Hakim/views/admin/admin_patients_page.dart';
import 'package:Hakim/views/admin/admin_settings_page.dart';
import 'package:Hakim/views/auths/login_page.dart';

typedef _T = AdminTheme;

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class AdminInterface extends ConsumerStatefulWidget {
  final UserProfile adminProfile;
  const AdminInterface({Key? key, required this.adminProfile}) : super(key: key);

  @override
  ConsumerState<AdminInterface> createState() => _AdminInterfaceState();
}

class _AdminInterfaceState extends ConsumerState<AdminInterface> {
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
      final vm = ref.read(adminViewModelProvider.notifier);
      vm.loadDashboard();
      vm.loadUsers();
    });
  }

  void _confirmLogout() {
    final adminTheme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: adminTheme,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out of the admin panel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(adminViewModelProvider.notifier).logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.urgent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext ctx, AdminThemeData at) {
    final name = widget.adminProfile.fullName;
    final initials = _initials(name);
    return Container(
      decoration: const BoxDecoration(gradient: _T.gHeader),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name.isEmpty ? 'Administrator' : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ADMINISTRATOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => showAdminSettings(ctx, widget.adminProfile),
                icon: const Icon(Icons.settings_outlined, size: 22),
                color: Colors.white.withValues(alpha: 0.85),
                tooltip: 'Settings',
              ),
              IconButton(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 22),
                color: Colors.white.withValues(alpha: 0.85),
                tooltip: 'Sign Out',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(AdminThemeData at, List<_NavItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: at.bgCard,
        boxShadow: [
          BoxShadow(
            color: _T.indigoDeep.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = i == _selectedIndex;
              final item = items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = i),
                  splashColor: _T.indigo.withValues(alpha: 0.08),
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: sel
                              ? _T.indigo.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          sel ? item.activeIcon : item.icon,
                          color: sel ? _T.indigo : at.textM,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? _T.indigo : at.textM,
                        ),
                        child: Text(item.label),
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

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return AdminDashboard(adminProfile: widget.adminProfile);
      case 1:
        return const AdminUsersPage();
      case 2:
        return const AdminPatientsPage();
      case 3:
        return const AdminAuditLogsPage();
      default:
        return AdminDashboard(adminProfile: widget.adminProfile);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final adminTheme = themeMode == ThemeMode.dark
        ? AppThemes.adminDark
        : AppThemes.adminLight;

    const navItems = [
      _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
      _NavItem(Icons.manage_accounts_outlined, Icons.manage_accounts_rounded, 'Users'),
      _NavItem(Icons.person_remove_outlined, Icons.person_remove_rounded, 'Patients'),
      _NavItem(Icons.history_outlined, Icons.history_rounded, 'Audit'),
    ];

    return Theme(
      data: adminTheme,
      child: Builder(
        builder: (ctx) {
          final at = Theme.of(ctx).extension<AdminThemeData>()!;
          return Scaffold(
            backgroundColor: at.bgPage,
            body: Column(
              children: [
                _buildTopBar(ctx, at),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.025),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: _buildPage(),
                    ),
                  ),
                ),
                _buildBottomNav(at, navItems),
              ],
            ),
          );
        },
      ),
    );
  }
}
