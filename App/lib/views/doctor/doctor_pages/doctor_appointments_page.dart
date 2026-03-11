// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_appointments_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/widgets/doctor/doctor_appt_card.dart';
import 'package:Hakim/widgets/doctor/doctor_appt_form.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';

typedef _T = DoctorTheme;

class DoctorAppointmentsPage extends ConsumerStatefulWidget {
  final UserProfile doctorProfile;
  final void Function(Map<String, dynamic>) onStartConsultation;

  const DoctorAppointmentsPage({
    required this.doctorProfile,
    required this.onStartConsultation,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DoctorAppointmentsPage> createState() =>
      _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState
    extends ConsumerState<DoctorAppointmentsPage> {
  DoctorApptFilter _filter = DoctorApptFilter.today;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorViewModelProvider);
    final vm = ref.read(doctorViewModelProvider.notifier);

    // ── Reactive filter switch ──────────────────────────────────────────────
    // When appointments list grows (new one added), switch to Upcoming so the
    // user immediately sees it. Uses ref.listen — correct Riverpod pattern,
    // no reliance on the sheet's Future completing in the right order.
    ref.listen<DoctorState>(doctorViewModelProvider, (prev, next) {
      if (prev != null &&
          next.appointments.length > prev.appointments.length &&
          mounted) {
        setState(() => _filter = DoctorApptFilter.upcoming);
      }
    });

    final loading = state.loadingAppointments;
    final q = state.apptSearchQuery;
    final list = vm.filteredAppointments(_filter);

    return Scaffold(
      backgroundColor: _T.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        backgroundColor: _T.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Search ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: _T.inp(
                'Search patient name...',
                pre: const Icon(
                  Icons.search_rounded,
                  color: _T.textM,
                  size: 20,
                ),
                suf: q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          vm.setApptSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: vm.setApptSearch,
            ),
          ),
          // ── Filter chips ─────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                for (final (f, lbl) in [
                  (DoctorApptFilter.all, 'All'),
                  (DoctorApptFilter.today, 'Today'),
                  (DoctorApptFilter.upcoming, 'Upcoming'),
                  (DoctorApptFilter.urgent, 'Urgent'),
                  (DoctorApptFilter.completed, 'Done'),
                ])
                  _buildChip(f, lbl, vm),
              ],
            ),
          ),
          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.fetchAppointments,
              color: _T.navy,
              child: _buildList(loading, list, vm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(DoctorApptFilter f, String lbl, DoctorViewModel vm) {
    final sel = _filter == f;
    final cnt = vm.apptFilterCount(f);
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: sel ? _T.navy : _T.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _T.navy : _T.divider),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: _T.navy.withOpacity(0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              lbl,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : _T.textS,
              ),
            ),
            if (cnt > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: sel ? Colors.white.withOpacity(0.25) : _T.bgInput,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$cnt',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : _T.navy,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    bool loading,
    List<Map<String, dynamic>> list,
    DoctorViewModel vm,
  ) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }
    if (list.isEmpty) {
      return const DoctorEmpty(
        icon: Icons.calendar_month_outlined,
        title: 'No appointments found',
        sub: 'Try a different filter or book a new appointment.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () {
          final s = (list[i]['status'] ?? '').toUpperCase();
          if (s == 'SCHEDULED' || s == 'IN_PROGRESS') {
            widget.onStartConsultation(list[i]);
          }
        },
        child: DoctorApptCard(
          appt: list[i],
          onStart: () => widget.onStartConsultation(list[i]),
          onEdit: () => _showForm(ctx, list[i]),
          onStatus: (s) => _setStatus(list[i], s, vm),
          onDelete: () => _delete(list[i], vm),
        ),
      ),
    );
  }

  Future<void> _setStatus(
    Map<String, dynamic> a,
    String status,
    DoctorViewModel vm,
  ) async {
    try {
      await vm.updateAppointmentStatus(int.parse(a['id'].toString()), status);
    } catch (e) {
      _snack(DoctorViewModel.extractError(e), err: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> a, DoctorViewModel vm) async {
    final name = vm.apptName(a);
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
      await vm.deleteAppointment(int.parse(a['id'].toString()));
    } catch (e) {
      _snack(DoctorViewModel.extractError(e), err: true);
    }
  }

  Future<void> _showForm(
    BuildContext context,
    Map<String, dynamic>? existing,
  ) async {
    final state = ref.read(doctorViewModelProvider);
    final vm = ref.read(doctorViewModelProvider.notifier);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorApptForm(
        existing: existing,
        patients: state.patients,
        types: state.appointmentTypes,
        doctorId: int.parse(widget.doctorProfile.id),
        onSubmit: (data, {existingId}) =>
            vm.createOrUpdateAppointment(data, existingId: existingId),
        snack: _snack,
      ),
    );
  }
}
