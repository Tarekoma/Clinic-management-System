// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_dashboard.dart
//
// Refactored from _buildProfile() in the original monolith.
// Architecture change only — visual output identical.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/widgets/assistant/assistant_shared_widgets.dart';

typedef _T = AssistantTheme;

class AssistantDashboard extends ConsumerWidget {
  final UserProfile profile;
  final Future<void> Function() onRefresh;

  const AssistantDashboard({
    required this.profile,
    required this.onRefresh,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final state = ref.watch(assistantViewModelProvider);
    final clinic = profile.clinicName ?? '';
    final loc = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _T.green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Hero banner ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: _T.gradCard(),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.welcomeBack,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.firstName.isEmpty
                              ? profile.fullName
                              : profile.firstName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _infoPill(
                              Icons.local_hospital_outlined,
                              clinic.isEmpty ? loc.noClinic : clinic,
                            ),
                            const SizedBox(width: 8),
                            _infoPill(
                              Icons.badge_rounded,
                              loc.assistantRoleLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile.fullName.isNotEmpty
                            ? profile.fullName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Quick stats ───────────────────────────────────────────────
            Row(
              children: [
                AssistantStatCard(
                  icon: Icons.calendar_month_rounded,
                  label: loc.appointments,
                  value: arDigits('${state.appointments.length}', lc),
                  color: _T.green,
                  bg: _T.greenPale,
                ),
                const SizedBox(width: 12),
                AssistantStatCard(
                  icon: Icons.people_alt_rounded,
                  label: loc.patients,
                  value: arDigits('${state.patients.length}', lc),
                  color: _T.emerald,
                  bg: const Color(0xFFE8F5E9),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Personal info card ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AssistantTheme.cardOf(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_rounded, size: 16, color: _T.green),
                      SizedBox(width: 8),
                      Text(
                        loc.personalInformation,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: at.textH,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AssistantIRow(loc.fullNameLabel, profile.fullName),
                  AssistantIRow(loc.emailLabel, profile.email),
                  AssistantIRow(
                    loc.genderLabel,
                    profile.gender.isEmpty ? loc.notAvailable : profile.gender,
                  ),
                  AssistantIRow(
                    loc.roleLabel,
                    profile.userType.isEmpty
                        ? loc.assistantRoleLabel
                        : profile.userType,
                  ),
                  AssistantIRow(
                    loc.clinicLabel,
                    clinic.isEmpty ? loc.notAvailable : clinic,
                  ),
                  if (profile.birthDate != null)
                    AssistantIRow(
                      loc.dateOfBirthLabel,
                      arDigits(
                        DateFormat(
                          'dd MMM yyyy',
                          lc,
                        ).format(profile.birthDate!),
                        lc,
                      ),
                    ),
                  AssistantIRow(
                    loc.joinedLabel,
                    arDigits(
                      DateFormat('dd MMM yyyy', lc).format(profile.createdAt),
                      lc,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white70),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
