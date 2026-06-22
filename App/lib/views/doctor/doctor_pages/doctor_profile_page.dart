// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_profile_page.dart
//
// Pure display page — no API calls, no ViewModel dependency.
// Pushed as a full-screen route from both the shell top-bar avatar tap
// and the dashboard greeting card tap.
// Localized via AppLocalizations.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_edit_profile_page.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';

typedef _T = DoctorTheme;

extension _StrX on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

// ─────────────────────────────────────────────────────────────────────────────

class DoctorProfilePage extends StatefulWidget {
  final UserProfile doctorProfile;
  const DoctorProfilePage({required this.doctorProfile, Key? key})
    : super(key: key);

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  late UserProfile _current;

  @override
  void initState() {
    super.initState();
    _current = widget.doctorProfile;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(DateTime? d, String na) {
    if (d == null) return na;
    return DateFormat('dd MMM yyyy').format(d);
  }

  int? get _age {
    if (_current.birthDate == null) return null;
    return ((DateTime.now().difference(_current.birthDate!).inDays) / 365.25)
        .floor();
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorEditProfilePage(profile: _current),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _current = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).profileUpdatedSuccess),
          backgroundColor: _T.teal,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);
    final name = _current.fullName.ifEmpty(_current.username);
    final na = loc.notAvailable;

    return Scaffold(
      backgroundColor: dt.bgPage,
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
                        Expanded(
                          child: Text(
                            loc.myProfile,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white70,
                          ),
                          tooltip: loc.editProfile,
                          onPressed: _openEdit,
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
                              color: Colors.white.withValues(alpha: 0.3),
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
                                  if ((_current.clinicName ?? '').isNotEmpty)
                                    _ProfileBadge(
                                      icon: Icons.local_hospital_rounded,
                                      label: _current.clinicName!,
                                    ),
                                  _ProfileBadge(
                                    icon: Icons.medical_services_rounded,
                                    label:
                                        _current.specialization ??
                                        loc.doctorRole,
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
                    decoration: _T.cardOf(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: _T.navy,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              loc.personalInformation,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: dt.textH,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(height: 1, color: dt.divider),
                        const SizedBox(height: 14),
                        _ProfileRow(loc.fullNameLabel, 'Dr. $name'),
                        _ProfileRow(loc.emailLabel, _current.email),
                        _ProfileRow(
                          loc.genderLabel,
                          _current.gender.isEmpty
                              ? na
                              : _current.gender[0].toUpperCase() +
                                    _current.gender.substring(1),
                        ),
                        _ProfileRow(
                          loc.dateOfBirthLabel,
                          _current.birthDate != null
                              ? _fmt(_current.birthDate, na)
                              : na,
                        ),
                        if (_age != null)
                          _ProfileRow(loc.ageLabel, loc.yearsCount(_age!)),
                        _ProfileRow(loc.roleLabel, loc.doctorRole),
                        _ProfileRow(
                          loc.clinicLabel,
                          _current.clinicName ?? na,
                        ),
                        _ProfileRow(
                          loc.specializationLabel,
                          _current.specialization ?? na,
                        ),
                        if ((_current.licenseNumber ?? '').isNotEmpty)
                          _ProfileRow(
                            loc.licenseNoLabel,
                            _current.licenseNumber!,
                          ),
                        _ProfileRow(
                          loc.joinedLabel,
                          _fmt(_current.createdAt, na),
                        ),
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
      color: Colors.white.withValues(alpha: 0.15),
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
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: dt.textS,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? loc.notAvailable : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dt.textH,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
