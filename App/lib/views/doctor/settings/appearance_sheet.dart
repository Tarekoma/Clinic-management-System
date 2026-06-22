// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/settings/appearance_sheet.dart
// MVVM — View only.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/settings_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/views/doctor/settings/settings_sheet_helpers.dart';

class AppearanceSheet extends ConsumerWidget {
  const AppearanceSheet({Key? key}) : super(key: key);

  static const _languages = ['English', 'العربية'];

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const AppearanceSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final vm = ref.read(settingsViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sheetHandle(),
          const SizedBox(height: 8),
          sheetTitle('Appearance', Icons.palette_outlined),
          const SizedBox(height: 20),

          // Language
          const Text(
            'Language',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DoctorTheme.textH,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4EAF1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.language,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: DoctorTheme.textH),
                items: _languages
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) vm.setLanguage(v);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Dark mode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EEF6)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.dark_mode_outlined,
                  size: 20,
                  color: DoctorTheme.navy,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark mode',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DoctorTheme.textH,
                        ),
                      ),
                      Text(
                        'Easier on the eyes at night',
                        style: TextStyle(
                          fontSize: 11,
                          color: DoctorTheme.textS,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.darkMode,
                  activeColor: DoctorTheme.navy,
                  onChanged: vm.setDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
