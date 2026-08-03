// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/assistant/assistant_pat_card.dart
//
// Extracted from the original _PatCard private class.
// Visual code 100% identical to original.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'assistant_shared_widgets.dart';

typedef _T = AssistantTheme;
typedef _Avatar = AssistantAvatar;

class AssistantPatCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap, onEdit;

  const AssistantPatCard({
    required this.patient,
    required this.onTap,
    required this.onEdit,
    Key? key,
  }) : super(key: key);

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

  PopupMenuItem<String> _menuItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) => PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;
    final name = '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'
        .trim();
    final gender = (patient['gender'] ?? '').toString().toUpperCase();
    final phone = patient['phone'] ?? '';
    final age = _age;
    final conds =
        (patient['conditions'] as List?)
            ?.map(
              (c) =>
                  (c['condition'] as Map? ?? {})['name']?.toString() ??
                  (c['name']?.toString() ?? ''),
            )
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    final chronic = patient['chronic_disease'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AssistantTheme.cardOf(context),
        child: Row(
          children: [
            _Avatar(name: name, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: at.textH,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (age != null)
                        Text(
                          arDigits(loc.yearsCount(age), lc),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: at.textS,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Gender / phone
                  Row(
                    children: [
                      if (gender.isNotEmpty) ...[
                        Icon(
                          gender == 'MALE'
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          size: 13,
                          color: gender == 'MALE'
                              ? _T.info
                              : const Color(0xFFAD1457),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          gender == 'MALE' ? loc.male : loc.female,
                          style: TextStyle(fontSize: 11, color: at.textS),
                        ),
                        if (phone.isNotEmpty)
                          Text(
                            '  •  ',
                            style: TextStyle(fontSize: 11, color: at.textM),
                          ),
                      ],
                      if (phone.isNotEmpty)
                        Expanded(
                          child: Text(
                            phone,
                            style: TextStyle(fontSize: 11, color: at.textS),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  // Chronic conditions
                  if (conds.isNotEmpty || chronic.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children:
                          (conds.isNotEmpty
                                  ? conds.take(3)
                                  : [chronic.toString()])
                              .map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _T.urgentBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    c,
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (_) => [
                _menuItem(
                  Icons.info_outline_rounded,
                  'view',
                  loc.actionDetails,
                  _T.info,
                ),
                _menuItem(Icons.edit_rounded, 'edit', loc.actionEdit, _T.green),
              ],
              onSelected: (v) {
                if (v == 'view') onTap();
                if (v == 'edit') onEdit();
              },
            ),
          ],
        ),
      ),
    );
  }
}
