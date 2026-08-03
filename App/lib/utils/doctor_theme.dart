// ─────────────────────────────────────────────────────────────────────────────
// lib/utils/doctor_theme.dart
//
// CHANGE IN THIS VERSION:
//   • sLabel(s) → sLabel(s, loc) — now takes AppLocalizations and returns
//     a localized status string instead of hardcoded English.
//   • All call sites must be updated to pass `loc`:
//       DoctorTheme.sLabel(status, loc)   /   _T.sLabel(status, loc)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ThemeExtension — carries all neutral colors per mode
// ══════════════════════════════════════════════════════════════════════════════

class DoctorThemeData extends ThemeExtension<DoctorThemeData> {
  final Color bgPage;
  final Color bgCard;
  final Color bgInput;
  final Color divider;
  final Color textH;
  final Color textS;
  final Color textM;
  final Color accent; // brighter interactive color for dark surfaces
  final Color accentTeal; // brighter teal for dark surfaces

  const DoctorThemeData({
    required this.bgPage,
    required this.bgCard,
    required this.bgInput,
    required this.divider,
    required this.textH,
    required this.textS,
    required this.textM,
    required this.accent,
    required this.accentTeal,
  });

  // ── Light variant (clinical white) ─────────────────────────────────────────
  static const light = DoctorThemeData(
    bgPage: Color(0xFFF5F7FA),
    bgCard: Color(0xFFFFFFFF),
    bgInput: Color(0xFFFFFFFF),
    divider: Color(0xFFDDE3EA),
    textH: Color(0xFF0D1B2A),
    textS: Color(0xFF546E7A),
    textM: Color(0xFF90A4AE),
    accent: Color(0xFF0B3D6B), // navy — fine on white
    accentTeal: Color(0xFF00796B), // teal — fine on white
  );

  // ── Dark variant (night-shift navy) ────────────────────────────────────────
  static const dark = DoctorThemeData(
    bgPage: Color(0xFF0D1117),
    bgCard: Color(0xFF1C2333),
    bgInput: Color(0xFF243044),
    divider: Color(0xFF2D3748),
    textH: Color(0xFFE8EDF3),
    textS: Color(0xFF8B9BB4),
    textM: Color(0xFF5A6A7E),
    accent: Color(0xFF4A9EDB), // brighter blue — visible on dark cards
    accentTeal: Color(0xFF4DB6AC), // brighter teal — visible on dark cards
  );

  @override
  DoctorThemeData copyWith({
    Color? bgPage,
    Color? bgCard,
    Color? bgInput,
    Color? divider,
    Color? textH,
    Color? textS,
    Color? textM,
    Color? accent,
    Color? accentTeal,
  }) => DoctorThemeData(
    bgPage: bgPage ?? this.bgPage,
    bgCard: bgCard ?? this.bgCard,
    bgInput: bgInput ?? this.bgInput,
    divider: divider ?? this.divider,
    textH: textH ?? this.textH,
    textS: textS ?? this.textS,
    textM: textM ?? this.textM,
    accent: accent ?? this.accent,
    accentTeal: accentTeal ?? this.accentTeal,
  );

  @override
  DoctorThemeData lerp(DoctorThemeData? other, double t) {
    if (other == null) return this;
    return DoctorThemeData(
      bgPage: Color.lerp(bgPage, other.bgPage, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgInput: Color.lerp(bgInput, other.bgInput, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textH: Color.lerp(textH, other.textH, t)!,
      textS: Color.lerp(textS, other.textS, t)!,
      textM: Color.lerp(textM, other.textM, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentTeal: Color.lerp(accentTeal, other.accentTeal, t)!,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DoctorTheme — brand tokens + context-aware helpers
// ══════════════════════════════════════════════════════════════════════════════

class DoctorTheme {
  DoctorTheme._();

  // ── Brand (NEVER change with theme) ───────────────────────────────────────
  static const Color navy = Color(0xFF0B3D6B);
  static const Color navyDeep = Color(0xFF071E34);
  static const Color navyLight = Color(0xFF1565C0);
  static const Color teal = Color(0xFF00796B);
  static const Color tealLight = Color(0xFF26A69A);
  static const Color tealPale = Color(0xFFE0F2F1);

  // ── Status (NEVER change with theme) ──────────────────────────────────────
  static const Color urgent = Color(0xFFD32F2F);
  static const Color urgentBg = Color(0xFFFDEDED);
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color waitingYellow = Color(0xFFF9A825);
  static const Color waitingYellowBg = Color(0xFFFFF8E1);
  static const Color info = Color(0xFF1565C0);
  static const Color infoBg = Color(0xFFE3F2FD);
  static const Color muted = Color(0xFF78909C);
  static const Color mutedBg = Color(0xFFF5F5F5);
  static const Color noShowGray = Color(0xFF546E7A);
  static const Color noShowBg = Color(0xFFECEFF1);
  static const Color confirmed = Color(0xFF6A1B9A);
  static const Color confirmedBg = Color(0xFFF3E5F5);

  // ── Legacy const surface/text tokens (kept for backward-compat) ────────────
  @Deprecated('Use dt.bgPage from DoctorThemeData extension')
  static const Color bgPage = Color(0xFFFFFFFF);
  @Deprecated('Use dt.bgCard from DoctorThemeData extension')
  static const Color bgCard = Color(0xFFFFFFFF);
  @Deprecated('Use dt.bgInput from DoctorThemeData extension')
  static const Color bgInput = Color(0xFFFFFFFF);
  @Deprecated('Use dt.divider from DoctorThemeData extension')
  static const Color divider = Color(0xFFDDE3EA);
  @Deprecated('Use dt.textH from DoctorThemeData extension')
  static const Color textH = Color(0xFF0D1B2A);
  @Deprecated('Use dt.textS from DoctorThemeData extension')
  static const Color textS = Color(0xFF546E7A);
  @Deprecated('Use dt.textM from DoctorThemeData extension')
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

  /// Returns the status string to display for an appointment.
  /// When the appointment is IN_PROGRESS and a visit exists, the visit status
  /// takes precedence over the appointment status in the display layer.
  static String getDisplayStatus(Map<String, dynamic> appt) {
    final appointmentStatus =
        (appt['status'] ?? 'SCHEDULED').toString().toUpperCase();
    if (appointmentStatus == 'IN_PROGRESS') {
      final visitStatus =
          (appt['visit_status'] ?? appt['visitStatus'] ?? '')
              .toString()
              .toUpperCase();
      if (visitStatus.isNotEmpty) return visitStatus;
    }
    return appointmentStatus;
  }

  static Color sFg(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':
        return muted;
      case 'CONFIRMED':
        return confirmed;
      case 'WAITING':
        return waitingYellow;
      case 'IN_PROGRESS':
        return info;
      case 'COMPLETED':
        return success;
      case 'CANCELLED':
        return confirmed;
      case 'NO_SHOW':
        return noShowGray;
      default:
        return muted;
    }
  }

  static Color sBg(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':
        return mutedBg;
      case 'CONFIRMED':
        return confirmedBg;
      case 'WAITING':
        return waitingYellowBg;
      case 'IN_PROGRESS':
        return infoBg;
      case 'COMPLETED':
        return successBg;
      case 'CANCELLED':
        return confirmedBg;
      case 'NO_SHOW':
        return noShowBg;
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
      case 'WAITING':
        return loc.statusWaiting;
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

  // ── Context-aware card decoration ─────────────────────────────────────────
  static BoxDecoration cardOf(
    BuildContext context, {
    double r = 16,
    Color? bg,
  }) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return BoxDecoration(
      color: bg ?? dt.bgCard,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: dt.divider.withOpacity(0.6)),
      boxShadow: [
        BoxShadow(
          color: navy.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // ── Legacy card() — kept for screens not yet migrated ─────────────────────
  static BoxDecoration card({double r = 16, Color? bg}) => BoxDecoration(
    color: bg ?? const Color(0xFFFFFFFF),
    borderRadius: BorderRadius.circular(r),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0B3D6B).withOpacity(0.07),
        blurRadius: 18,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration gradCard({LinearGradient g = gNavy, double r = 18}) =>
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

  // ── Context-aware input decoration ────────────────────────────────────────
  static InputDecoration inpOf(
    BuildContext context,
    String label, {
    String? hint,
    Widget? pre,
    Widget? suf,
    bool error = false,
  }) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final borderColor = error ? urgent : dt.divider;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: pre,
      suffixIcon: suf,
      filled: true,
      fillColor: dt.bgInput,
      labelStyle: TextStyle(fontSize: 13, color: dt.textS),
      hintStyle: TextStyle(fontSize: 13, color: dt.textM),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: error ? 1.5 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error ? urgent : navy, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Legacy inp() — kept for screens not yet migrated ──────────────────────
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
    fillColor: const Color(0xFFFFFFFF),
    labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF90A4AE)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: navy, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
