// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_pat_card.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';

typedef _T = DoctorTheme;

class DoctorPatCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  const DoctorPatCard({
    required this.patient,
    required this.onTap,
    this.onEdit,
    Key? key,
  }) : super(key: key);

  String get _name =>
      '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim();

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

  @override
  Widget build(BuildContext context) {
    final gender = (patient['gender'] ?? '').toString().toUpperCase();
    final phone  = patient['phone'] ?? '';
    final age    = _age;
    final conds  = (patient['conditions'] as List?)?.cast<Map>() ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _T.card(),
        child: Row(
          children: [
            DoctorAvatar(name: _name, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.textH,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (age != null)
                        Text(
                          '$age yrs',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _T.textS,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (gender.isNotEmpty) ...[
                        Icon(
                          gender == 'MALE'
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          size: 13,
                          color: gender == 'MALE'
                              ? _T.navyLight
                              : const Color(0xFFAD1457),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          gender == 'MALE' ? 'Male' : 'Female',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _T.textS,
                          ),
                        ),
                        if (phone.isNotEmpty)
                          const Text(
                            '  •  ',
                            style: TextStyle(fontSize: 11, color: _T.textM),
                          ),
                      ],
                      if (phone.isNotEmpty)
                        Expanded(
                          child: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _T.textS,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  if (conds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: conds
                          .take(3)
                          .map(
                            (c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _T.urgentBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                c['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _T.urgent,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  Builder(
                    builder: (_) {
                      final diseases =
                          List<String>.from(patient['chronic_diseases'] ?? []);
                      if (diseases.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: diseases
                              .map(
                                (d) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E5F5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    d,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6A1B9A),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chevron_right_rounded, color: _T.textM),
                if (onEdit != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: _T.textM,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
