// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_patients_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/viewmodels/assistant_viewmodel.dart';
import 'package:Hakim/widgets/assistant/assistant_shared_widgets.dart';
import 'package:Hakim/widgets/assistant/assistant_pat_card.dart';
import 'package:Hakim/widgets/assistant/assistant_pat_form.dart';
import 'package:Hakim/widgets/assistant/assistant_patient_detail.dart';
import 'package:Hakim/widgets/assistant/assistant_appt_form.dart'; // NEW — for auto-open

typedef _T = AssistantTheme;
typedef _Empty = AssistantEmpty;

class AssistantPatientsPage extends ConsumerStatefulWidget {
  const AssistantPatientsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AssistantPatientsPage> createState() =>
      _AssistantPatientsPageState();
}

class _AssistantPatientsPageState extends ConsumerState<AssistantPatientsPage> {
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
      ref.read(assistantViewModelProvider.notifier).loadMorePatients();
    }
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

  // ── Patient actions ─────────────────────────────────────────────────────────

  void _showDetail(Map<String, dynamic> p) {
    final state = ref.read(assistantViewModelProvider);
    showDialog(
      context: context,
      builder: (_) => AssistantPatientDetail(
        patient: p,
        appointments: state.appointments,
        onEdit: () => _showForm(p),
      ),
    );
  }

  /// Opens the patient form.
  ///
  /// When [existing] is null (new patient) the sheet's `.then()` callback
  /// checks [AssistantState.lastCreatedPatient].  If the ViewModel stored a
  /// response (i.e. creation succeeded), the appointment form opens immediately
  /// with that patient pre-selected — the user never has to search again.
  void _showForm([Map<String, dynamic>? existing]) {
    final vm = ref.read(assistantViewModelProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScaffoldMessenger(
        child: AssistantPatForm(
          existing: existing,
          onSubmit: vm.createOrUpdatePatient,
          onSaved: vm.fetchPatients,
          snack: _snack,
        ),
      ),
    ).then((_) {
      // Only act when adding a NEW patient (not editing).
      if (existing != null || !mounted) return;

      final newPatient = ref
          .read(assistantViewModelProvider)
          .lastCreatedPatient;
      if (newPatient == null) return;

      // Consume the value so subsequent form opens don't re-trigger.
      ref.read(assistantViewModelProvider.notifier).clearLastCreatedPatient();

      // Open the appointment form with the new patient pre-selected.
      _showApptFormForPatient(newPatient);
    });
  }

  /// Opens [AssistantApptForm] with [patient] already selected.
  ///
  /// Reads the current ViewModel state so it always has up-to-date
  /// patients / types / activeDoctor — no extra API calls needed.
  void _showApptFormForPatient(Map<String, dynamic> patient) {
    if (!mounted) return;
    final state = ref.read(assistantViewModelProvider);
    final vm = ref.read(assistantViewModelProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScaffoldMessenger(
        child: AssistantApptForm(
          preSelectedPatient: patient,
          patients: state.patients,
          activeDoctorId: state.activeDoctor != null
              ? int.tryParse(state.activeDoctor!['id'].toString())
              : null,
          appointmentTypes: state.appointmentTypes,
          existingAppointments: state.appointments,
          patName: vm.patName,
          onSubmit: vm.createOrUpdateAppointment,
          onSaved: vm.fetchAppointments,
          snack: _snack,
        ),
      ),
    );
  }

  Future<void> _deletePatient(Map<String, dynamic> p) async {
    final loc = AppLocalizations.of(context)!;
    final vm = ref.read(assistantViewModelProvider.notifier);
    final name = vm.patName(p);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(loc.deletePatientTitle),
          content: Text(loc.deletePatientBody(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.urgent,
                foregroundColor: Colors.white,
              ),
              child: Text(loc.delete),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await vm.deletePatient(p['id'] as int);
      _snack(loc.patientDeleted(name));
    } catch (e) {
      _snack(loc.actionFailed(e.toString()), err: true);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final state = ref.watch(assistantViewModelProvider);
    final vm = ref.read(assistantViewModelProvider.notifier);
    final filtered = vm.filteredPatients;
    final loc = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;

    if (state.patientsError) {
      return AssistantErrorWidget(
        message: loc.failedToLoadPatients,
        onRetry: vm.fetchPatients,
      );
    }

    return Scaffold(
      backgroundColor: at.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: _T.green,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          loc.addPatient,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: vm.fetchPatients,
        color: _T.green,
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchCtrl,
                decoration: _T.inpOf(
                  context,
                  loc.searchPatientFull,
                  pre: Icon(Icons.search_rounded, size: 20, color: at.textM),
                  suf: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            vm.setPatientSearch('');
                            vm.fetchPatients();
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  vm.setPatientSearch(v);
                  setState(() {}); // toggle clear button
                  if (v.length >= 2 || v.isEmpty) {
                    vm.fetchPatients(search: v);
                  }
                },
              ),
            ),
            // ── Count row ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    arDigits(loc.patientsTotalCount(state.patients.length), lc),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: at.textM,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty) ...[
                    Text(
                      '  •  ',
                      style: TextStyle(fontSize: 11, color: at.textM),
                    ),
                    Text(
                      arDigits(loc.resultsCount(filtered.length), lc),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _T.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: state.loadingPatients
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _T.green,
                        strokeWidth: 2,
                      ),
                    )
                  : filtered.isEmpty
                  ? _Empty(
                      icon: Icons.people_outline_rounded,
                      title: loc.noPatientsFound,
                      sub: loc.noPatientsFoundSub,
                    )
                  : _buildPatientList(filtered, state, at, loc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList(
    List<Map<String, dynamic>> list,
    AssistantState state,
    AssistantThemeData at,
    AppLocalizations loc,
  ) {
    final showFooter = state.loadingMorePatients || !state.patientsHasMore;

    return ListView.builder(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: list.length + (showFooter ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == list.length) {
          if (state.loadingMorePatients) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: _T.green,
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
                style: TextStyle(fontSize: 12, color: at.textM),
              ),
            ),
          );
        }
        final p = list[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i < list.length - 1 ? 10 : 0),
          child: AssistantPatCard(
            patient: p,
            onTap: () => _showDetail(p),
            onEdit: () => _showForm(p),
            onDelete: () => _deletePatient(p),
          ),
        );
      },
    );
  }
}
