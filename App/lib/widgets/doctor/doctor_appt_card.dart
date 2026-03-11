// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_appt_card.dart
//
// DoctorApptCard, DoctorMiniChip, DoctorActBtn
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';

typedef _T = DoctorTheme;

extension _StrExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class DoctorApptCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final VoidCallback onStart, onEdit, onDelete;
  final void Function(String) onStatus;

  const DoctorApptCard({
    required this.appt,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
    required this.onStatus,
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
    final fn = appt['patient_first_name'] ?? appt['patient']?['first_name'] ?? '';
    final ln = appt['patient_last_name']  ?? appt['patient']?['last_name']  ?? '';
    return '$fn $ln'.trim().ifEmpty('Unknown Patient');
  }

  @override
  Widget build(BuildContext context) {
    final dt     = _dt(appt['start_time']);
    final status = (appt['status'] ?? 'SCHEDULED').toUpperCase();
    final urgent = appt['is_urgent'] == true;
    final type   = appt['appointment_type_name'] ?? appt['appointment_type'] ?? 'Consultation';
    final phone  = appt['patient_phone'] ?? appt['patient']?['phone'] ?? '';
    final fee    = double.tryParse((appt['fee'] ?? 0).toString()) ?? 0.0;
    final isPaid = appt['is_paid'] == true;
    final canStart = status == 'SCHEDULED' || status == 'IN_PROGRESS';

    return Container(
      decoration: BoxDecoration(
        color: _T.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent ? _T.urgent.withOpacity(0.35) : _T.divider,
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
          // ── Main row ──────────────────────────────────────────────────────
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
                        color: _T.navy,
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
                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DoctorAvatar(name: _name, size: 36),
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
                                if (phone.isNotEmpty)
                                  Text(
                                    phone,
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
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          DoctorMiniChip(
                            icon: Icons.medical_services_outlined,
                            label: type,
                          ),
                          if (fee > 0) ...[
                            const SizedBox(width: 6),
                            DoctorMiniChip(
                              icon: Icons.payments_outlined,
                              label: '${fee.toStringAsFixed(0)} EGP',
                              color: isPaid ? _T.success : _T.warning,
                            ),
                          ],
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
                      label: _T.sLabel(status),
                      fg: _T.sFg(status),
                      bg: _T.sBg(status),
                    ),
                    if (urgent) ...[
                      const SizedBox(height: 4),
                      const DoctorBadge(
                        label: 'URGENT',
                        fg: _T.urgent,
                        bg: _T.urgentBg,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // ── Action row ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: _T.bgInput,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                if (dt != null) ...[
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: _T.textM,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      DateFormat('EEE, dd MMM yyyy').format(dt),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _T.textM,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (canStart)
                      DoctorActBtn(
                        label: 'Start',
                        icon: Icons.play_circle_rounded,
                        color: _T.teal,
                        onTap: onStart,
                      ),
                    DoctorActBtn(
                      label: 'Edit',
                      icon: Icons.edit_rounded,
                      color: _T.navyLight,
                      onTap: onEdit,
                    ),
                    if (status == 'SCHEDULED')
                      DoctorActBtn(
                        label: 'Done',
                        icon: Icons.check_circle_outline_rounded,
                        color: _T.success,
                        onTap: () => onStatus('COMPLETED'),
                      ),
                    DoctorActBtn(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      color: _T.urgent,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── MiniChip ──────────────────────────────────────────────────────────────────

class DoctorMiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const DoctorMiniChip({
    required this.icon,
    required this.label,
    this.color = _T.textS,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: _T.bgInput,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      );
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
}
