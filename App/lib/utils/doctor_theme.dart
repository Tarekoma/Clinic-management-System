// ─────────────────────────────────────────────────────────────────────────────
// lib/utils/doctor_theme.dart
//
// All design tokens, colour helpers, decoration factories and
// input decoration for the Doctor module.
//
// Every view and widget file includes:
//   typedef _T = DoctorTheme;
// so existing references (_T.navy, _T.card(), …) compile unchanged.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class DoctorTheme {
  DoctorTheme._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color navy      = Color(0xFF0B3D6B);
  static const Color navyDeep  = Color(0xFF071E34);
  static const Color navyLight = Color(0xFF1565C0);
  static const Color teal      = Color(0xFF00796B);
  static const Color tealLight = Color(0xFF26A69A);
  static const Color tealPale  = Color(0xFFE0F2F1);

  // ── Surface ────────────────────────────────────────────────────────────────
  static const Color bgPage  = Color(0xFFF0F4F8);
  static const Color bgCard  = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFF5F7FA);
  static const Color divider = Color(0xFFE4EAF1);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color urgent    = Color(0xFFD32F2F);
  static const Color urgentBg  = Color(0xFFFDEDED);
  static const Color success   = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning   = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color info      = Color(0xFF1565C0);
  static const Color infoBg    = Color(0xFFE3F2FD);
  static const Color muted     = Color(0xFF78909C);
  static const Color mutedBg   = Color(0xFFF5F5F5);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textH = Color(0xFF0D1B2A);
  static const Color textS = Color(0xFF546E7A);
  static const Color textM = Color(0xFF90A4AE);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient gNavy = LinearGradient(
    colors: [Color(0xFF071E34), Color(0xFF0B3D6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gTeal = LinearGradient(
    colors: [Color(0xFF004D40), Color(0xFF00796B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gUrgent = LinearGradient(
    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Status helpers ─────────────────────────────────────────────────────────
  static Color sFg(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':   return info;
      case 'IN_PROGRESS': return teal;
      case 'COMPLETED':   return success;
      case 'CANCELLED':   return muted;
      default:            return textS;
    }
  }

  static Color sBg(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':   return infoBg;
      case 'IN_PROGRESS': return tealPale;
      case 'COMPLETED':   return successBg;
      case 'CANCELLED':   return mutedBg;
      default:            return mutedBg;
    }
  }

  static String sLabel(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':   return 'Scheduled';
      case 'IN_PROGRESS': return 'In Progress';
      case 'COMPLETED':   return 'Completed';
      case 'CANCELLED':   return 'Cancelled';
      default:            return s;
    }
  }

  // ── Decorations ────────────────────────────────────────────────────────────
  static BoxDecoration card({double r = 16, Color? bg}) => BoxDecoration(
    color: bg ?? bgCard,
    borderRadius: BorderRadius.circular(r),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0B3D6B).withOpacity(0.07),
        blurRadius: 18,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration gradCard({
    LinearGradient g = gNavy,
    double r = 18,
  }) =>
      BoxDecoration(
        gradient: g,
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D6B).withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // ── Input decoration ───────────────────────────────────────────────────────
  static InputDecoration inp(
    String label, {
    String? hint,
    Widget? pre,
    Widget? suf,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: pre,
        suffixIcon: suf,
        filled: true,
        fillColor: bgInput,
        labelStyle: const TextStyle(fontSize: 13, color: textS),
        hintStyle:  const TextStyle(fontSize: 13, color: textM),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navy, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  // ── Avatar colour bucket ───────────────────────────────────────────────────
  static final _ac = [
    const Color(0xFF1565C0),
    const Color(0xFF00796B),
    const Color(0xFF6A1B9A),
    const Color(0xFFAD1457),
    const Color(0xFF0277BD),
    const Color(0xFF558B2F),
    const Color(0xFF4E342E),
    const Color(0xFF00838F),
  ];

  static Color avatarBg(String name) =>
      name.isEmpty ? _ac[0] : _ac[name.codeUnitAt(0) % _ac.length];
}
