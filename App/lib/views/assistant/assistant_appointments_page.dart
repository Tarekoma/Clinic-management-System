// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_appointments_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/views/assistant/assistant_vitals_page.dart';
import 'package:Hakim/viewmodels/assistant_viewmodel.dart';
import 'package:Hakim/widgets/assistant/assistant_appt_form.dart';
import 'package:Hakim/widgets/doctor/doctor_appt_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/widgets/assistant/assistant_shared_widgets.dart';
import 'package:Hakim/widgets/assistant/assistant_appt_card.dart';

typedef _T = AssistantTheme;
typedef _Empty = AssistantEmpty;

// Active / finished status sets — keyed on raw AppointmentStatus.
// 'WAITING' is a VisitStatus, not an AppointmentStatus, so it never appears
// in a['status'] and is intentionally excluded here.
const _activeStatuses = {'IN_PROGRESS', 'SCHEDULED', 'CONFIRMED'};
const _finishedStatuses = {'COMPLETED', 'CANCELLED', 'NO_SHOW'};

class AssistantAppointmentsPage extends ConsumerStatefulWidget {
  const AssistantAppointmentsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AssistantAppointmentsPage> createState() =>
      _AssistantAppointmentsPageState();
}

class _AssistantAppointmentsPageState
    extends ConsumerState<AssistantAppointmentsPage> {
  final _searchCtrl = TextEditingController();
  AssistantApptFilter _filter = AssistantApptFilter.today;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final types = ref.read(assistantViewModelProvider).appointmentTypes;
      if (types.isEmpty) {
        ref.read(assistantViewModelProvider.notifier).fetchAppointmentTypes();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 300) {
      if (!_isLoadingMore) {
        _isLoadingMore = true;
        ref
            .read(assistantViewModelProvider.notifier)
            .loadMoreAppointments()
            .whenComplete(() => _isLoadingMore = false);
      }
    }
    return false;
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
    final loc = AppLocalizations.of(context)!;

    final isTerminal =
        status == 'CANCELLED' || status == 'COMPLETED' || status == 'NO_SHOW';
    final canEdit = !isTerminal && status != 'IN_PROGRESS';
    final canRecordVitals = !isTerminal;
    final canCancel = status == 'SCHEDULED' || status == 'CONFIRMED';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).extension<AssistantThemeData>()!.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color:
                      Theme.of(context).extension<AssistantThemeData>()!.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AssistantBottomSheetTile(
              icon: Icons.person_outline_rounded,
              label: loc.actionDetails,
              color: _T.info,
              onTap: () {
                Navigator.pop(ctx);
                _showDetails(a);
              },
            ),
            if (canEdit)
              AssistantBottomSheetTile(
                icon: Icons.edit_rounded,
                label: loc.editAppointmentTitle,
                color: _T.info,
                onTap: () {
                  Navigator.pop(ctx);
                  _showForm(a);
                },
              ),
            if (canRecordVitals)
              AssistantBottomSheetTile(
                icon: Icons.monitor_heart_rounded,
                label: loc.recordVitals,
                color: _T.green,
                onTap: () {
                  Navigator.pop(ctx);
                  _showVitals(a);
                },
              ),
            if (status == 'SCHEDULED')
              AssistantBottomSheetTile(
                icon: Icons.lock_clock_rounded,
                label: loc.confirmAppointmentAction,
                color: _T.confirmed,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(vm, id, 'CONFIRMED', loc);
                },
              ),
            if (status == 'SCHEDULED' || status == 'CONFIRMED')
              AssistantBottomSheetTile(
                icon: Icons.login_rounded,
                label: loc.checkInPatient,
                color: _T.waitingYellow,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _checkIn(vm, id, loc);
                },
              ),
            if (status == 'SCHEDULED' || status == 'CONFIRMED')
              AssistantBottomSheetTile(
                icon: Icons.person_off_outlined,
                label: loc.markAsNoShow,
                color: _T.muted,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(vm, id, 'NO_SHOW', loc);
                },
              ),
            if (canCancel)
              AssistantBottomSheetTile(
                icon: Icons.cancel_outlined,
                label: loc.cancelAppointmentAction,
                color: _T.warning,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(vm, id, 'CANCELLED', loc);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> a) {
    final state = ref.read(assistantViewModelProvider);
    final patientId = a['patient_id'] ?? a['patient']?['id'];
    Map<String, dynamic>? patient;
    if (patientId != null) {
      try {
        patient = state.patients.firstWhere(
          (p) => p['id'].toString() == patientId.toString(),
        );
      } catch (_) {
        patient = null;
      }
    }
    showAppointmentDetails(context: context, appt: a, patient: patient);
  }

  Future<void> _updateStatus(
    dynamic vm,
    int id,
    String status,
    AppLocalizations loc,
  ) async {
    try {
      await vm.updateAppointmentStatus(id, status);
      _snack(loc.statusUpdatedTo(_T.sLabel(status, loc)));
    } catch (e) {
      _snack(loc.actionFailed(e.toString()), err: true);
    }
  }

  Future<void> _checkIn(dynamic vm, int id, AppLocalizations loc) async {
    try {
      await vm.checkInPatient(id);
      _snack(loc.checkInPatient);
    } catch (e) {
      _snack(loc.actionFailed(e.toString()), err: true);
    }
  }

  void _showVitals(Map<String, dynamic> a) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScaffoldMessenger(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AssistantVitalsPage(appointment: a, onSaved: () {}),
        ),
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        _snack(AppLocalizations.of(context)!.vitalsSavedSuccess);
      }
    });
  }

  Future<void> _showForm([Map<String, dynamic>? existing]) async {
    final vm = ref.read(assistantViewModelProvider.notifier);
    // Fire without awaiting — form renders immediately from cached/fallback types.
    vm.fetchAppointmentTypes();
    if (!mounted) return;
    final state = ref.read(assistantViewModelProvider);
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

  // ── Section header ──────────────────────────────────────────────────────────

  SliverToBoxAdapter _sectionHeader(String label, Color color) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
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
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final state = ref.watch(assistantViewModelProvider);
    final vm = ref.read(assistantViewModelProvider.notifier);
    final loc = AppLocalizations.of(context)!;

    if (state.appointmentsError) {
      return AssistantErrorWidget(
        message: state.appointmentsErrorMessage.isNotEmpty
            ? state.appointmentsErrorMessage
            : loc.failedToLoadAppointments,
        onRetry: vm.fetchAppointments,
      );
    }

    final list = vm.filteredByFilter(_filter);

    return Scaffold(
      backgroundColor: at.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: _T.green,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          loc.newAppointment,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Search ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: _T.inpOf(
                context,
                loc.searchPatientNameFull,
                pre: Icon(Icons.search_rounded, size: 20, color: at.textM),
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
                setState(() {});
              },
            ),
          ),
          // ── Filter chips ────────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                for (final (f, lbl) in [
                  (AssistantApptFilter.today, loc.filterToday),
                  (AssistantApptFilter.waiting, loc.filterWaiting),
                  (AssistantApptFilter.upcoming, loc.filterUpcoming),
                  (AssistantApptFilter.urgent, loc.filterUrgent),
                  (AssistantApptFilter.completed, loc.filterCompleted),
                  (AssistantApptFilter.cancelled, loc.filterCancelled),
                  (AssistantApptFilter.all, loc.filterAll),
                ])
                  _buildChip(f, lbl, vm, at),
              ],
            ),
          ),
          // ── List ────────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.fetchAppointments,
              color: _T.green,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: _filter == AssistantApptFilter.today
                    ? _buildTodayView(list, state, loc, at, vm)
                    : _buildSimpleList(list, state, loc, at),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chip ─────────────────────────────────────────────────────────────

  Widget _buildChip(
    AssistantApptFilter f,
    String lbl,
    AssistantViewModel vm,
    AssistantThemeData at,
  ) {
    final sel = _filter == f;
    final chipColor = (f == AssistantApptFilter.urgent && sel)
        ? _T.urgent
        : sel
        ? _T.green
        : null;

    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: chipColor ?? at.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipColor ?? at.divider),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: (chipColor ?? _T.green).withValues(alpha: 0.22),
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
                color: sel ? Colors.white : at.textS,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: sel
                    ? Colors.white.withValues(alpha: 0.25)
                    : at.bgInput,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${vm.apptFilterCount(f)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : _T.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Today view: Active / Finished sections ──────────────────────────────────

  Widget _buildTodayView(
    List<Map<String, dynamic>> list,
    AssistantState state,
    AppLocalizations loc,
    AssistantThemeData at,
    AssistantViewModel vm,
  ) {
    if (state.loadingAppointments) {
      return const Center(
        child: CircularProgressIndicator(color: _T.green, strokeWidth: 2),
      );
    }
    if (list.isEmpty) {
      return _Empty(
        icon: Icons.calendar_today_outlined,
        title: loc.noAppointmentsFound,
        sub: loc.tapToCreateAppointment,
      );
    }

    final active = list
        .where((a) =>
            _activeStatuses.contains((a['status'] ?? '').toUpperCase()))
        .toList();
    final finished = list
        .where((a) =>
            _finishedStatuses.contains((a['status'] ?? '').toUpperCase()))
        .toList();

    // Next patient = earliest active appointment
    final nextPatient = active.isNotEmpty ? active.first : null;

    return CustomScrollView(
      slivers: [
        if (active.isNotEmpty) ...[
          _sectionHeader(loc.sectionActive, _T.info),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final appt = active[i];
                  final isNext = nextPatient != null &&
                      appt['id'].toString() ==
                          nextPatient['id'].toString();
                  return AssistantApptCard(
                    appt: appt,
                    isNextPatient: isNext,
                    onTap: () => _showOptions(appt),
                  );
                },
                childCount: active.length,
              ),
            ),
          ),
        ],
        if (finished.isNotEmpty) ...[
          _sectionHeader(loc.sectionFinished, at.textM),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => AssistantApptCard(
                  appt: finished[i],
                  onTap: () => _showOptions(finished[i]),
                ),
                childCount: finished.length,
              ),
            ),
          ),
        ] else
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        SliverToBoxAdapter(child: _buildFooter(state, loc, at)),
      ],
    );
  }

  // ── Simple sorted list (non-Today filters) ──────────────────────────────────

  Widget _buildSimpleList(
    List<Map<String, dynamic>> list,
    AssistantState state,
    AppLocalizations loc,
    AssistantThemeData at,
  ) {
    if (state.loadingAppointments) {
      return const Center(
        child: CircularProgressIndicator(color: _T.green, strokeWidth: 2),
      );
    }
    if (list.isEmpty) {
      return _Empty(
        icon: Icons.calendar_month_outlined,
        title: loc.noAppointmentsFound,
        sub: loc.tapToCreateAppointment,
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => AssistantApptCard(
                appt: list[i],
                onTap: () => _showOptions(list[i]),
              ),
              childCount: list.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildFooter(state, loc, at)),
      ],
    );
  }

  // ── Pagination footer ───────────────────────────────────────────────────────

  Widget _buildFooter(
    AssistantState state,
    AppLocalizations loc,
    AssistantThemeData at,
  ) {
    if (state.loadingMoreAppointments) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: _T.green, strokeWidth: 2),
        ),
      );
    }
    if (!state.appointmentsHasMore && state.appointments.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 100, top: 20),
        child: Center(
          child: Text(
            loc.endOfResults,
            style: TextStyle(fontSize: 12, color: at.textM),
          ),
        ),
      );
    }
    return const SizedBox(height: 100);
  }
}
