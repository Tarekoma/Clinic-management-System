// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/settings/linked_assistants_sheet.dart
// MVVM — View only. Delegates fetchAssistants() to SettingsViewModel.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/settings_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/views/doctor/settings/settings_sheet_helpers.dart';

class LinkedAssistantsSheet extends ConsumerStatefulWidget {
  final UserProfile doctorProfile;

  const LinkedAssistantsSheet({required this.doctorProfile, Key? key})
      : super(key: key);

  static Future<void> show(BuildContext context, UserProfile profile) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => LinkedAssistantsSheet(doctorProfile: profile),
      );

  @override
  ConsumerState<LinkedAssistantsSheet> createState() =>
      _LinkedAssistantsSheetState();
}

class _LinkedAssistantsSheetState extends ConsumerState<LinkedAssistantsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsViewModelProvider.notifier).fetchAssistants(
            clinicName: widget.doctorProfile.clinicName ?? '',
            doctorId:   widget.doctorProfile.id,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsViewModelProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.35,
      builder: (_, sc) => Column(
        children: [
          const SizedBox(height: 16),
          sheetHandle(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: sheetTitle('Linked Assistants', Icons.people_outline),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: state.loadingAssistants
                ? const Center(
                    child: CircularProgressIndicator(
                        color: DoctorTheme.navy, strokeWidth: 2))
                : state.assistants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off_outlined,
                                size: 48,
                                color: DoctorTheme.textM.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text(
                              'No assistants linked to your account.',
                              style: TextStyle(
                                  color: DoctorTheme.textS, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: sc,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        itemCount: state.assistants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _AssistantTile(data: state.assistants[i]),
                      ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AssistantTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AssistantTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final fn       = (data['first_name'] ?? '').toString();
    final ln       = (data['last_name']  ?? '').toString();
    final name     = '$fn $ln'.trim().isEmpty ? 'Assistant' : '$fn $ln'.trim();
    final email    = (data['email'] ?? '').toString();
    final initials = fn.isNotEmpty
        ? (fn[0] + (ln.isNotEmpty ? ln[0] : '')).toUpperCase()
        : 'A';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: DoctorTheme.avatarBg(fn),
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DoctorTheme.textH)),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(
                        fontSize: 12, color: DoctorTheme.textS)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: DoctorTheme.successBg,
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Active',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: DoctorTheme.success)),
          ),
        ],
      ),
    );
  }
}
