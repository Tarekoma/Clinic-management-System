// lib/views/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/admin_providers.dart';
import 'package:Hakim/utils/admin_theme.dart';
import 'package:Hakim/viewmodels/admin_viewmodel.dart';

typedef _T = AdminTheme;

class AdminDashboard extends ConsumerWidget {
  final UserProfile adminProfile;
  const AdminDashboard({super.key, required this.adminProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminViewModelProvider);
    final at = Theme.of(context).extension<AdminThemeData>()!;
    final vm = ref.read(adminViewModelProvider.notifier);

    return RefreshIndicator(
      color: _T.indigo,
      displacement: 20,
      onRefresh: () => vm.loadDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(context, at, state, onRetry: vm.loadDashboard),
                  if (state.stats != null && !state.isLoadingStats) ...[
                    const SizedBox(height: 20),
                    _buildUserDistribution(context, at, state.stats!),
                  ],
                  const SizedBox(height: 20),
                  _buildQuickActions(context, at),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Header ────────────────────────────────────────────────────────────

  Widget _buildHeroHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final name = adminProfile.fullName;
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: _T.gHeader),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name.isEmpty ? 'Administrator' : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      today,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SystemStatusBadge(),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white.withValues(alpha: 0.80), size: 16),
                const SizedBox(width: 8),
                Text(
                  'System Administration Panel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Section ──────────────────────────────────────────────────────────

  Widget _buildStatsSection(
    BuildContext context,
    AdminThemeData at,
    AdminState state, {
    required VoidCallback onRetry,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'System Overview', icon: Icons.grid_view_rounded),
        const SizedBox(height: 14),
        if (state.isLoadingStats)
          _buildLoadingGrid()
        else if (state.statsError != null)
          _buildErrorCard(context, at, state.statsError!, onRetry)
        else
          _buildStatsGrid(context, at, state.stats),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: List.generate(6, (_) => const _ShimmerStatCard()),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AdminThemeData at, AdminStats? stats) {
    final items = [
      _StatItem(
        label: 'Total Patients',
        value: stats?.totalPatients ?? 0,
        icon: Icons.personal_injury_rounded,
        gradient: _T.gBlue,
        subtitle: 'Registered patients',
      ),
      _StatItem(
        label: 'Total Doctors',
        value: stats?.totalDoctors ?? 0,
        icon: Icons.medical_services_rounded,
        gradient: _T.gIndigo,
        subtitle: 'Medical staff',
      ),
      _StatItem(
        label: 'Assistants',
        value: stats?.totalAssistants ?? 0,
        icon: Icons.support_agent_rounded,
        gradient: _T.gTeal,
        subtitle: 'Support staff',
      ),
      _StatItem(
        label: 'Admins',
        value: stats?.totalAdmins ?? 0,
        icon: Icons.admin_panel_settings_rounded,
        gradient: _T.gPurple,
        subtitle: 'Admin accounts',
      ),
      _StatItem(
        label: 'Active Users',
        value: stats?.activeUsers ?? 0,
        icon: Icons.check_circle_rounded,
        gradient: _T.gGreen,
        subtitle: 'Currently active',
      ),
      _StatItem(
        label: 'Inactive',
        value: stats?.inactiveUsers ?? 0,
        icon: Icons.cancel_rounded,
        gradient: _T.gSlate,
        subtitle: 'Deactivated',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: items.map((item) => _buildStatCard(item)).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: item.gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    AdminThemeData at,
    String error,
    VoidCallback onRetry,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _T.urgentBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.urgent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.urgent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, color: _T.urgent, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load statistics',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _T.urgent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: _T.urgent.withValues(alpha: 0.75), fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.urgent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── User Distribution ──────────────────────────────────────────────────────

  Widget _buildUserDistribution(BuildContext context, AdminThemeData at, AdminStats stats) {
    final totalUsers = stats.activeUsers + stats.inactiveUsers;
    final activeRatio = totalUsers == 0 ? 0.0 : stats.activeUsers / totalUsers;
    final totalStaff = stats.totalDoctors + stats.totalAssistants + stats.totalAdmins;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _T.cardOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _T.indigo.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_alt_rounded, color: _T.indigo, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'User Distribution',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: at.textH,
                  ),
                ),
              ),
              Text(
                '$totalStaff total staff',
                style: TextStyle(fontSize: 11, color: at.textM),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: activeRatio,
              backgroundColor: at.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(_T.active),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LegendDot(color: _T.active, label: '${stats.activeUsers} Active'),
              const SizedBox(width: 16),
              _LegendDot(color: _T.muted, label: '${stats.inactiveUsers} Inactive'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _T.active.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(activeRatio * 100).toStringAsFixed(0)}% active',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _T.active,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: at.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.medical_services_rounded,
                  color: _T.indigo,
                  label: 'Doctors',
                  value: stats.totalDoctors,
                ),
              ),
              Container(width: 1, height: 32, color: at.divider),
              Expanded(
                child: _MiniStat(
                  icon: Icons.support_agent_rounded,
                  color: const Color(0xFF00695C),
                  label: 'Assistants',
                  value: stats.totalAssistants,
                ),
              ),
              Container(width: 1, height: 32, color: at.divider),
              Expanded(
                child: _MiniStat(
                  icon: Icons.admin_panel_settings_rounded,
                  color: _T.purple,
                  label: 'Admins',
                  value: stats.totalAdmins,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, AdminThemeData at) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Quick Actions', icon: Icons.bolt_rounded),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                at,
                icon: Icons.manage_accounts_rounded,
                label: 'Manage Users',
                subtitle: 'Activate or deactivate accounts',
                color: _T.indigo,
                gradient: _T.gIndigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                at,
                icon: Icons.history_rounded,
                label: 'Audit Logs',
                subtitle: 'Review system activity',
                color: _T.purple,
                gradient: _T.gPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    AdminThemeData at, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: at.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: at.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: at.textH,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: at.textM, height: 1.3),
          ),
        ],
      ),
    );
  }
}

// ── Supporting types ───────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final String subtitle;
  final int value;
  final IconData icon;
  final Gradient gradient;
  const _StatItem({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _SystemStatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF66BB6A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Online',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AdminThemeData>()!;
    return Row(
      children: [
        Icon(icon, color: _T.indigo, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: at.textH,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AdminThemeData>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: at.textS, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AdminThemeData>()!;
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 5),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: at.textH,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: at.textM)),
      ],
    );
  }
}

class _ShimmerStatCard extends StatefulWidget {
  const _ShimmerStatCard();

  @override
  State<_ShimmerStatCard> createState() => _ShimmerStatCardState();
}

class _ShimmerStatCardState extends State<_ShimmerStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AdminThemeData>()!;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.75).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: at.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: at.divider),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: at.divider,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 24,
                  decoration: BoxDecoration(
                    color: at.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 84,
                  height: 11,
                  decoration: BoxDecoration(
                    color: at.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
