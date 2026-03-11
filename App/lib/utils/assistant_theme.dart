// ─────────────────────────────────────────────────────────────────────────────
// lib/utils/assistant_theme.dart
//
// Public version of the private _T class that was buried inside
// Assistant_Interface.dart.  Every assistant view/widget file imports this
// and adds:
//
//   typedef _T = AssistantTheme;
//
// so that ALL original widget code compiles without a single character change.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AssistantTheme {
  AssistantTheme._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color green       = Color(0xFF00695C);
  static const Color greenDeep   = Color(0xFF004D40);
  static const Color greenLight  = Color(0xFF26A69A);
  static const Color greenPale   = Color(0xFFE0F2F1);
  static const Color emerald     = Color(0xFF43A047);

  // ── Surface ───────────────────────────────────────────────────────────────
  static const Color bgPage  = Color(0xFFF0F7F5);
  static const Color bgCard  = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFF5F9F8);
  static const Color divider = Color(0xFFDCEDE9);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color urgent      = Color(0xFFD32F2F);
  static const Color urgentBg    = Color(0xFFFDEDED);
  static const Color success     = Color(0xFF2E7D32);
  static const Color successBg   = Color(0xFFE8F5E9);
  static const Color warning     = Color(0xFFE65100);
  static const Color warningBg   = Color(0xFFFFF3E0);
  static const Color info        = Color(0xFF1565C0);
  static const Color infoBg      = Color(0xFFE3F2FD);
  static const Color confirmed   = Color(0xFF6A1B9A);
  static const Color confirmedBg = Color(0xFFF3E5F5);
  static const Color muted       = Color(0xFF78909C);
  static const Color mutedBg     = Color(0xFFF5F5F5);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textH = Color(0xFF0D1F1C);
  static const Color textS = Color(0xFF4A6360);
  static const Color textM = Color(0xFF90A4A0);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient gGreen = LinearGradient(
    colors: [Color(0xFF004D40), Color(0xFF00695C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gEmerald = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gUrgent = LinearGradient(
    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Status helpers ────────────────────────────────────────────────────────
  static Color sFg(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':  return info;
      case 'CONFIRMED':  return confirmed;
      case 'IN_PROGRESS': return green;
      case 'COMPLETED':  return success;
      case 'CANCELLED':
      case 'NO_SHOW':    return muted;
      default:           return textS;
    }
  }

  static Color sBg(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':   return infoBg;
      case 'CONFIRMED':   return confirmedBg;
      case 'IN_PROGRESS': return greenPale;
      case 'COMPLETED':   return successBg;
      case 'CANCELLED':
      case 'NO_SHOW':     return mutedBg;
      default:            return mutedBg;
    }
  }

  static String sLabel(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':   return 'Scheduled';
      case 'CONFIRMED':   return 'Confirmed';
      case 'IN_PROGRESS': return 'In Progress';
      case 'COMPLETED':   return 'Completed';
      case 'CANCELLED':   return 'Cancelled';
      case 'NO_SHOW':     return 'No Show';
      default:            return s;
    }
  }

  // ── Decorations ───────────────────────────────────────────────────────────
  static BoxDecoration card({double r = 16, Color? bg}) => BoxDecoration(
    color: bg ?? bgCard,
    borderRadius: BorderRadius.circular(r),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF00695C).withOpacity(0.07),
        blurRadius: 18,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration gradCard({
    LinearGradient g = gGreen,
    double r = 18,
  }) => BoxDecoration(
    gradient: g,
    borderRadius: BorderRadius.circular(r),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF004D40).withOpacity(0.28),
        blurRadius: 22,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // ── Input decoration ──────────────────────────────────────────────────────
  static InputDecoration inp(
    String label, {
    String? hint,
    Widget? pre,
    Widget? suf,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: pre,
    suffixIcon: suf,
    filled: true,
    fillColor: bgInput,
    labelStyle: const TextStyle(fontSize: 13, color: textS),
    hintStyle: const TextStyle(fontSize: 13, color: textM),
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
      borderSide: const BorderSide(color: green, width: 1.5),
    ),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  // ── Avatar colour ─────────────────────────────────────────────────────────
  static final _ac = [
    const Color(0xFF00695C),
    const Color(0xFF388E3C),
    const Color(0xFF0277BD),
    const Color(0xFF6A1B9A),
    const Color(0xFF00838F),
    const Color(0xFFAD1457),
    const Color(0xFF4E342E),
    const Color(0xFF1565C0),
  ];
  static Color avatarBg(String name) =>
      name.isEmpty ? _ac[0] : _ac[name.codeUnitAt(0) % _ac.length];
}

// ── Convenience extension (previously _StrExt) ────────────────────────────────
extension AssistantStringExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
