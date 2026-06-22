// ─────────────────────────────────────────────────────────────────────────────
// lib/utils/assistant_theme.dart
//
// CHANGE IN THIS VERSION — dark mode parity with doctor_theme.dart:
//   • Added AssistantThemeData (ThemeExtension) carrying neutral surface/text
//     colors per mode (light/dark), mirroring DoctorThemeData exactly.
//   • Added context-aware helpers: AssistantTheme.cardOf(context),
//     AssistantTheme.inpOf(context, label, ...).
//   • Old static consts (bgPage, bgCard, bgInput, divider, textH, textS,
//     textM) are KEPT for backward-compat with any file not yet migrated,
//     but are now marked @Deprecated — prefer reading from
//     Theme.of(context).extension<AssistantThemeData>()! instead.
//   • Brand colors (green, urgent, success, warning, info, confirmed, muted,
//     etc.) are UNCHANGED — these are identity colors, not theme-neutral
//     surfaces, same rule as DoctorTheme.navy/teal/urgent.
//   • Register AssistantThemeData.light / .dark in AppThemes.light/.dark's
//     `extensions: [...]` list (see app_themes.dart) — without that
//     registration, `Theme.of(context).extension<AssistantThemeData>()!`
//     will throw null at runtime.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ThemeExtension — carries all neutral colors per mode
// ══════════════════════════════════════════════════════════════════════════════

class AssistantThemeData extends ThemeExtension<AssistantThemeData> {
  final Color bgPage;
  final Color bgCard;
  final Color bgInput;
  final Color divider;
  final Color textH;
  final Color textS;
  final Color textM;
  final Color accent; // brighter green for dark surfaces

  const AssistantThemeData({
    required this.bgPage,
    required this.bgCard,
    required this.bgInput,
    required this.divider,
    required this.textH,
    required this.textS,
    required this.textM,
    required this.accent,
  });

  // ── Light variant (clinical mint/white) ────────────────────────────────────
  static const light = AssistantThemeData(
    bgPage: Color(0xFFF0F7F5),
    bgCard: Color(0xFFFFFFFF),
    bgInput: Color(0xFFF5F9F8),
    divider: Color(0xFFDCEDE9),
    textH: Color(0xFF0D1F1C),
    textS: Color(0xFF4A6360),
    textM: Color(0xFF90A4A0),
    accent: Color(0xFF00695C), // green — fine on white
  );

  // ── Dark variant (modern slate/teal — distinct from DoctorTheme.dark's
  //    navy/blue palette; same app design language, different identity) ──────
  static const dark = AssistantThemeData(
    bgPage: Color(
      0xFF0E1715,
    ), // deep slate-teal-black (not doctor's navy-black)
    bgCard: Color(0xFF15211F), // slate-teal card surface
    bgInput: Color(0xFF1C2B28), // slightly lifted input fill
    divider: Color(0xFF263935), // muted teal-grey divider
    textH: Color(0xFFE7F2EF), // soft teal-tinted off-white
    textS: Color(0xFF9FB8B3), // muted sage-teal secondary text
    textM: Color(0xFF61817A), // tertiary/placeholder text
    accent: Color(0xFF26C6DA), // professional cyan — visible on dark cards
  );

  @override
  AssistantThemeData copyWith({
    Color? bgPage,
    Color? bgCard,
    Color? bgInput,
    Color? divider,
    Color? textH,
    Color? textS,
    Color? textM,
    Color? accent,
  }) => AssistantThemeData(
    bgPage: bgPage ?? this.bgPage,
    bgCard: bgCard ?? this.bgCard,
    bgInput: bgInput ?? this.bgInput,
    divider: divider ?? this.divider,
    textH: textH ?? this.textH,
    textS: textS ?? this.textS,
    textM: textM ?? this.textM,
    accent: accent ?? this.accent,
  );

  @override
  AssistantThemeData lerp(AssistantThemeData? other, double t) {
    if (other == null) return this;
    return AssistantThemeData(
      bgPage: Color.lerp(bgPage, other.bgPage, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgInput: Color.lerp(bgInput, other.bgInput, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textH: Color.lerp(textH, other.textH, t)!,
      textS: Color.lerp(textS, other.textS, t)!,
      textM: Color.lerp(textM, other.textM, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AssistantTheme — brand tokens + context-aware helpers
// ══════════════════════════════════════════════════════════════════════════════

class AssistantTheme {
  AssistantTheme._();

  // ── Brand (NEVER changes with theme) ────────────────────────────────────────
  static const Color green = Color(0xFF00695C);
  static const Color greenDeep = Color(0xFF004D40);
  static const Color greenLight = Color(0xFF26A69A);
  static const Color greenPale = Color(0xFFE0F2F1);
  static const Color emerald = Color(0xFF43A047);

  // ── Status (NEVER changes with theme) ───────────────────────────────────────
  static const Color urgent = Color(0xFFD32F2F);
  static const Color urgentBg = Color(0xFFFDEDED);
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF1565C0);
  static const Color infoBg = Color(0xFFE3F2FD);
  static const Color confirmed = Color(0xFF6A1B9A);
  static const Color confirmedBg = Color(0xFFF3E5F5);
  static const Color muted = Color(0xFF78909C);
  static const Color mutedBg = Color(0xFFF5F5F5);

  // ── Legacy const surface/text tokens (kept for backward-compat) ─────────────
  // Prefer Theme.of(context).extension<AssistantThemeData>()! instead.
  @Deprecated('Use Theme.of(context).extension<AssistantThemeData>()!.bgPage')
  static const Color bgPage = Color(0xFFF0F7F5);
  @Deprecated('Use Theme.of(context).extension<AssistantThemeData>()!.bgCard')
  static const Color bgCard = Color(0xFFFFFFFF);
  @Deprecated('Use Theme.of(context).extension<AssistantThemeData>()!.bgInput')
  static const Color bgInput = Color(0xFFF5F9F8);
  @Deprecated('Use Theme.of(context).extension<AssistantThemeData>()!.divider')
  static const Color divider = Color(0xFFDCEDE9);
  @Deprecated('Use Theme.of(context).extension<AssistantThemeData>()!.textH')
  static const Color textH = Color(0xFF0D1F1C);
  @Deprecated('Use Theme.of(context).extension<AssistantThemeData>()!.textS')
  static const Color textS = Color(0xFF4A6360);
  @Deprecated('Use Theme.of(context).extension<AssistantThemeData>()!.textM')
  static const Color textM = Color(0xFF90A4A0);

  // ── Gradients ──────────────────────────────────────────────────────────────
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
      case 'SCHEDULED':
        return info;
      case 'CONFIRMED':
        return confirmed;
      case 'IN_PROGRESS':
        return green;
      case 'COMPLETED':
        return success;
      case 'CANCELLED':
      case 'NO_SHOW':
        return muted;
      default:
        return textS;
    }
  }

  static Color sBg(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':
        return infoBg;
      case 'CONFIRMED':
        return confirmedBg;
      case 'IN_PROGRESS':
        return greenPale;
      case 'COMPLETED':
        return successBg;
      case 'CANCELLED':
      case 'NO_SHOW':
        return mutedBg;
      default:
        return mutedBg;
    }
  }

  static String sLabel(String s, AppLocalizations loc) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':
        return loc.statusScheduled;
      case 'CONFIRMED':
        return loc.statusConfirmed;
      case 'IN_PROGRESS':
        return loc.statusInProgress;
      case 'COMPLETED':
        return loc.statusCompleted;
      case 'CANCELLED':
        return loc.statusCancelled;
      case 'NO_SHOW':
        return loc.statusNoShow;
      default:
        return s;
    }
  }

  // ── Context-aware card decoration ───────────────────────────────────────────
  static BoxDecoration cardOf(
    BuildContext context, {
    double r = 16,
    Color? bg,
  }) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return BoxDecoration(
      color: bg ?? at.bgCard,
      borderRadius: BorderRadius.circular(r),
      boxShadow: [
        BoxShadow(
          color: green.withOpacity(0.07),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // ── Legacy card() — kept for screens not yet migrated ───────────────────────
  @Deprecated('Use AssistantTheme.cardOf(context) for dark-mode support')
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

  static BoxDecoration gradCard({LinearGradient g = gGreen, double r = 18}) =>
      BoxDecoration(
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

  // ── Context-aware input decoration ──────────────────────────────────────────
  static InputDecoration inpOf(
    BuildContext context,
    String label, {
    String? hint,
    Widget? pre,
    Widget? suf,
  }) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: pre,
      suffixIcon: suf,
      filled: true,
      fillColor: at.bgInput,
      labelStyle: TextStyle(fontSize: 13, color: at.textS),
      hintStyle: TextStyle(fontSize: 13, color: at.textM),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: at.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: at.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: green, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Legacy inp() — kept for screens not yet migrated ────────────────────────
  @Deprecated('Use AssistantTheme.inpOf(context, label) for dark-mode support')
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  // ── Avatar colour ────────────────────────────────────────────────────────────
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

// ── Convenience extension (previously _StrExt) ──────────────────────────────
extension AssistantStringExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
