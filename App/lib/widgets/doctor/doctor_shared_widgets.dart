// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_shared_widgets.dart
//
// Shared micro-widgets: DoctorAvatar, DoctorBadge, DoctorSecHead,
// DoctorEmpty, DoctorStatCard.
// Each file that uses these keeps `typedef _T = DoctorTheme;` so
// internal references compile unchanged.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/utils/doctor_theme.dart';

// Allow files that import this to keep using _T.xxx references unchanged.
typedef _T = DoctorTheme;

// ── Avatar ────────────────────────────────────────────────────────────────────

class DoctorAvatar extends StatelessWidget {
  final String name;
  final double size;
  const DoctorAvatar({required this.name, this.size = 44, Key? key})
      : super(key: key);

  String get _init {
    final p = name.trim().split(' ');
    if (p.isEmpty) return '?';
    if (p.length == 1) return p[0].isEmpty ? '?' : p[0][0].toUpperCase();
    return '${p[0][0]}${p.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _T.avatarBg(name),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _init,
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class DoctorBadge extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const DoctorBadge({
    required this.label,
    required this.fg,
    required this.bg,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.3,
          ),
        ),
      );
}

// ── Section Header ────────────────────────────────────────────────────────────

class DoctorSecHead extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const DoctorSecHead({
    required this.title,
    this.action,
    this.onAction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _T.textH,
            ),
          ),
          const Spacer(),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _T.navy,
                ),
              ),
            ),
        ],
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class DoctorEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  const DoctorEmpty({
    required this.icon,
    required this.title,
    this.sub,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: _T.bgInput,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 38, color: _T.textM),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _T.textS,
                ),
              ),
              if (sub != null) ...[
                const SizedBox(height: 6),
                Text(
                  sub!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _T.textM),
                ),
              ],
            ],
          ),
        ),
      );
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class DoctorStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? sub;
  final Color color, bg;
  const DoctorStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    required this.color,
    required this.bg,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _T.card(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: _T.textS),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _T.textM,
                        letterSpacing: 0.4,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}
