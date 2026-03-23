// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_consultation_widgets.dart
//
// DoctorConsultCard, DoctorSympChip, DoctorRxItem, DoctorImgBtn,
// DoctorFinChip — all consultation-specific sub-widgets.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

// ── Section card ──────────────────────────────────────────────────────────────

class DoctorConsultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const DoctorConsultCard({
    required this.title,
    required this.icon,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: _T.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: _T.navy),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _T.textH,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

// ── Symptom chip ──────────────────────────────────────────────────────────────

class DoctorSympChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const DoctorSympChip({required this.label, required this.onRemove, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _T.infoBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.info.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _T.info,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded, size: 14, color: _T.info),
            ),
          ],
        ),
      );
}

// ── Prescription item ─────────────────────────────────────────────────────────

class DoctorRxItem extends StatelessWidget {
  final int index;
  final Map<String, String> med;
  final VoidCallback onRemove;
  const DoctorRxItem({
    required this.index,
    required this.med,
    required this.onRemove,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: _T.card(r: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: _T.tealPale, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.teal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _T.textH,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [med['dose'], med['frequency'], med['duration']]
                        .where((s) => s != null && s.isNotEmpty)
                        .join('  •  '),
                    style: const TextStyle(fontSize: 11, color: _T.textS),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: _T.urgent, size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
      );
}

// ── Image pick button ─────────────────────────────────────────────────────────

class DoctorImgBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const DoctorImgBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _T.bgInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.divider),
            ),
            child: Column(
              children: [
                Icon(icon, color: _T.navy, size: 24),
                const SizedBox(height: 6),
                Text(label,
                    style: const TextStyle(fontSize: 12, color: _T.textS)),
              ],
            ),
          ),
        ),
      );
}

// ── Finance chip ──────────────────────────────────────────────────────────────

class DoctorFinChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const DoctorFinChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
