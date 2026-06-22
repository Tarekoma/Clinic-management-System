// ─────────────────────────────────────────────────────────────────────────────
// lib/utils/app_themes.dart
//
// Defines production-quality ThemeData for both light and dark modes.
// Used by MaterialApp.theme / MaterialApp.darkTheme.
//
// Design philosophy:
//   Light — Clinical white with deep navy primary and teal accent.
//            Feels authoritative, clean, trustworthy — like a premium EMR.
//   Dark  — Deep navy-black with luminous blue and cyan accent.
//            Reduces eye strain during night shifts; keeps the medical brand.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/utils/admin_theme.dart';

class AppThemes {
  AppThemes._();

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME — Clinical White
  // ══════════════════════════════════════════════════════════════════════════
  static ThemeData get light {
    const cs = ColorScheme.light(
      // ── Brand ──────────────────────────────────────────────────────────
      primary: Color(0xFF0B3D6B), // deep navy
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD6E8FF),
      onPrimaryContainer: Color(0xFF001D36),

      secondary: Color(0xFF00796B), // teal
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB2DFDB),
      onSecondaryContainer: Color(0xFF003330),

      tertiary: Color(0xFF6A1B9A), // accent purple (used in icons)
      onTertiary: Colors.white,

      // ── Surface / background ───────────────────────────────────────────
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0D1B2A),
      surfaceContainerHighest: Color(0xFFF0F4F8),
      onSurfaceVariant: Color(0xFF546E7A),

      background: Color(0xFFF5F7FA),
      onBackground: Color(0xFF0D1B2A),

      // ── Semantic ───────────────────────────────────────────────────────
      error: Color(0xFFD32F2F),
      onError: Colors.white,
      errorContainer: Color(0xFFFDEDED),
      onErrorContainer: Color(0xFF8B0000),

      outline: Color(0xFFDDE3EA),
      outlineVariant: Color(0xFFF0F4F8),
      shadow: Color(0xFF0B3D6B),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,

      // ── Scaffold & card ─────────────────────────────────────────────────
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardColor: Colors.white,
      extensions: const [DoctorThemeData.light, AssistantThemeData.light, AdminThemeData.light],
      dividerColor: const Color(0xFFDDE3EA),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B3D6B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),

      // ── Bottom Navigation ────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF0B3D6B),
        unselectedItemColor: Color(0xFF90A4AE),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Input / TextField ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: Color(0xFF0B3D6B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? Colors.white
              : const Color(0xFF90A4AE),
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? const Color(0xFF0B3D6B)
              : const Color(0xFFDDE3EA),
        ),
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B3D6B),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0B3D6B),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D1B2A),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF546E7A),
        ),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0B3D6B),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFFDDE3EA),
        thickness: 1,
        space: 1,
      ),

      // ── Typography ────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0D1B2A),
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D1B2A),
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D1B2A),
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0D1B2A),
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFF0D1B2A),
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFF546E7A),
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFF90A4AE),
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D1B2A),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME — Night Shift Navy
  //
  // Deep navy-black base: easier on eyes during long clinical shifts.
  // Luminous blue primary + cyan-teal accent: keeps the Hakim brand alive.
  // Card surfaces use subtle navy gradation (not pure grey) to feel cohesive.
  // ══════════════════════════════════════════════════════════════════════════
  static ThemeData get dark {
    const cs = ColorScheme.dark(
      // ── Brand ─────────────────────────────────────────────────────────
      primary: Color(0xFF4A9EDB), // luminous navy-blue (visible on dark)
      onPrimary: Color(0xFF001D36),
      primaryContainer: Color(0xFF0B3D6B),
      onPrimaryContainer: Color(0xFFD6E8FF),

      secondary: Color(0xFF4DB6AC), // luminous teal
      onSecondary: Color(0xFF00251F),
      secondaryContainer: Color(0xFF00504A),
      onSecondaryContainer: Color(0xFFB2DFDB),

      tertiary: Color(0xFFCE93D8), // light purple for icons
      onTertiary: Color(0xFF4A0072),

      // ── Surface / background ───────────────────────────────────────────
      // Uses a deep navy-black that feels clinical, not generic charcoal.
      surface: Color(0xFF1C2333), // card bg — dark navy card
      onSurface: Color(0xFFE8EDF3),
      surfaceContainerHighest: Color(0xFF243044), // slightly lighter navy
      onSurfaceVariant: Color(0xFF8B9BB4),

      background: Color(0xFF0D1117), // page bg — deepest navy-black
      onBackground: Color(0xFFE8EDF3),

      // ── Semantic ──────────────────────────────────────────────────────
      error: Color(0xFFEF5350),
      onError: Colors.white,
      errorContainer: Color(0xFF4D1212),
      onErrorContainer: Color(0xFFFFCDD2),

      outline: Color(0xFF2D3748), // dividers / borders
      outlineVariant: Color(0xFF1E2A3A),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,

      // ── Scaffold & card ─────────────────────────────────────────────────
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      cardColor: const Color(0xFF1C2333),
      extensions: const [DoctorThemeData.dark, AssistantThemeData.dark, AdminThemeData.dark],
      dividerColor: const Color(0xFF2D3748),
      canvasColor: const Color(0xFF0D1117),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C2333),
        foregroundColor: Color(0xFFE8EDF3),
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8EDF3),
          letterSpacing: -0.3,
        ),
      ),

      // ── Bottom Navigation ────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1C2333),
        selectedItemColor: Color(0xFF4A9EDB),
        unselectedItemColor: Color(0xFF5A6A7E),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: const Color(0xFF1C2333),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Input / TextField ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF243044),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF8B9BB4)),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF5A6A7E)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A9EDB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? Colors.white
              : const Color(0xFF5A6A7E),
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? const Color(0xFF4A9EDB)
              : const Color(0xFF2D3748),
        ),
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A9EDB),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4A9EDB),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1C2333),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8EDF3),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF8B9BB4),
        ),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF243044),
        contentTextStyle: const TextStyle(
          color: Color(0xFFE8EDF3),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2D3748),
        thickness: 1,
        space: 1,
      ),

      // ── Typography ────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFFE8EDF3),
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8EDF3),
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8EDF3),
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8EDF3),
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFFE8EDF3),
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8B9BB4),
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFF5A6A7E),
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8EDF3),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ASSISTANT LIGHT THEME — Clinical Mint
  //
  // Dedicated Material-level theme for the Assistant module. Same design
  // system as the Doctor theme (Material 3, same shapes/spacing) but with a
  // distinct green/teal identity instead of doctor's navy/blue, so AppBars,
  // BottomNavigationBars, Switches, SnackBars and Dialogs rendered through
  // default Material widgets (not just AssistantThemeData-aware widgets)
  // carry the Assistant's own branding.
  //
  // Apply this at the root of the Assistant module, e.g.:
  //   Theme(
  //     data: themeMode == ThemeMode.dark
  //         ? AppThemes.assistantDark
  //         : AppThemes.assistantLight,
  //     child: AssistantInterface(...),
  //   )
  // ══════════════════════════════════════════════════════════════════════════
  static ThemeData get assistantLight {
    const cs = ColorScheme.light(
      primary: Color(0xFF00695C), // deep green
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFB2DFDB),
      onPrimaryContainer: Color(0xFF002019),

      secondary: Color(0xFF00838F), // cyan-teal
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB2EBF2),
      onSecondaryContainer: Color(0xFF002022),

      tertiary: Color(0xFF6A1B9A),
      onTertiary: Colors.white,

      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0D1F1C),
      surfaceContainerHighest: Color(0xFFEAF4F2),
      onSurfaceVariant: Color(0xFF4A6360),

      background: Color(0xFFF0F7F5),
      onBackground: Color(0xFF0D1F1C),

      error: Color(0xFFD32F2F),
      onError: Colors.white,
      errorContainer: Color(0xFFFDEDED),
      onErrorContainer: Color(0xFF8B0000),

      outline: Color(0xFFDCEDE9),
      outlineVariant: Color(0xFFEAF4F2),
      shadow: Color(0xFF00695C),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF0F7F5),
      cardColor: Colors.white,
      extensions: const [AssistantThemeData.light],
      dividerColor: const Color(0xFFDCEDE9),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF00695C),
        unselectedItemColor: Color(0xFF90A4A0),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F9F8),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF4A6360)),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF90A4A0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCEDE9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCEDE9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00695C), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? Colors.white
              : const Color(0xFF90A4A0),
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? const Color(0xFF00695C)
              : const Color(0xFFDCEDE9),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF00695C),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D1F1C),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF4A6360),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00695C),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFDCEDE9),
        thickness: 1,
        space: 1,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0D1F1C),
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D1F1C),
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D1F1C),
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0D1F1C),
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFF0D1F1C),
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFF4A6360),
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFF90A4A0),
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D1F1C),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ASSISTANT DARK THEME — Slate Teal
  //
  // Distinct from DoctorTheme's navy/blue dark theme: a softer slate-teal
  // base with a professional cyan accent. Same Material structure/spacing
  // as AppThemes.dark, different identity — built for comfortable long
  // sessions with strong contrast ratios (WCAG AA-friendly text colors).
  // ══════════════════════════════════════════════════════════════════════════
  static ThemeData get assistantDark {
    const cs = ColorScheme.dark(
      primary: Color(0xFF26C6DA), // professional cyan
      onPrimary: Color(0xFF00272B),
      primaryContainer: Color(0xFF00474F),
      onPrimaryContainer: Color(0xFFB2EBF2),

      secondary: Color(0xFF4DB6AC), // teal
      onSecondary: Color(0xFF00251F),
      secondaryContainer: Color(0xFF00504A),
      onSecondaryContainer: Color(0xFFB2DFDB),

      tertiary: Color(0xFFCE93D8),
      onTertiary: Color(0xFF4A0072),

      // Slate-teal surfaces — distinct from doctor's navy-black 0xFF1C2333.
      surface: Color(0xFF15211F), // card bg
      onSurface: Color(0xFFE7F2EF),
      surfaceContainerHighest: Color(0xFF1C2B28),
      onSurfaceVariant: Color(0xFF9FB8B3),

      background: Color(0xFF0E1715), // page bg — deep slate-teal-black
      onBackground: Color(0xFFE7F2EF),

      error: Color(0xFFEF5350),
      onError: Colors.white,
      errorContainer: Color(0xFF4D1212),
      onErrorContainer: Color(0xFFFFCDD2),

      outline: Color(0xFF263935),
      outlineVariant: Color(0xFF1C2B28),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF0E1715),
      cardColor: const Color(0xFF15211F),
      extensions: const [AssistantThemeData.dark],
      dividerColor: const Color(0xFF263935),
      canvasColor: const Color(0xFF0E1715),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF15211F),
        foregroundColor: Color(0xFFE7F2EF),
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE7F2EF),
          letterSpacing: -0.3,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF15211F),
        selectedItemColor: Color(0xFF26C6DA),
        unselectedItemColor: Color(0xFF5E7A74),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF15211F),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2B28),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF9FB8B3)),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF61817A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF263935)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF263935)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF26C6DA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? Colors.white
              : const Color(0xFF5E7A74),
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? const Color(0xFF26C6DA)
              : const Color(0xFF263935),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF26C6DA),
          foregroundColor: const Color(0xFF00272B),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF26C6DA),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF15211F),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE7F2EF),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF9FB8B3),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C2B28),
        contentTextStyle: const TextStyle(
          color: Color(0xFFE7F2EF),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF263935),
        thickness: 1,
        space: 1,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFFE7F2EF),
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE7F2EF),
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE7F2EF),
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE7F2EF),
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFFE7F2EF),
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFF9FB8B3),
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFF61817A),
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE7F2EF),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADMIN LIGHT THEME — Soft Indigo
  // ══════════════════════════════════════════════════════════════════════════
  static ThemeData get adminLight {
    const cs = ColorScheme.light(
      primary: Color(0xFF5E35B1),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEDE7F6),
      onPrimaryContainer: Color(0xFF1A0A3C),

      secondary: Color(0xFF7B1FA2),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF3E5F5),
      onSecondaryContainer: Color(0xFF2D0040),

      tertiary: Color(0xFF1565C0),
      onTertiary: Colors.white,

      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A0A3C),
      surfaceContainerHighest: Color(0xFFEDE7F6),
      onSurfaceVariant: Color(0xFF5B4A8A),

      error: Color(0xFFD32F2F),
      onError: Colors.white,
      errorContainer: Color(0xFFFDEDED),
      onErrorContainer: Color(0xFF8B0000),

      outline: Color(0xFFE0D9F7),
      outlineVariant: Color(0xFFEDE7F6),
      shadow: Color(0xFF5E35B1),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF5F3FF),
      cardColor: Colors.white,
      extensions: const [AdminThemeData.light, DoctorThemeData.light, AssistantThemeData.light],
      dividerColor: const Color(0xFFE0D9F7),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF5E35B1),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF5E35B1),
        unselectedItemColor: Color(0xFF9D8EC4),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F3FF),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF5B4A8A)),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9D8EC4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D9F7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D9F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5E35B1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5E35B1),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF5E35B1),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A0A3C),
        ),
        contentTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF5B4A8A)),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF5E35B1),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      dividerTheme: const DividerThemeData(color: Color(0xFFE0D9F7), thickness: 1, space: 1),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A0A3C), letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A0A3C), letterSpacing: -0.3),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A0A3C)),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A0A3C)),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF1A0A3C)),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF5B4A8A)),
        bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF9D8EC4)),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A0A3C)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADMIN DARK THEME — Deep Violet
  // ══════════════════════════════════════════════════════════════════════════
  static ThemeData get adminDark {
    const cs = ColorScheme.dark(
      primary: Color(0xFF9575CD),
      onPrimary: Color(0xFF1A0A3C),
      primaryContainer: Color(0xFF311B92),
      onPrimaryContainer: Color(0xFFEDE7F6),

      secondary: Color(0xFFCE93D8),
      onSecondary: Color(0xFF2D0040),
      secondaryContainer: Color(0xFF4A148C),
      onSecondaryContainer: Color(0xFFF3E5F5),

      tertiary: Color(0xFF64B5F6),
      onTertiary: Color(0xFF001C38),

      surface: Color(0xFF1E1633),
      onSurface: Color(0xFFEDE8FF),
      surfaceContainerHighest: Color(0xFF281F3F),
      onSurfaceVariant: Color(0xFF9D8EC4),

      error: Color(0xFFEF5350),
      onError: Colors.white,
      errorContainer: Color(0xFF4D1212),
      onErrorContainer: Color(0xFFFFCDD2),

      outline: Color(0xFF2E2450),
      outlineVariant: Color(0xFF281F3F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF100B1F),
      cardColor: const Color(0xFF1E1633),
      extensions: const [AdminThemeData.dark, DoctorThemeData.dark, AssistantThemeData.dark],
      dividerColor: const Color(0xFF2E2450),
      canvasColor: const Color(0xFF100B1F),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1633),
        foregroundColor: Color(0xFFEDE8FF),
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFEDE8FF),
          letterSpacing: -0.3,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1633),
        selectedItemColor: Color(0xFF9575CD),
        unselectedItemColor: Color(0xFF5B4A8A),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1E1633),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF281F3F),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF9D8EC4)),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF5B4A8A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2450)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2450)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9575CD), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9575CD),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF9575CD),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1633),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDE8FF)),
        contentTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF9D8EC4)),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF281F3F),
        contentTextStyle: const TextStyle(
          color: Color(0xFFEDE8FF),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      dividerTheme: const DividerThemeData(color: Color(0xFF2E2450), thickness: 1, space: 1),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFEDE8FF), letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFEDE8FF), letterSpacing: -0.3),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDE8FF)),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFEDE8FF)),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFFEDE8FF)),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF9D8EC4)),
        bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF5B4A8A)),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEDE8FF)),
      ),
    );
  }
}
