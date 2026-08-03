// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/assistant/assistant_appt_card.dart
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

class AssistantApptCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final VoidCallback onTap;
  final bool highlight;
  final bool isNextPatient;

  const AssistantApptCard({
    required this.appt,
    required this.onTap,
    this.highlight = false,
    this.isNextPatient = false,
    super.key,
  });

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _name(AppLocalizations loc) {
    if (appt['patient_name'] != null) return appt['patient_name'].toString();
    final fn =
        appt['patient_first_name'] ?? appt['patient']?['first_name'] ?? '';
    final ln = appt['patient_last_name'] ?? appt['patient']?['last_name'] ?? '';
    final full = '$fn $ln'.trim();
    return full.isEmpty ? loc.unknownPatient : full;
  }

  String _resolveType(dynamic raw, AppLocalizations loc) {
    if (raw == null) return loc.consultationDefault;
    if (raw is Map) return (raw['name'] ?? loc.consultationDefault).toString();
    final s = raw.toString().trim();
    return s.isEmpty ? loc.consultationDefault : s;
  }

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context);
    final lc = Localizations.localeOf(context).languageCode;
    final dt = _dt(appt['start_time']);
    final status = _T.getDisplayStatus(appt);
    final urgent = appt['is_urgent'] == true;
    final isPaid = appt['is_paid'] == true;
    final fee = double.tryParse((appt['fee'] ?? 0).toString()) ?? 0.0;
    final type = _resolveType(
      appt['appointment_type_name'] ?? appt['appointment_type'],
      loc,
    );
    final name = _name(loc);

    final bool showNextPatient = isNextPatient && !highlight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: showNextPatient
              ? _T.infoBg.withValues(alpha: 0.35)
              : highlight
              ? _T.greenPale.withValues(alpha: 0.4)
              : at.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: showNextPatient
                ? _T.info.withValues(alpha: 0.6)
                : highlight
                ? _T.green.withValues(alpha: 0.5)
                : at.divider,
            width: (showNextPatient || highlight) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (showNextPatient ? _T.info : _T.green).withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Next Patient label ─────────────────────────────────────────
            if (showNextPatient)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _T.info.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_pin_circle_rounded, size: 13, color: _T.info),
                    const SizedBox(width: 5),
                    Text(
                      loc.nextPatientLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _T.info,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            // ── Main row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time column
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _T.sFg(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dt != null
                              ? arDigits(
                                  DateFormat('hh:mm', lc).format(dt),
                                  lc,
                                )
                              : '--:--',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _T.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          dt != null ? DateFormat('a', lc).format(dt) : '',
                          style: TextStyle(
                            fontSize: 10,
                            color: at.textM,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: at.divider,
                  ),
                  // Info section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Avatar(name: name, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: at.textH,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: at.textS,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: at.textM,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Badge(
                              label: _T.sLabel(status, loc),
                              fg: _T.sFg(status),
                              bg: _T.sBg(status),
                            ),
                            _Badge(
                              label: isPaid ? loc.paidBadge : loc.unpaidBadge,
                              fg: isPaid ? _T.success : _T.warning,
                              bg: isPaid ? _T.successBg : _T.warningBg,
                            ),
                            if (urgent)
                              _Badge(
                                label: loc.urgentBadge,
                                fg: _T.urgent,
                                bg: _T.urgentBg,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Footer ────────────────────────────────────────────────────
            if (fee > 0 || dt != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: at.bgInput,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    if (dt != null) ...[
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: at.textM,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          arDigits(
                            DateFormat('EEE, dd MMM yyyy', lc).format(dt),
                            lc,
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: at.textM,
                            letterSpacing: 0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (fee > 0)
                      Text(
                        '${arNumber(fee, lc)} ${loc.currencyEgp}',
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
