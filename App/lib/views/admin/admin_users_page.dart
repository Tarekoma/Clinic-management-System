// lib/views/admin/admin_users_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/admin_providers.dart';
import 'package:Hakim/utils/admin_theme.dart';
import 'package:Hakim/viewmodels/admin_viewmodel.dart';
import 'package:intl/intl.dart';

typedef _T = AdminTheme;

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  static const _tabs = ['All', 'Doctors', 'Assistants', 'Admins'];
  static const _roleFilters = ['', 'doctor', 'assistant', 'admin'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        final role = _roleFilters[_tabCtrl.index];
        ref.read(adminViewModelProvider.notifier).setRoleFilter(
              role.isEmpty ? null : role,
            );
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminViewModelProvider);
    final at = Theme.of(context).extension<AdminThemeData>()!;
    final vm = ref.read(adminViewModelProvider.notifier);

    return Column(
      children: [
        _buildHeader(context, at, vm, state),
        _buildTabBar(at),
        Expanded(child: _buildBody(context, at, state, vm)),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminThemeData at,
    AdminViewModel vm,
    AdminState state,
  ) {
    return Container(
      color: at.bgCard,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(fontSize: 14, color: at.textH),
                  decoration: AdminTheme.inpOf(
                    context,
                    'Search users…',
                    pre: Icon(Icons.search_rounded, size: 18, color: at.textM),
                    suf: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, size: 18, color: at.textM),
                            onPressed: () {
                              _searchCtrl.clear();
                              vm.setSearch('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) {
                    vm.setSearch(v);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              _RefreshButton(onPressed: vm.loadUsers),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Status:', style: TextStyle(fontSize: 12, color: at.textS)),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'All',
                  selected: state.statusFilter == null,
                  onTap: () => vm.setStatusFilter(null),
                  at: at,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Active',
                  selected: state.statusFilter == 'active',
                  onTap: () => vm.setStatusFilter('active'),
                  at: at,
                  color: _T.active,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Inactive',
                  selected: state.statusFilter == 'inactive',
                  onTap: () => vm.setStatusFilter('inactive'),
                  at: at,
                  color: _T.inactive,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTabBar(AdminThemeData at) {
    return Container(
      color: at.bgCard,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: _T.indigo,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: _T.indigo,
        unselectedLabelColor: at.textM,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminThemeData at,
    AdminState state,
    AdminViewModel vm,
  ) {
    if (state.isLoadingUsers) {
      return _buildSkeleton(at);
    }

    if (state.usersError != null) {
      return _buildError(context, at, state.usersError!, vm);
    }

    final users = state.filteredUsers;

    if (users.isEmpty) {
      return _buildEmpty(at, state);
    }

    return RefreshIndicator(
      color: _T.indigo,
      onRefresh: () => vm.loadUsers(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return _buildResultsHeader(at, users.length);
          }
          return _buildUserCard(context, at, users[i - 1], vm);
        },
      ),
    );
  }

  Widget _buildResultsHeader(AdminThemeData at, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$count ${count == 1 ? 'user' : 'users'} found',
        style: TextStyle(fontSize: 12, color: at.textM, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    AdminThemeData at,
    AdminUser user,
    AdminViewModel vm,
  ) {
    final roleColor = _roleColor(user.role);
    final joined = DateFormat('d MMM yyyy').format(user.createdAt);
    final displayName = user.fullName.isEmpty ? user.email : user.fullName;

    return Container(
      decoration: _T.cardOf(context, r: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          splashColor: _T.indigo.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserAvatar(name: displayName, role: user.role),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: at.textH,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusBadge(isActive: user.isActive),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 12, color: at.textS),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _RoleBadge(role: user.role, color: roleColor),
                          if (user.clinicName != null && user.clinicName!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.local_hospital_rounded,
                                      size: 11, color: at.textM),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      user.clinicName!,
                                      style: TextStyle(fontSize: 11, color: at.textM),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 11, color: at.textM),
                          const SizedBox(width: 4),
                          Text(
                            'Joined $joined',
                            style: TextStyle(fontSize: 11, color: at.textM),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ToggleButton(
                  isActive: user.isActive,
                  onTap: () => _confirmToggle(context, at, user, vm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmToggle(
    BuildContext context,
    AdminThemeData at,
    AdminUser user,
    AdminViewModel vm,
  ) {
    final adminTheme = Theme.of(context);
    final action = user.isActive ? 'Deactivate' : 'Activate';
    final actionColor = user.isActive ? _T.urgent : _T.success;
    final displayName = user.fullName.isEmpty ? user.email : user.fullName;

    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: adminTheme,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  user.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                  color: actionColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text('$action Account'),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(ctx).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Are you sure you want to $action the account for '),
                TextSpan(
                  text: displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final ok = await vm.toggleUserStatus(user);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Account ${action.toLowerCase()}d successfully.'
                          : 'Failed to $action account. Please try again.',
                    ),
                    backgroundColor: ok ? _T.success : _T.urgent,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(AdminThemeData at) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _SkeletonUserCard(at: at),
    );
  }

  Widget _buildError(
    BuildContext context,
    AdminThemeData at,
    String error,
    AdminViewModel vm,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _T.urgentBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: _T.urgent, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load users',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: at.textH,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: at.textS, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: vm.loadUsers,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AdminThemeData at, AdminState state) {
    final isFiltered = state.searchQuery.isNotEmpty ||
        state.roleFilter != null ||
        state.statusFilter != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: at.divider.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFiltered ? Icons.search_off_rounded : Icons.people_outline_rounded,
              color: at.textM,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No results found' : 'No users yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: at.textH,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Try adjusting your search or filters.'
                : 'Users will appear here once added.',
            style: TextStyle(fontSize: 13, color: at.textM),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return _T.indigo;
      case 'assistant':
        return const Color(0xFF00695C);
      case 'admin':
        return _T.purple;
      default:
        return _T.muted;
    }
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _RefreshButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _RefreshButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.refresh_rounded, size: 20),
        color: AdminTheme.indigo,
        tooltip: 'Refresh',
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final String role;
  const _UserAvatar({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final bg = AdminTheme.avatarBg(name);
    final initials = _initials(name);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [bg, bg.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ToggleButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _ToggleButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AdminTheme.urgent : AdminTheme.success;
    final bg = isActive ? AdminTheme.urgentBg : AdminTheme.successBg;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          isActive ? 'Deactivate' : 'Activate',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AdminThemeData at;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.at,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminTheme.indigo;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : at.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? c : at.textS,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AdminTheme.activeBg : AdminTheme.inactiveBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AdminTheme.active : AdminTheme.inactive,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? AdminTheme.active : AdminTheme.inactive,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final Color color;
  const _RoleBadge({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1).toLowerCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SkeletonUserCard extends StatefulWidget {
  final AdminThemeData at;
  // ignore: prefer_const_constructors_in_immutables
  _SkeletonUserCard({required this.at});

  @override
  State<_SkeletonUserCard> createState() => _SkeletonUserCardState();
}

class _SkeletonUserCardState extends State<_SkeletonUserCard>
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
    final at = widget.at;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.75).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: at.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: at.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(shape: BoxShape.circle, color: at.divider),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: at.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 11,
                    width: 200,
                    decoration: BoxDecoration(
                      color: at.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        height: 20,
                        width: 60,
                        decoration: BoxDecoration(
                          color: at.divider,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 28,
              width: 72,
              decoration: BoxDecoration(
                color: at.divider,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
