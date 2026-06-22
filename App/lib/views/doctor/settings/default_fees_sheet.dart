// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/settings/default_fees_sheet.dart
// MVVM — View only. saveFees() delegates to SettingsViewModel.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/settings_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/views/doctor/settings/settings_sheet_helpers.dart';

class DefaultFeesSheet extends ConsumerStatefulWidget {
  const DefaultFeesSheet({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const DefaultFeesSheet(),
      );

  @override
  ConsumerState<DefaultFeesSheet> createState() => _DefaultFeesSheetState();
}

class _DefaultFeesSheetState extends ConsumerState<DefaultFeesSheet> {
  final _formKey     = GlobalKey<FormState>();
  late final TextEditingController _consultCtrl;
  late final TextEditingController _revisitCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(settingsViewModelProvider);
    _consultCtrl = TextEditingController(text: state.consultFee.toStringAsFixed(0));
    _revisitCtrl = TextEditingController(text: state.revisitFee.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _consultCtrl.dispose();
    _revisitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(settingsViewModelProvider.notifier).saveFees(
          consultFee: double.tryParse(_consultCtrl.text) ?? 200,
          revisitFee: double.tryParse(_revisitCtrl.text) ?? 100,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sheetHandle(),
            const SizedBox(height: 8),
            sheetTitle('Default Fees', Icons.payments_outlined),
            const SizedBox(height: 6),
            const Text(
              'These fees auto-fill when creating new appointments.',
              style: TextStyle(fontSize: 12, color: DoctorTheme.textS),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _consultCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: DoctorTheme.inp(
                'Consultation fee (EGP)',
                pre: const Icon(Icons.monetization_on_outlined, size: 18),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter a fee amount' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _revisitCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: DoctorTheme.inp(
                'Revisit fee (EGP)',
                pre: const Icon(Icons.monetization_on_outlined, size: 18),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter a fee amount' : null,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: sheetBtnStyle(),
                onPressed: _save,
                child: const Text('Save fees'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
