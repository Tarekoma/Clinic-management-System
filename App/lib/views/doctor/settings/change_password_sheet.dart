// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/settings/change_password_sheet.dart
// MVVM — View only. All logic in SettingsViewModel.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Hakim/providers/settings_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/views/doctor/settings/settings_sheet_helpers.dart';

class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const ChangePasswordSheet(),
      );

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _formKey  = GlobalKey<FormState>();
  final _oldCtrl  = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _showOld  = false;
  bool _showNew  = false;
  bool _showConf = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(settingsViewModelProvider.notifier)
        .changePassword(
          oldPassword: _oldCtrl.text,
          newPassword: _newCtrl.text,
        );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(settingsViewModelProvider).isLoading;
    final error   = ref.watch(settingsViewModelProvider).error;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
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
            sheetTitle('Change Password', Icons.lock_outline),
            const SizedBox(height: 20),

            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: DoctorTheme.urgentBg, borderRadius: BorderRadius.circular(10)),
                child: Text(error, style: const TextStyle(fontSize: 12, color: DoctorTheme.urgent)),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _oldCtrl,
              obscureText: !_showOld,
              decoration: DoctorTheme.inp(
                'Current password',
                pre: const Icon(Icons.lock_outline, size: 18),
                suf: IconButton(
                  icon: Icon(_showOld ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _showOld = !_showOld),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _newCtrl,
              obscureText: !_showNew,
              decoration: DoctorTheme.inp(
                'New password',
                pre: const Icon(Icons.lock_outline, size: 18),
                suf: IconButton(
                  icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter new password';
                if (v.length < 8) return 'At least 8 characters required';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _confCtrl,
              obscureText: !_showConf,
              decoration: DoctorTheme.inp(
                'Confirm new password',
                pre: const Icon(Icons.lock_outline, size: 18),
                suf: IconButton(
                  icon: Icon(_showConf ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _showConf = !_showConf),
                ),
              ),
              validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : _submit,
                style: sheetBtnStyle(),
                child: loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


