// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_patients_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/utils/assistant_theme.dart';
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

  Future<void> _deletePatient(Map<String, dynamic> p) async {
    final vm = ref.read(assistantViewModelProvider.notifier);
    final name = vm.patName(p);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Patient'),
        content: Text('Delete $name? This cannot be undone.'),
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
      await vm.deletePatient(p['id'] as int);
      _snack('$name deleted');
    } catch (e) {
      _snack('Failed: ${e.toString()}', err: true);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantViewModelProvider);
    final vm = ref.read(assistantViewModelProvider.notifier);
    final filtered = vm.filteredPatients;

    if (state.patientsError) {
      return AssistantErrorWidget(
        message: 'Failed to load patients',
        onRetry: vm.fetchPatients,
      );
    }

    return Scaffold(
      backgroundColor: _T.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: _T.green,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add Patient',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                decoration: _T.inp(
                  'Search by name, phone, or national ID...',
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
                    '${state.patients.length} patients total',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _T.textM,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty) ...[
                    const Text(
                      '  •  ',
                      style: TextStyle(fontSize: 11, color: _T.textM),
                    ),
                    Text(
                      '${filtered.length} results',
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
                  ? const _Empty(
                      icon: Icons.people_outline_rounded,
                      title: 'No patients found',
                      sub: 'Try a different search or add a new patient.',
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        return AssistantPatCard(
                          patient: p,
                          onTap: () => _showDetail(p),
                          onEdit: () => _showForm(p),
                          onDelete: () => _deletePatient(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
