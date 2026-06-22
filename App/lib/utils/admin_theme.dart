// lib/utils/admin_theme.dart

import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ThemeExtension — neutral surface/text/border colors per mode
// ══════════════════════════════════════════════════════════════════════════════

class AdminThemeData extends ThemeExtension<AdminThemeData> {
  final Color bgPage;
  final Color bgCard;
  final Color bgInput;
  final Color divider;
  final Color textH;
  final Color textS;
  final Color textM;
  final Color accent;

  const AdminThemeData({
    required this.bgPage,
    required this.bgCard,
    required this.bgInput,
    required this.divider,
    required this.textH,
    required this.textS,
    required this.textM,
    required this.accent,
  });

  static const light = AdminThemeData(
    bgPage: Color(0xFFF0F2FF),
    bgCard: Color(0xFFFFFFFF),
    bgInput: Color(0xFFF7F8FF),
    divider: Color(0xFFDDE1F0),
    textH: Color(0xFF1A237E),
    textS: Color(0xFF3949AB),
    textM: Color(0xFF9FA8DA),
    accent: Color(0xFF3949AB),
  );

  static const dark = AdminThemeData(
    bgPage: Color(0xFF0D0F1A),
    bgCard: Color(0xFF161A2E),
    bgInput: Color(0xFF1E2340),
    divider: Color(0xFF252B4A),
    textH: Color(0xFFEEF0FF),
    textS: Color(0xFF9FA8DA),
    textM: Color(0xFF5C6BC0),
    accent: Color(0xFF7986CB),
  );

  @override
  AdminThemeData copyWith({
    Color? bgPage,
    Color? bgCard,
    Color? bgInput,
    Color? divider,
    Color? textH,
    Color? textS,
    Color? textM,
    Color? accent,
  }) =>
      AdminThemeData(
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
  AdminThemeData lerp(AdminThemeData? other, double t) {
    if (other == null) return this;
    return AdminThemeData(
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
// AdminTheme — brand tokens + context-aware helpers
// ══════════════════════════════════════════════════════════════════════════════

class AdminTheme {
  AdminTheme._();

  // ─── Brand ────────────────────────────────────────────────────────────────
  static const Color indigo = Color(0xFF3949AB);
  static const Color indigoDeep = Color(0xFF1A237E);
  static const Color indigoLight = Color(0xFF7986CB);
  static const Color indigoPale = Color(0xFFE8EAF6);
  static const Color purple = Color(0xFF7B1FA2);
  static const Color purplePale = Color(0xFFF3E5F5);

  // ─── Semantic ─────────────────────────────────────────────────────────────
  static const Color urgent = Color(0xFFD32F2F);
  static const Color urgentBg = Color(0xFFFDEDED);
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF1565C0);
  static const Color infoBg = Color(0xFFE3F2FD);
  static const Color muted = Color(0xFF78909C);
  static const Color mutedBg = Color(0xFFF5F5F5);
  static const Color active = Color(0xFF2E7D32);
  static const Color activeBg = Color(0xFFE8F5E9);
  static const Color inactive = Color(0xFF78909C);
  static const Color inactiveBg = Color(0xFFF5F5F5);

  // ─── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient gHeader = LinearGradient(
    colors: [Color(0xFF0D1B6E), Color(0xFF1A237E), Color(0xFF283593)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gIndigo = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gPurple = LinearGradient(
    colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gBlue = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gTeal = LinearGradient(
    colors: [Color(0xFF004D40), Color(0xFF00695C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gGreen = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gSlate = LinearGradient(
    colors: [Color(0xFF37474F), Color(0xFF546E7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Helpers ───────────────────────────────────────────────────────────────
  static BoxDecoration cardOf(
    BuildContext context, {
    double r = 16,
    Color? bg,
    double shadowOpacity = 0.06,
  }) {
    final at = Theme.of(context).extension<AdminThemeData>()!;
    return BoxDecoration(
      color: bg ?? at.bgCard,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: at.divider.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: indigo.withValues(alpha: shadowOpacity),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static InputDecoration inpOf(
    BuildContext context,
    String label, {
    String? hint,
    Widget? pre,
    Widget? suf,
  }) {
    final at = Theme.of(context).extension<AdminThemeData>()!;
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
        borderSide: const BorderSide(color: indigo, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static final List<Color> _avatarColors = [
    const Color(0xFF3949AB),
    const Color(0xFF7B1FA2),
    const Color(0xFF1565C0),
    const Color(0xFF00695C),
    const Color(0xFFAD1457),
    const Color(0xFF4E342E),
    const Color(0xFF00838F),
    const Color(0xFF558B2F),
  ];

  static Color avatarBg(String name) => name.isEmpty
      ? _avatarColors[0]
      : _avatarColors[name.codeUnitAt(0) % _avatarColors.length];
}
