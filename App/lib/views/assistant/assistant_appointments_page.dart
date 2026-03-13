// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_appointments_page.dart
//
// Refactored from _buildAppointments() + helpers in the original monolith.
//
// Architecture changes (visual output is 100% identical):
//   • ConsumerStatefulWidget instead of StatefulWidget
//   • All state from Riverpod (ref.watch / ref.read)
//   • Zero ApiService calls — all delegated to AssistantViewModel
//   • Search query stored in controller, pushed to ViewModel on change
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/widgets/assistant/assistant_appt_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/widgets/assistant/assistant_shared_widgets.dart';
import 'package:Hakim/widgets/assistant/assistant_appt_card.dart';

typedef _T = AssistantTheme;
typedef _Empty = AssistantEmpty;

class AssistantAppointmentsPage extends ConsumerStatefulWidget {
  const AssistantAppointmentsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AssistantAppointmentsPage> createState() =>
      _AssistantAppointmentsPageState();
}

class _AssistantAppointmentsPageState
    extends ConsumerState<AssistantAppointmentsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── SnackBar helper ─────────────────────────────────────────────────────────

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

  // ── Appointment options bottom sheet ────────────────────────────────────────

  void _showOptions(Map<String, dynamic> a) {
    final status = (a['status'] ?? '').toUpperCase();
    final id = int.tryParse((a['id'] ?? '0').toString()) ?? 0;
    final vm = ref.read(assistantViewModelProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _T.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 8,
          left: 8,
          right: 8,
          bottom: MediaQuery.of(ctx).padding.bottom + 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _T.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AssistantBottomSheetTile(
              icon: Icons.edit_rounded,
              label: 'Edit Appointment',
              color: _T.info,
              onTap: () {
                Navigator.pop(ctx);
                _showForm(a);
              },
            ),
            if (status == 'SCHEDULED')
              AssistantBottomSheetTile(
                icon: Icons.lock_clock_rounded,
                label: 'Confirm Appointment',
                color: _T.confirmed,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(vm, id, 'CONFIRMED');
                },
              ),
            if (status == 'SCHEDULED' || status == 'CONFIRMED')
              AssistantBottomSheetTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Mark as Completed',
                color: _T.success,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(vm, id, 'COMPLETED');
                },
              ),
            if (status != 'CANCELLED' && status != 'COMPLETED')
              AssistantBottomSheetTile(
                icon: Icons.cancel_outlined,
                label: 'Cancel Appointment',
                color: _T.warning,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(vm, id, 'CANCELLED');
                },
              ),
            AssistantBottomSheetTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Appointment',
              color: _T.urgent,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(a, vm);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(dynamic vm, int id, String status) async {
    try {
      await vm.updateAppointmentStatus(id, status);
      _snack('Status updated to ${_T.sLabel(status)}');
    } catch (e) {
      _snack('Failed: ${vm.runtimeType}.extractError(e)', err: true);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> a, dynamic vm) async {
    final name = ref.read(assistantViewModelProvider.notifier).apptName(a);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Appointment'),
        content: Text('Delete appointment for $name? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.urgent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final id = int.tryParse((a['id'] ?? '0').toString()) ?? 0;
      await ref.read(assistantViewModelProvider.notifier).deleteAppointment(id);
      _snack('Appointment deleted');
    } catch (e) {
      _snack('Failed: ${e.toString()}', err: true);
    }
  }

  void _showForm([Map<String, dynamic>? existing]) {
    final state = ref.read(assistantViewModelProvider);
    final vm = ref.read(assistantViewModelProvider.notifier);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScaffoldMessenger(
        child: AssistantApptForm(
          existing: existing,
          patients: state.patients,
          activeDoctorId: state.activeDoctor != null
              ? int.tryParse(state.activeDoctor!['id'].toString())
              : null,
          appointmentTypes: state.appointmentTypes,
          patName: vm.patName,
          onSubmit: vm.createOrUpdateAppointment,
          onSaved: vm.fetchAppointments,
          snack: _snack,
        ),
      ),
    );
  }

  // ── Section header (SliverToBoxAdapter) ────────────────────────────────────

  SliverToBoxAdapter _sectionHeader(String label, Color color) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantViewModelProvider);
    final vm = ref.read(assistantViewModelProvider.notifier);

    if (state.appointmentsError) {
      return AssistantErrorWidget(
        message: 'Failed to load appointments',
        onRetry: vm.fetchAppointments,
      );
    }

    final now = DateTime.now();
    final todayDay = DateTime(now.year, now.month, now.day);
    final tomorrow = todayDay.add(const Duration(days: 1));
    final all = vm.filteredAppointments;

    final todayList = <Map<String, dynamic>>[];
    final upList = <Map<String, dynamic>>[];
    final pastList = <Map<String, dynamic>>[];

    for (final a in all) {
      final dt = vm.parseDate(a['start_time']);
      if (dt == null) continue;
      final day = DateTime(dt.year, dt.month, dt.day);
      if (!day.isBefore(todayDay) && day.isBefore(tomorrow)) {
        todayList.add(a);
      } else if (!day.isBefore(tomorrow)) {
        upList.add(a);
      } else {
        pastList.add(a);
      }
    }

    int queueSort(Map a, Map b) {
      if ((a['is_urgent'] == true) != (b['is_urgent'] == true)) {
        return a['is_urgent'] == true ? -1 : 1;
      }
      final da = vm.parseDate(a['start_time']) ?? now;
      final db = vm.parseDate(b['start_time']) ?? now;
      return da.compareTo(db);
    }

    todayList.sort(queueSort);
    upList.sort(queueSort);

    final serving = todayList.where((a) {
      final s = (a['status'] ?? '').toUpperCase();
      return s == 'SCHEDULED' || s == 'CONFIRMED';
    }).firstOrNull;

    return Scaffold(
      backgroundColor: _T.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: _T.green,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: vm.fetchAppointments,
        color: _T.green,
        child: CustomScrollView(
          slivers: [
            // ── Search + summary ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: _T.inp(
                        'Search by patient name, phone...',
                        pre: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: _T.textM,
                        ),
                        suf: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  vm.setApptSearch('');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) {
                        vm.setApptSearch(v);
                        setState(() {}); // to toggle clear button
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        AssistantCountChip(
                          label: 'Today',
                          count: todayList.length,
                          color: _T.green,
                          bg: _T.greenPale,
                        ),
                        const SizedBox(width: 8),
                        AssistantCountChip(
                          label: 'Upcoming',
                          count: upList.length,
                          color: _T.info,
                          bg: _T.infoBg,
                        ),
                        const SizedBox(width: 8),
                        AssistantCountChip(
                          label: 'Urgent',
                          count: all
                              .where((a) => a['is_urgent'] == true)
                              .length,
                          color: _T.urgent,
                          bg: _T.urgentBg,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Loading / empty / list ─────────────────────────────────────
            if (state.loadingAppointments)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: _T.green,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (all.isEmpty)
              const SliverFillRemaining(
                child: _Empty(
                  icon: Icons.calendar_month_outlined,
                  title: 'No appointments found',
                  sub: 'Tap + to create a new appointment.',
                ),
              )
            else ...[
              if (serving != null) ...[
                _sectionHeader('Now Serving', _T.green),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: AssistantApptCard(
                      appt: serving,
                      highlight: true,
                      onTap: () => _showOptions(serving),
                    ),
                  ),
                ),
              ],
              if (todayList.isNotEmpty) ...[
                _sectionHeader("Today's Queue", _T.green),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => AssistantApptCard(
                        appt: todayList[i],
                        onTap: () => _showOptions(todayList[i]),
                      ),
                      childCount: todayList.length,
                    ),
                  ),
                ),
              ],
              if (upList.isNotEmpty) ...[
                _sectionHeader('Upcoming', _T.info),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => AssistantApptCard(
                        appt: upList[i],
                        onTap: () => _showOptions(upList[i]),
                      ),
                      childCount: upList.length,
                    ),
                  ),
                ),
              ],
              if (pastList.isNotEmpty) ...[
                _sectionHeader('Past', _T.muted),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => AssistantApptCard(
                        appt: pastList[i],
                        onTap: () => _showOptions(pastList[i]),
                      ),
                      childCount: pastList.length,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
