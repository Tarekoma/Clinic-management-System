// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/assistant/assistant_appt_card.dart
//
// Extracted from the original _ApptCard private class.
// Visual code is 100% identical to the original.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'assistant_shared_widgets.dart';

typedef _T = AssistantTheme;

// Local private aliases that map the original private widget names
// to the new public names — keeps every reference inside build() identical.
typedef _Avatar = AssistantAvatar;
typedef _Badge = AssistantBadge;

class AssistantApptCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final VoidCallback onTap;
  final bool highlight;

  const AssistantApptCard({
    required this.appt,
    required this.onTap,
    this.highlight = false,
    Key? key,
  }) : super(key: key);

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String get _name {
    if (appt['patient_name'] != null) return appt['patient_name'].toString();
    final fn =
        appt['patient_first_name'] ?? appt['patient']?['first_name'] ?? '';
    final ln = appt['patient_last_name'] ?? appt['patient']?['last_name'] ?? '';
    final full = '$fn $ln'.trim();
    return full.isEmpty ? 'Unknown Patient' : full;
  }

  @override
  Widget build(BuildContext context) {
    final dt = _dt(appt['start_time']);
    final status = (appt['status'] ?? 'SCHEDULED').toUpperCase();
    final urgent = appt['is_urgent'] == true;
    final isPaid = appt['is_paid'] == true;
    final fee = double.tryParse((appt['fee'] ?? 0).toString()) ?? 0.0;
    final type =
        (appt['appointment_type'] as Map?)?['name'] ??
        appt['appointment_type_name'] ??
        'Consultation';
    final reason = (appt['reason'] ?? '').toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _T.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: urgent
                ? _T.urgent.withOpacity(0.4)
                : highlight
                ? _T.green.withOpacity(0.5)
                : _T.divider,
            width: (urgent || highlight) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (urgent ? _T.urgent : _T.green).withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Main row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Time column
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: urgent ? _T.urgent : _T.sFg(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dt != null ? DateFormat('hh:mm').format(dt) : '--:--',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _T.green,
                        ),
                      ),
                      Text(
                        dt != null ? DateFormat('a').format(dt) : '',
                        style: const TextStyle(
                          fontSize: 10,
                          color: _T.textM,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 52, color: _T.divider),
                  const SizedBox(width: 12),
                  // Info section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Avatar(name: _name, size: 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _T.textH,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    type,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _T.textS,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Badge(
                              label: _T.sLabel(status),
                              fg: _T.sFg(status),
                              bg: _T.sBg(status),
                            ),
                            _Badge(
                              label: isPaid ? 'PAID' : 'UNPAID',
                              fg: isPaid ? _T.success : _T.warning,
                              bg: isPaid ? _T.successBg : _T.warningBg,
                            ),
                            if (urgent)
                              const _Badge(
                                label: 'URGENT',
                                fg: _T.urgent,
                                bg: _T.urgentBg,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _T.textM,
                    size: 20,
                  ),
                ],
              ),
            ),
            // ── Footer ────────────────────────────────────────────────────
            if (fee > 0 || dt != null || reason.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: _T.bgInput,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    if (dt != null) ...[
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: _T.textM,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('EEE, dd MMM yyyy').format(dt),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _T.textM,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (fee > 0)
                      Text(
                        '${fee.toStringAsFixed(0)} EGP',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _T.green,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
