// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/settings/reports_export_sheet.dart
// MVVM — View only. Export logic lives in SettingsViewModel.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/providers/settings_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/views/doctor/settings/settings_sheet_helpers.dart';

class ReportsExportSheet extends ConsumerWidget {
  const ReportsExportSheet({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const ReportsExportSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exporting   = ref.watch(settingsViewModelProvider).exporting;
    final vm          = ref.read(settingsViewModelProvider.notifier);
    final doctorState = ref.read(doctorViewModelProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sheetHandle(),
          const SizedBox(height: 8),
          sheetTitle('Reports & Export', Icons.download_outlined),
          const SizedBox(height: 6),
          const Text(
            'Export your clinic data as CSV — open in Excel or Google Sheets.',
            style: TextStyle(fontSize: 12, color: DoctorTheme.textS),
          ),
          const SizedBox(height: 20),

          if (exporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                    color: DoctorTheme.navy, strokeWidth: 2),
              ),
            )
          else ...[
            _ExportTile(
              icon:      Icons.people_outline,
              iconBg:    const Color(0xFFEEEDFE),
              iconColor: const Color(0xFF534AB7),
              title:     'Export Patients',
              sub:       'Name, phone, conditions, demographics',
              onTap:     () => vm.exportPatients(doctorState.patients),
            ),
            const SizedBox(height: 10),
            _ExportTile(
              icon:      Icons.calendar_month_outlined,
              iconBg:    const Color(0xFFE6F1FB),
              iconColor: DoctorTheme.navy,
              title:     'Export Appointments',
              sub:       'Date, status, type, fee, payment status',
              onTap:     () => vm.exportAppointments(doctorState.appointments),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final Color    iconBg, iconColor;
  final String   title, sub;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF6)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DoctorTheme.textH)),
                const SizedBox(height: 2),
                Text(sub,   style: const TextStyle(fontSize: 11, color: DoctorTheme.textS)),
              ],
            ),
          ),
          const Icon(Icons.download_outlined, size: 18, color: DoctorTheme.textS),
        ],
      ),
    ),
  );
}
