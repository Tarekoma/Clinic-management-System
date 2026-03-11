// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_profile_page.dart
//
// Pure display page — no API calls, no ViewModel dependency.
// Pushed as a full-screen route from both the shell top-bar avatar tap
// and the dashboard greeting card tap.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';

typedef _T = DoctorTheme;

extension _StrX on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

// ─────────────────────────────────────────────────────────────────────────────

class DoctorProfilePage extends StatelessWidget {
  final UserProfile doctorProfile;
  const DoctorProfilePage({required this.doctorProfile, Key? key})
    : super(key: key);

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(DateTime? d) {
    if (d == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(d);
  }

  int? get _age {
    if (doctorProfile.birthDate == null) return null;
    return ((DateTime.now().difference(doctorProfile.birthDate!).inDays) /
            365.25)
        .floor();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name = doctorProfile.fullName.ifEmpty(doctorProfile.username);

    return Scaffold(
      backgroundColor: _T.bgPage,
      body: Column(
        children: [
          // ── Gradient header ────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(gradient: _T.gNavy),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Back-button row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'My Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar + name + badges
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    child: Row(
                      children: [
                        // Avatar with white-ring border
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: DoctorAvatar(name: name, size: 72),
                        ),
                        const SizedBox(width: 18),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. $name',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if ((doctorProfile.clinicName ?? '')
                                      .isNotEmpty)
                                    _ProfileBadge(
                                      icon: Icons.local_hospital_rounded,
                                      label: doctorProfile.clinicName!,
                                    ),
                                  _ProfileBadge(
                                    icon: Icons.medical_services_rounded,
                                    label:
                                        doctorProfile.specialization ??
                                        'Doctor',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Personal information card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: _T.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: _T.navy,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _T.textH,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: _T.divider),
                        const SizedBox(height: 14),
                        _ProfileRow('Full Name', 'Dr. $name'),
                        _ProfileRow('Email', doctorProfile.email),
                        _ProfileRow(
                          'Gender',
                          doctorProfile.gender.isEmpty
                              ? 'N/A'
                              : doctorProfile.gender[0].toUpperCase() +
                                    doctorProfile.gender.substring(1),
                        ),
                        _ProfileRow(
                          'Date of Birth',
                          doctorProfile.birthDate != null
                              ? _fmt(doctorProfile.birthDate)
                              : 'N/A',
                        ),
                        if (_age != null) _ProfileRow('Age', '$_age years'),
                        _ProfileRow('Role', 'Doctor'),
                        _ProfileRow(
                          'Clinic',
                          doctorProfile.clinicName ?? 'N/A',
                        ),
                        _ProfileRow(
                          'Specialization',
                          doctorProfile.specialization ?? 'N/A',
                        ),
                        if ((doctorProfile.licenseNumber ?? '').isNotEmpty)
                          _ProfileRow(
                            'License No.',
                            doctorProfile.licenseNumber!,
                          ),
                        _ProfileRow('Joined', _fmt(doctorProfile.createdAt)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets  (scoped to this file)
// ─────────────────────────────────────────────────────────────────────────────

/// Small pill badge used in the gradient header (clinic name, specialization).
class _ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ProfileBadge({required this.icon, required this.label, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white),
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

/// Label + value row inside the info card.
class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _T.textS,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _T.textH,
            ),
          ),
        ),
      ],
    ),
  );
}
