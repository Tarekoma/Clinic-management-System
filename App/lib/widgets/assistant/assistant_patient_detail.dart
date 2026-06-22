// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/assistant/assistant_patient_detail.dart
//
// Extracted from the original _PatientDetailPage.
// Visual code 100% identical to original.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'assistant_shared_widgets.dart';

typedef _T = AssistantTheme;
typedef _Avatar = AssistantAvatar;
typedef _Badge = AssistantBadge;
typedef _SectionHead = AssistantSectionHead;

class AssistantPatientDetail extends StatelessWidget {
  final Map<String, dynamic> patient;
  final List<Map<String, dynamic>> appointments;
  final VoidCallback onEdit;

  const AssistantPatientDetail({
    required this.patient,
    required this.appointments,
    required this.onEdit,
    Key? key,
  }) : super(key: key);

  String get _name =>
      '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim();

  // ignore: unused_element
  int? get _age {
    final dob = patient['birth_date'] ?? patient['date_of_birth'];
    if (dob == null) return null;
    try {
      return ((DateTime.now()
                  .difference(DateTime.parse(dob.toString()))
                  .inDays) /
              365.25)
          .floor();
    } catch (_) {
      return null;
    }
  }

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _appts {
    final pid = (patient['id'] ?? '').toString();
    return appointments
        .where(
          (a) =>
              (a['patient_id'] ?? a['patient']?['id'] ?? '').toString() == pid,
        )
        .toList()
      ..sort(
        (a, b) => (_dt(b['start_time']) ?? DateTime.now()).compareTo(
          _dt(a['start_time']) ?? DateTime.now(),
        ),
      );
  }

  String get _conditionsText {
    final list =
        (patient['conditions'] as List?)
            ?.map(
              (c) =>
                  (c['condition'] as Map? ?? {})['name']?.toString() ??
                  (c['name']?.toString() ?? ''),
            )
            .where((s) => s.isNotEmpty)
            .join(', ') ??
        '';
    if (list.isNotEmpty) return list;
    return (patient['chronic_disease'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;
    final age = _age;
    final gender = (patient['gender'] ?? '').toString().toUpperCase();
    final hasChronic = _conditionsText.isNotEmpty;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: at.bgPage,
        body: Column(
          children: [
            // ── Gradient header ───────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(gradient: _T.gGreen),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      _Avatar(name: _name, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (age != null)
                                  arDigits(loc.yearsCount(age), lc),
                                if (gender.isNotEmpty)
                                  gender == 'MALE' ? loc.male : loc.female,
                                if ((patient['phone'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  patient['phone'],
                              ].join('  •  '),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                            if (hasChronic) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _T.urgent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  loc.chronicConditionBadge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    _InfoCard(
                      icon: Icons.badge_rounded,
                      title: loc.patientInformation,
                      color: _T.green,
                      rows: [
                        _patRow(
                          context,
                          Icons.badge_outlined,
                          loc.idLabel,
                          patient['id'].toString(),
                        ),
                        _patRow(
                          context,
                          Icons.phone_rounded,
                          loc.phoneLabel,
                          patient['phone'] ?? loc.notAvailable,
                        ),
                        _patRow(
                          context,
                          Icons.email_rounded,
                          loc.emailLabel,
                          patient['email'] ?? loc.notAvailable,
                        ),
                        _patRow(
                          context,
                          Icons.wc_rounded,
                          loc.genderLabel,
                          patient['gender'] ?? loc.notAvailable,
                        ),
                        _patRow(
                          context,
                          Icons.cake_rounded,
                          loc.dateOfBirthLabel,
                          patient['date_of_birth'] ??
                              patient['birth_date'] ??
                              loc.notAvailable,
                        ),
                        _patRow(
                          context,
                          Icons.location_on_outlined,
                          loc.addressLabel,
                          patient['address'] ?? loc.notAvailable,
                        ),
                        _patRow(
                          context,
                          Icons.fingerprint_rounded,
                          loc.nationalIdLabel,
                          patient['national_id'] ?? loc.notAvailable,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Conditions card
                    if (hasChronic) ...[
                      _InfoCard(
                        icon: Icons.local_hospital_outlined,
                        title: loc.chronicConditionsTitle,
                        color: _T.urgent,
                        rows: [
                          _patRow(
                            context,
                            Icons.warning_amber_rounded,
                            loc.conditionsLabel,
                            _conditionsText,
                            isWarning: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Appointments section
                    _SectionHead(
                      title: loc.appointmentsCountTitle(
                        arDigits('${_appts.length}', lc),
                      ),
                    ),
                    if (_appts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AssistantTheme.cardOf(context),
                        child: Center(
                          child: Text(
                            loc.noAppointmentsFound,
                            style: TextStyle(fontSize: 12, color: at.textS),
                          ),
                        ),
                      )
                    else
                      ..._appts.take(5).map((a) {
                        final dt = _dt(a['start_time']);
                        final status = (a['status'] ?? '').toUpperCase();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: AssistantTheme.cardOf(context, r: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: _T.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dt != null
                                      ? arDigits(
                                          DateFormat(
                                            'dd MMM yyyy  •  hh:mm a',
                                            lc,
                                          ).format(dt),
                                          lc,
                                        )
                                      : loc.unknownDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: at.textS,
                                  ),
                                ),
                              ),
                              _Badge(
                                label: _T.sLabel(status, loc),
                                fg: _T.sFg(status),
                                bg: _T.sBg(status),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isWarning = false,
  }) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isWarning ? _T.urgent : at.textM),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 12, color: at.textS)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? loc.notAvailable : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isWarning ? _T.urgent : at.textH,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card (local to this file — matches original _InfoCard) ───────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> rows;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.rows,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AssistantTheme.cardOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: at.divider),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}
