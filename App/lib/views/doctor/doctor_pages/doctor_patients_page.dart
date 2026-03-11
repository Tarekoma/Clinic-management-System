// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_patients_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_patient_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/widgets/doctor/doctor_pat_card.dart';
import 'package:Hakim/widgets/doctor/doctor_pat_form.dart';
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
    final loading = state.loadingPatients;
    final q = state.patientSearchQuery;
    final list = vm.filteredPatients;

    return Scaffold(
      backgroundColor: _T.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, vm),
        backgroundColor: _T.navy,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add Patient',
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
                'Search by name, phone, or national ID...',
                pre: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _T.textM,
                ),
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
                  '${state.patients.length} patients total',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _T.textM,
                    letterSpacing: 0.5,
                  ),
                ),
                if (q.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${list.length} results',
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
              child: _buildList(loading, list, vm),
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
  ) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }
    if (list.isEmpty) {
      return const DoctorEmpty(
        icon: Icons.people_outline_rounded,
        title: 'No patients found',
        sub: 'Try a different search or add a new patient.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => DoctorPatCard(
        patient: list[i],
        onTap: () {
          final pid = int.tryParse((list[i]['id'] ?? '').toString()) ?? 0;
          if (pid > 0) vm.fetchReports(pid);
          _openDetail(list[i], vm);
        },
        onEdit: () => _showEditSheet(list[i], vm),
      ),
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

  void _showAddSheet(BuildContext context, DoctorViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorPatForm(
        onSubmit: (data, {existingId}) =>
            vm.createOrUpdatePatient(data, existingId: existingId),
        snack: _snack,
      ),
    );
  }

  void _showEditSheet(Map<String, dynamic> patient, DoctorViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorPatForm(
        existing: patient,
        onSubmit: (data, {existingId}) =>
            vm.createOrUpdatePatient(data, existingId: existingId),
        snack: _snack,
      ),
    );
  }
}
