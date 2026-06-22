// lib/views/admin/admin_audit_logs_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/admin_providers.dart';
import 'package:Hakim/utils/admin_theme.dart';
import 'package:Hakim/viewmodels/admin_viewmodel.dart';
import 'package:intl/intl.dart';

typedef _T = AdminTheme;

class AdminAuditLogsPage extends ConsumerStatefulWidget {
  const AdminAuditLogsPage({super.key});

  @override
  ConsumerState<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends ConsumerState<AdminAuditLogsPage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminViewModelProvider.notifier).loadAuditLogs(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(adminViewModelProvider.notifier).loadAuditLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminViewModelProvider);
    final at = Theme.of(context).extension<AdminThemeData>()!;
    final vm = ref.read(adminViewModelProvider.notifier);

    return Column(
      children: [
        _buildFilterBar(context, at, state, vm),
        Expanded(child: _buildBody(context, at, state, vm)),
      ],
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────

  Widget _buildFilterBar(
    BuildContext context,
    AdminThemeData at,
    AdminState state,
    AdminViewModel vm,
  ) {
    final hasFilters = state.logsActionFilter != null || state.logsStartDate != null;
    return Container(
      decoration: BoxDecoration(
        color: at.bgCard,
        border: Border(bottom: BorderSide(color: at.divider, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: _T.indigo, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Audit Logs',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: at.textH,
                      ),
                    ),
                    if (state.auditLogs.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _T.indigo.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.auditLogs.length}${state.logsHasMore ? '+' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _T.indigo,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => vm.loadAuditLogs(refresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: _T.indigo,
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: () => _showFilterSheet(context, at, state, vm),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.tune_rounded, size: 20),
                    if (hasFilters)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _T.indigo,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                color: hasFilters ? _T.indigo : at.textM,
                tooltip: 'Filters',
              ),
            ],
          ),
          if (hasFilters) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (state.logsActionFilter != null)
                    _ActiveFilterChip(
                      label: 'Action: ${state.logsActionFilter}',
                      onRemove: () => vm.setLogsActionFilter(null),
                    ),
                  if (state.logsStartDate != null) ...[
                    const SizedBox(width: 6),
                    _ActiveFilterChip(
                      label:
                          'From ${state.logsStartDate} → ${state.logsEndDate ?? 'now'}',
                      onRemove: () => vm.setLogsDateRange(null, null),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Filter Sheet ───────────────────────────────────────────────────────────

  void _showFilterSheet(
    BuildContext context,
    AdminThemeData at,
    AdminState state,
    AdminViewModel vm,
  ) {
    final adminTheme = Theme.of(context);
    String? tempAction = state.logsActionFilter;
    DateTime? tempStart =
        state.logsStartDate != null ? DateTime.tryParse(state.logsStartDate!) : null;
    DateTime? tempEnd =
        state.logsEndDate != null ? DateTime.tryParse(state.logsEndDate!) : null;

    const commonActions = [
      'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT',
      'ACTIVATE', 'DEACTIVATE', 'VIEW',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: at.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Theme(
        data: adminTheme,
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: at.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Logs',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: at.textH,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setSheet(() {
                        tempAction = null;
                        tempStart = null;
                        tempEnd = null;
                      }),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'ACTION TYPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: at.textM,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: commonActions.map((a) {
                    final sel = tempAction == a;
                    final color = _actionColor(a);
                    return GestureDetector(
                      onTap: () =>
                          setSheet(() => tempAction = sel ? null : a),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? color : at.divider,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          a,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? color : at.textS,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'DATE RANGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: at.textM,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerButton(
                        label: tempStart != null
                            ? DateFormat('dd MMM yyyy').format(tempStart!)
                            : 'From date',
                        at: at,
                        hasValue: tempStart != null,
                        onTap: () async {
                          final p = await showDatePicker(
                            context: ctx,
                            initialDate: tempStart ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (p != null) setSheet(() => tempStart = p);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DatePickerButton(
                        label: tempEnd != null
                            ? DateFormat('dd MMM yyyy').format(tempEnd!)
                            : 'To date',
                        at: at,
                        hasValue: tempEnd != null,
                        onTap: () async {
                          final p = await showDatePicker(
                            context: ctx,
                            initialDate: tempEnd ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (p != null) setSheet(() => tempEnd = p);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      vm.setLogsActionFilter(tempAction);
                      vm.setLogsDateRange(
                        tempStart != null
                            ? DateFormat('yyyy-MM-dd').format(tempStart!)
                            : null,
                        tempEnd != null
                            ? DateFormat('yyyy-MM-dd').format(tempEnd!)
                            : null,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    AdminThemeData at,
    AdminState state,
    AdminViewModel vm,
  ) {
    if (state.isLoadingLogs && state.auditLogs.isEmpty) {
      return _buildSkeleton(at);
    }

    if (state.logsError != null && state.auditLogs.isEmpty) {
      return _buildError(at, state.logsError!, vm);
    }

    if (state.auditLogs.isEmpty) {
      return _buildEmpty(at);
    }

    return RefreshIndicator(
      color: _T.indigo,
      onRefresh: () => vm.loadAuditLogs(refresh: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: state.auditLogs.length + (state.logsHasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == state.auditLogs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: _T.indigo, strokeWidth: 2),
              ),
            );
          }
          return _buildLogCard(at, state.auditLogs[i]);
        },
      ),
    );
  }

  Widget _buildLogCard(AdminThemeData at, AuditLog log) {
    final ts = DateFormat('dd MMM yyyy  HH:mm').format(log.timestamp.toLocal());
    final actionColor = _actionColor(log.action);
    final icon = _actionIcon(log.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: at.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: at.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: _T.indigoDeep.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: actionColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.action.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: actionColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        ts,
                        style: TextStyle(fontSize: 10.5, color: at.textM),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    log.userEmail,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: at.textH,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (log.description != null && log.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      log.description!,
                      style: TextStyle(fontSize: 12, color: at.textS, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (log.resourceType != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: at.divider.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.label_outline_rounded,
                              size: 11, color: at.textM),
                          const SizedBox(width: 4),
                          Text(
                            '${log.resourceType}${log.resourceId != null ? ' #${log.resourceId}' : ''}',
                            style: TextStyle(fontSize: 10, color: at.textM),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(AdminThemeData at) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 8,
      itemBuilder: (_, __) => _SkeletonLogCard(at: at),
    );
  }

  Widget _buildError(AdminThemeData at, String error, AdminViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _T.urgentBg, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  color: _T.urgent, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load audit logs',
              style: TextStyle(
                fontSize: 15,
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
              onPressed: () => vm.loadAuditLogs(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AdminThemeData at) {
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
            child: Icon(Icons.history_rounded, color: at.textM, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'No audit logs found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: at.textH,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No activity matches the current filters.',
            style: TextStyle(fontSize: 13, color: at.textM),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return _T.success;
      case 'DELETE':
        return _T.urgent;
      case 'UPDATE':
        return _T.warning;
      case 'LOGIN':
      case 'VIEW':
        return _T.info;
      case 'LOGOUT':
        return _T.muted;
      case 'ACTIVATE':
        return _T.active;
      case 'DEACTIVATE':
        return _T.inactive;
      default:
        return _T.indigo;
    }
  }

  IconData _actionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Icons.add_circle_outline_rounded;
      case 'DELETE':
        return Icons.delete_outline_rounded;
      case 'UPDATE':
        return Icons.edit_outlined;
      case 'LOGIN':
        return Icons.login_rounded;
      case 'LOGOUT':
        return Icons.logout_rounded;
      case 'ACTIVATE':
        return Icons.check_circle_outline_rounded;
      case 'DEACTIVATE':
        return Icons.cancel_outlined;
      case 'VIEW':
        return Icons.visibility_outlined;
      default:
        return Icons.history_rounded;
    }
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AdminTheme.indigo.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminTheme.indigo.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AdminTheme.indigo,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AdminTheme.indigo.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 10, color: AdminTheme.indigo),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final AdminThemeData at;
  final bool hasValue;
  final VoidCallback onTap;

  const _DatePickerButton({
    required this.label,
    required this.at,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? AdminTheme.indigo.withValues(alpha: 0.08)
              : at.bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AdminTheme.indigo : at.divider,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: hasValue ? AdminTheme.indigo : at.textM,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue ? AdminTheme.indigo : at.textS,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLogCard extends StatefulWidget {
  final AdminThemeData at;
  // ignore: prefer_const_constructors_in_immutables
  _SkeletonLogCard({required this.at});

  @override
  State<_SkeletonLogCard> createState() => _SkeletonLogCardState();
}

class _SkeletonLogCardState extends State<_SkeletonLogCard>
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: at.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: at.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: at.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 18,
                        width: 70,
                        decoration: BoxDecoration(
                          color: at.divider,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 11,
                        width: 100,
                        decoration: BoxDecoration(
                          color: at.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 13,
                    width: 180,
                    decoration: BoxDecoration(
                      color: at.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 11,
                    width: 130,
                    decoration: BoxDecoration(
                      color: at.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
