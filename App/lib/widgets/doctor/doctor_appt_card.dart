// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_appt_card.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';

typedef _T = DoctorTheme;

extension _StrExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class DoctorApptCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDetails;
  final VoidCallback? onCancel;

  const DoctorApptCard({
    required this.appt,
    required this.onStart,
    required this.onEdit,
    required this.onDetails,
    this.onCancel,
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
    final fn =
        appt['patient_first_name'] ?? appt['patient']?['first_name'] ?? '';
    final ln = appt['patient_last_name'] ?? appt['patient']?['last_name'] ?? '';
    return '$fn $ln'.trim().ifEmpty(loc.unknownPatient);
  }

  String _resolveType(dynamic raw, AppLocalizations loc) {
    String extracted;
    if (raw == null) {
      extracted = loc.consultationDefault;
    } else if (raw is Map) {
      extracted = (raw['name'] ?? raw['title'] ?? loc.consultationDefault)
          .toString();
    } else {
      final s = raw.toString().trim();
      extracted = s.isEmpty ? loc.consultationDefault : s;
    }
    return _localizeTypeName(extracted, loc);
  }

  String _localizeTypeName(String name, AppLocalizations loc) {
    switch (name.trim().toLowerCase()) {
      case 'initial consultation':
        return loc.initialConsultation;
      case 'consultation':
        return loc.visitTypeConsultation;
      case 'revisit':
      case 're-visit':
        return loc.visitTypeRevisit;
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final dt = _dt(appt['start_time']);
    final status = (appt['status'] ?? 'SCHEDULED').toUpperCase();
    final urgent = appt['is_urgent'] == true;
    final name = _name(loc);
    final type = _resolveType(
      appt['appointment_type_name'] ?? appt['appointment_type'],
      loc,
    );
    final phone = appt['patient_phone'] ?? appt['patient']?['phone'] ?? '';
    final fee = double.tryParse((appt['fee'] ?? 0).toString()) ?? 0.0;
    final isPaid = appt['is_paid'] == true;
    final canStart = status == 'SCHEDULED' || status == 'IN_PROGRESS';
    final canCancel =
        (status == 'SCHEDULED' || status == 'IN_PROGRESS') && onCancel != null;

    return Container(
      decoration: BoxDecoration(
        color: themeData.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgent ? _T.urgent.withOpacity(0.35) : themeData.divider,
          width: urgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (urgent ? _T.urgent : _T.navy).withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main row ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
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
                      dt != null
                          ? arDigits(
                              DateFormat('hh:mm', localeCode).format(dt),
                              localeCode,
                            )
                          : '--:--',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: themeData.accent,
                      ),
                    ),
                    Text(
                      dt != null ? DateFormat('a', localeCode).format(dt) : '',
                      style: TextStyle(
                        fontSize: 10,
                        color: themeData.textM,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 44, color: themeData.divider),
                const SizedBox(width: 12),
                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DoctorAvatar(name: name, size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: themeData.textH,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (phone.isNotEmpty)
                                  Directionality(
                                    textDirection: material.TextDirection.ltr,
                                    child: Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: themeData.textS,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          DoctorMiniChip(
                            icon: Icons.medical_services_outlined,
                            label: type,
                          ),
                          if (fee > 0)
                            DoctorMiniChip(
                              icon: Icons.payments_outlined,
                              label:
                                  '${arNumber(fee, localeCode)} ${loc.currencyEgp}',
                              color: isPaid ? _T.success : _T.warning,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    DoctorBadge(
                      label: _T.sLabel(status, loc),
                      fg: _T.sFg(status),
                      bg: _T.sBg(status),
                    ),
                    if (urgent) ...[
                      const SizedBox(height: 4),
                      DoctorBadge(
                        label: loc.urgentBadge,
                        fg: _T.urgent,
                        bg: _T.urgentBg,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // ── Action footer ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: themeData.bgInput,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                // Date — takes all remaining space and truncates gracefully
                Icon(
                  Icons.calendar_today_rounded,
                  size: 11,
                  color: themeData.textM,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dt != null
                        ? arDigits(
                            DateFormat('EEE, dd MMM', localeCode).format(dt),
                            localeCode,
                          )
                        : '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: themeData.textM,
                      letterSpacing: 0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Action buttons — fixed, never expand
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canStart) ...[
                      DoctorActBtn(
                        label: loc.actionStart,
                        icon: Icons.play_circle_rounded,
                        color: themeData.accentTeal,
                        onTap: onStart,
                      ),
                      _vDivider(themeData),
                    ],
                    DoctorActBtn(
                      label: loc.actionEdit,
                      icon: Icons.edit_rounded,
                      color: themeData.accent,
                      onTap: onEdit,
                    ),
                    _vDivider(themeData),
                    DoctorActBtn(
                      label: loc.actionDetails,
                      icon: Icons.person_outline_rounded,
                      color: themeData.accent,
                      onTap: onDetails,
                    ),
                    if (canCancel) ...[
                      _vDivider(themeData),
                      DoctorActBtn(
                        label: loc.cancel,
                        icon: Icons.cancel_outlined,
                        color: _T.urgent,
                        onTap: onCancel!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider(DoctorThemeData dt) => Container(
    width: 1,
    height: 12,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: dt.divider,
  );
}

// ── MiniChip ──────────────────────────────────────────────────────────────────

class DoctorMiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const DoctorMiniChip({
    required this.icon,
    required this.label,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context).extension<DoctorThemeData>()!;
    final c = color ?? themeData.textS;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: themeData.bgInput,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: c),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 10, color: c),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class DoctorActBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const DoctorActBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}
