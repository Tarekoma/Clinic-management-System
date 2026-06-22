// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_appointments_page.dart
//
// CHANGE: "Done" (onStatus) removed from card actions.
//         "Details" (onDetails) added — opens DoctorApptDetailsSheet with
//         full patient information for the selected appointment.
//         Localized via AppLocalizations.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/widgets/doctor/doctor_appt_card.dart';
import 'package:Hakim/widgets/doctor/doctor_appt_form.dart';
import 'package:Hakim/widgets/doctor/doctor_appt_details_sheet.dart'; // ← NEW
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
  late DoctorThemeData _dt;
  DoctorApptFilter _filter = DoctorApptFilter.all;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(doctorViewModelProvider.notifier).loadMoreAppointments();
    }
  }

  // ── Snack helper ──────────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(doctorViewModelProvider);
    final vm = ref.read(doctorViewModelProvider.notifier);

    final loading = state.loadingAppointments;
    final q = state.apptSearchQuery;
    final list = vm.filteredAppointments(_filter);

    return Scaffold(
      backgroundColor: _dt.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        backgroundColor: _T.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          loc.newAppointment,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: _T.inpOf(
                context,
                loc.searchPatientName,
                pre: Icon(Icons.search_rounded, color: _dt.textM, size: 20),
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
          // ── Filter chips ──────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                for (final (f, lbl) in [
                  (DoctorApptFilter.all, loc.filterAll),
                  (DoctorApptFilter.today, loc.filterToday),
                  (DoctorApptFilter.upcoming, loc.filterUpcoming),
                  (DoctorApptFilter.urgent, loc.filterUrgent),
                  (DoctorApptFilter.completed, loc.filterDone),
                ])
                  _buildChip(f, lbl, vm),
              ],
            ),
          ),
          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.fetchAppointments,
              color: _T.navy,
              child: _buildList(loading, list, state, loc),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chip ───────────────────────────────────────────────────────────

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
          color: sel ? _T.navy : _dt.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _T.navy : _dt.divider),
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
                color: sel ? Colors.white : _dt.textS,
              ),
            ),
            if (cnt > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: sel ? Colors.white.withOpacity(0.25) : _dt.bgInput,
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

  // ── Appointment list ──────────────────────────────────────────────────────

  Widget _buildList(
    bool loading,
    List<Map<String, dynamic>> list,
    DoctorState state,
    AppLocalizations loc,
  ) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }
    if (list.isEmpty) {
      return DoctorEmpty(
        icon: Icons.calendar_month_outlined,
        title: loc.noAppointmentsFound,
        sub: loc.noAppointmentsFoundSub,
      );
    }

    final showFooter =
        state.loadingMoreAppointments || !state.appointmentsHasMore;

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: list.length + (showFooter ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == list.length) {
          if (state.loadingMoreAppointments) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: _T.navy,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                loc.endOfResults,
                style: TextStyle(fontSize: 12, color: _dt.textM),
              ),
            ),
          );
        }

        final appt = list[i];
        final s = (appt['status'] ?? '').toUpperCase();
        return Padding(
          padding: EdgeInsets.only(bottom: i < list.length - 1 ? 10 : 0),
          child: GestureDetector(
            onTap: () {
              if (s == 'SCHEDULED' || s == 'IN_PROGRESS') {
                widget.onStartConsultation(appt);
              }
            },
            child: DoctorApptCard(
              appt: appt,
              onStart: () => widget.onStartConsultation(appt),
              onEdit: () => _showForm(ctx, appt),
              onDetails: () => _showDetails(appt, state),
              onCancel: () => _cancel(appt),
            ),
          ),
        );
      },
    );
  }

  // ── Cancel appointment ────────────────────────────────────────────────────

  Future<void> _cancel(Map<String, dynamic> appt) async {
    final loc = AppLocalizations.of(context)!;
    final vm = ref.read(doctorViewModelProvider.notifier);
    final id = int.tryParse(appt['id'].toString());
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.cancelAppointmentAction),
        content: Text(loc.cancelAppointmentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              loc.yes,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await vm.updateAppointmentStatus(id, 'CANCELLED');
      if (mounted) _snack(loc.statusCancelled);
    } catch (e) {
      if (mounted) _snack(e.toString(), err: true);
    }
  }

  // ── Open details sheet ────────────────────────────────────────────────────

  void _showDetails(Map<String, dynamic> appt, DoctorState state) {
    // Resolve the richer patient record from the patients list using the id
    // carried inside the appointment map.
    final patientId = appt['patient_id'] ?? appt['patient']?['id'];

    Map<String, dynamic>? patient;
    if (patientId != null) {
      try {
        patient = state.patients.firstWhere(
          (p) => p['id'].toString() == patientId.toString(),
        );
      } catch (_) {
        // Patient not in local cache — sheet still shows appointment data.
        patient = null;
      }
    }

    showAppointmentDetails(context: context, appt: appt, patient: patient);
  }

  // ── Create / edit form ────────────────────────────────────────────────────
  Future<void> _showForm(
    BuildContext context,
    Map<String, dynamic>? existing,
  ) async {
    final state = ref.read(doctorViewModelProvider);
    final vm = ref.read(doctorViewModelProvider.notifier);
    final loc = AppLocalizations.of(context)!;
    final isNew = existing == null;

    // No status manipulation here — viewmodel handles it internally
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorApptForm(
        existing: existing,
        patients: state.patients,
        types: state.appointmentTypes,
        doctorId: int.parse(widget.doctorProfile.id),
        existingAppointments: state.appointments,
        onSubmit: (data, {existingId}) =>
            vm.createOrUpdateAppointment(data, existingId: existingId),
        snack: _snack,
      ),
    );
    if (isNew && created == true && mounted) {
      _snack(loc.appointmentBookedSuccess);
      setState(() => _filter = DoctorApptFilter.all);
    }
  }
}
