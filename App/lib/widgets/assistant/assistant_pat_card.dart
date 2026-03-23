// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/assistant/assistant_pat_card.dart
//
// Extracted from the original _PatCard private class.
// Visual code 100% identical to original.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'assistant_shared_widgets.dart';

typedef _T      = AssistantTheme;
typedef _Avatar = AssistantAvatar;

class AssistantPatCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap, onEdit, onDelete;

  const AssistantPatCard({
    required this.patient,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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

  PopupMenuItem<String> _menuItem(
          IconData icon, String label, Color color) =>
      PopupMenuItem<String>(
        value: label,
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
    final gender  = (patient['gender'] ?? '').toString().toUpperCase();
    final phone   = patient['phone'] ?? '';
    final age     = _age;
    final conds   = (patient['conditions'] as List?)
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
        decoration: _T.card(),
        child: Row(
          children: [
            _Avatar(name: _name, size: 48),
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
                          gender == 'MALE' ? 'Male' : 'Female',
                          style:
                              const TextStyle(fontSize: 11, color: _T.textS),
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
                            style:
                                const TextStyle(fontSize: 11, color: _T.textS),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  // Chronic conditions
                  if (conds.isNotEmpty ||
                      chronic.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (conds.isNotEmpty
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
                _menuItem(Icons.info_outline_rounded, 'View', _T.info),
                _menuItem(Icons.edit_rounded, 'Edit', _T.green),
                _menuItem(
                    Icons.delete_outline_rounded, 'Delete', _T.urgent),
              ],
              onSelected: (v) {
                if (v == 'View') onTap();
                if (v == 'Edit') onEdit();
                if (v == 'Delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
