// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_patients_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_patient_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/widgets/doctor/doctor_pat_card.dart';
import 'package:Hakim/widgets/doctor/doctor_pat_form.dart';
import 'package:Hakim/widgets/doctor/doctor_appt_form.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';

typedef _T = DoctorTheme;

class DoctorPatientsPage extends ConsumerStatefulWidget {
  final UserProfile doctorProfile;
  const DoctorPatientsPage({required this.doctorProfile, Key? key})
    : super(key: key);

  @override
  ConsumerState<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends ConsumerState<DoctorPatientsPage> {
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
      ref.read(doctorViewModelProvider.notifier).loadMorePatients();
    }
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
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(doctorViewModelProvider);
    final vm = ref.read(doctorViewModelProvider.notifier);
    final loading = state.loadingPatients;
    final q = state.patientSearchQuery;
    final list = vm.filteredPatients;

    return Scaffold(
      backgroundColor: dt.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, vm),
        backgroundColor: _T.navy,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          loc.addPatient,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: _T.inpOf(
                context,
                loc.searchPatientFull,
                pre: Icon(Icons.search_rounded, size: 20, color: dt.textM),
                suf: q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          vm.setPatientSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: vm.setPatientSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                Text(
                  loc.patientsTotalCount(state.patients.length),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dt.textM,
                    letterSpacing: 0.5,
                  ),
                ),
                if (q.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${loc.resultsCount(list.length)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _T.navy,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.fetchPatients,
              color: _T.navy,
              child: _buildList(loading, list, vm, loc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    bool loading,
    List<Map<String, dynamic>> list,
    DoctorViewModel vm,
    AppLocalizations loc,
  ) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final state = ref.watch(doctorViewModelProvider);

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }
    if (list.isEmpty) {
      return DoctorEmpty(
        icon: Icons.people_outline_rounded,
        title: loc.noPatientsFound,
        sub: loc.noPatientsFoundSub,
      );
    }

    final showFooter =
        state.loadingMorePatients || !state.patientsHasMore;

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: list.length + (showFooter ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == list.length) {
          if (state.loadingMorePatients) {
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
                style: TextStyle(
                  fontSize: 12,
                  color: dt.textM,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(bottom: i < list.length - 1 ? 10 : 0),
          child: DoctorPatCard(
            patient: list[i],
            onTap: () {
              final pid =
                  int.tryParse((list[i]['id'] ?? '').toString()) ?? 0;
              if (pid > 0) vm.fetchReports(pid);
              _openDetail(list[i], vm);
            },
            onEdit: () => _showEditSheet(list[i], vm),
          ),
        );
      },
    );
  }

  void _openDetail(Map<String, dynamic> p, DoctorViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorPatientDetail(
        patient: p,
        onEditPatient: (pat) => _showEditSheet(pat, vm),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, DoctorViewModel vm) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Local ScaffoldMessenger so validation/API-error SnackBars render
      // inside the sheet instead of queuing on the page below.
      builder: (_) => ScaffoldMessenger(
        child: DoctorPatForm(
          onSubmit: (data, {existingId}) =>
              vm.createOrUpdatePatient(data, existingId: existingId),
          snack: _snack,
        ),
      ),
    );

    // Patient was successfully created → open appointment form pre-filled
    if (created == true && mounted) {
      final state = ref.read(doctorViewModelProvider);
      final newPatient = state.lastCreatedPatient;
      vm.clearLastCreatedPatient();
      if (newPatient != null) {
        await _showApptSheet(vm, newPatient);
      }
    }
  }

  /// Opens the appointment form with [preSelectedPatient] locked in.
  /// The patient search field is read-only — no searching needed.
  Future<void> _showApptSheet(
    DoctorViewModel vm,
    Map<String, dynamic> preSelectedPatient,
  ) async {
    if (!mounted) return;
    await vm.fetchAppointmentTypes();
    if (!mounted) return;
    final state = ref.read(doctorViewModelProvider);
    final loc = AppLocalizations.of(context)!;
    final booked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Local ScaffoldMessenger so SnackBars triggered from inside the sheet
      // render within the sheet's own overlay instead of queuing on the page
      // below, where they'd stay hidden until the sheet closes.
      builder: (_) => ScaffoldMessenger(
        child: DoctorApptForm(
          preSelectedPatient: preSelectedPatient,
          patients: state.patients,
          types: state.appointmentTypes,
          doctorId: int.parse(widget.doctorProfile.id),
          onSubmit: (data, {existingId}) =>
              vm.createOrUpdateAppointment(data, existingId: existingId),
          snack: _snack,
        ),
      ),
    );
    if (booked == true && mounted) {
      _snack(loc.appointmentBookedSuccess);
    }
  }

  void _showEditSheet(Map<String, dynamic> patient, DoctorViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Local ScaffoldMessenger so validation/API-error SnackBars render
      // inside the sheet instead of queuing on the page below. DoctorPatForm
      // has no Scaffold.of() dependency, so this wrapper is safe.
      builder: (_) => ScaffoldMessenger(
        child: DoctorPatForm(
          existing: patient,
          onSubmit: (data, {existingId}) =>
              vm.createOrUpdatePatient(data, existingId: existingId),
          snack: _snack,
        ),
      ),
    );
  }
}
