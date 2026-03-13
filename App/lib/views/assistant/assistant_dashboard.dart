// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_dashboard.dart
//
// Refactored from _buildProfile() in the original monolith.
// Architecture change only — visual output identical.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/assistant_providers.dart';
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
    final state = ref.watch(assistantViewModelProvider);
    final clinic = profile.clinicName ?? '';

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
                          'Welcome back,',
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
                              clinic.isEmpty ? 'No Clinic' : clinic,
                            ),
                            const SizedBox(width: 8),
                            _infoPill(Icons.badge_rounded, 'Assistant'),
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
                  label: 'Appointments',
                  value: '${state.appointments.length}',
                  color: _T.green,
                  bg: _T.greenPale,
                ),
                const SizedBox(width: 12),
                AssistantStatCard(
                  icon: Icons.people_alt_rounded,
                  label: 'Patients',
                  value: '${state.patients.length}',
                  color: _T.emerald,
                  bg: const Color(0xFFE8F5E9),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Personal info card ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _T.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_rounded, size: 16, color: _T.green),
                      SizedBox(width: 8),
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _T.textH,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AssistantIRow('Full Name', profile.fullName),
                  AssistantIRow('Email', profile.email),
                  AssistantIRow(
                    'Gender',
                    profile.gender.isEmpty ? 'N/A' : profile.gender,
                  ),
                  AssistantIRow(
                    'Role',
                    profile.userType.isEmpty ? 'Assistant' : profile.userType,
                  ),
                  AssistantIRow('Clinic', clinic.isEmpty ? 'N/A' : clinic),
                  if (profile.birthDate != null)
                    AssistantIRow(
                      'Birth Date',
                      DateFormat('dd MMM yyyy').format(profile.birthDate!),
                    ),
                  AssistantIRow(
                    'Joined',
                    DateFormat('dd MMM yyyy').format(profile.createdAt),
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
