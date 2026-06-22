// lib/views/admin/admin_patients_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/admin_providers.dart';
import 'package:Hakim/utils/admin_theme.dart';

typedef _T = AdminTheme;

class AdminPatientsPage extends ConsumerStatefulWidget {
  const AdminPatientsPage({super.key});

  @override
  ConsumerState<AdminPatientsPage> createState() => _AdminPatientsPageState();
}

class _AdminPatientsPageState extends ConsumerState<AdminPatientsPage> {
  final _idCtrl = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AdminThemeData>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(at),
          const SizedBox(height: 20),
          _buildWarningBanner(at),
          const SizedBox(height: 20),
          _buildDeleteCard(context, at),
        ],
      ),
    );
  }

  Widget _buildPageHeader(AdminThemeData at) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _T.urgent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_remove_rounded, color: _T.urgent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: at.textH,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Permanent deletion of patient records',
                    style: TextStyle(fontSize: 12, color: at.textM),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWarningBanner(AdminThemeData at) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.urgent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.urgent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _T.urgent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: _T.urgent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Permanent Action — Cannot Be Undone',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _T.urgent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Deleting a patient permanently removes their complete record including all appointments, visits, consultation notes, and medical history.',
            style: TextStyle(
              fontSize: 13,
              color: at.textS,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _T.urgent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: _T.urgent, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verify the patient ID carefully before proceeding. This action is irreversible.',
                    style: TextStyle(
                      fontSize: 11,
                      color: _T.urgent.withValues(alpha: 0.80),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteCard(BuildContext context, AdminThemeData at) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _T.cardOf(context, r: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delete Patient by ID',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: at.textH,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the numeric patient ID to delete their record.',
            style: TextStyle(fontSize: 12, color: at.textM),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _idCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(fontSize: 16, color: at.textH, fontWeight: FontWeight.w600),
            decoration: AdminTheme.inpOf(
              context,
              'Patient ID',
              hint: 'e.g. 1042',
              pre: Icon(Icons.tag_rounded, size: 18, color: at.textM),
              suf: _idCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, size: 18, color: at.textM),
                      onPressed: () => setState(() => _idCtrl.clear()),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _tryDelete(context),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_isDeleting || _idCtrl.text.isEmpty)
                  ? null
                  : () => _tryDelete(context),
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.delete_forever_rounded, size: 20),
              label: Text(
                _isDeleting ? 'Deleting…' : 'Delete Patient Permanently',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.urgent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _T.urgent.withValues(alpha: 0.40),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _tryDelete(BuildContext context) {
    final idText = _idCtrl.text.trim();
    if (idText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a patient ID.'),
          backgroundColor: _T.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final patientId = int.tryParse(idText);
    if (patientId == null) return;

    final adminTheme = Theme.of(context);

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
                  color: _T.urgent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: _T.urgent, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Confirm Deletion'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(ctx).textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                        text: 'You are about to permanently delete patient '),
                    TextSpan(
                      text: '#$patientId',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _T.urgent,
                      ),
                    ),
                    const TextSpan(text: ' and all of their data.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _T.urgentBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: _T.urgent, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This cannot be undone.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _T.urgent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _performDelete(context, patientId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.urgent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performDelete(BuildContext context, int patientId) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isDeleting = true);
    final error = await ref
        .read(adminViewModelProvider.notifier)
        .deletePatient(patientId);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (error == null) {
      _idCtrl.clear();
      setState(() {});
      messenger.showSnackBar(
        SnackBar(
          content: Text('Patient #$patientId deleted successfully.'),
          backgroundColor: _T.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: _T.urgent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
