// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/settings/settings_sheet_helpers.dart
//
// Shared UI helpers used by every settings sheet.
// Import this file in each sheet instead of duplicating code.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/utils/doctor_theme.dart';

/// Drag handle shown at the top of every bottom sheet.
Widget sheetHandle() => Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

/// Icon + title row shown at the top of every bottom sheet body.
Widget sheetTitle(String title, IconData icon) => Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F1FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DoctorTheme.navy, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: DoctorTheme.textH,
          ),
        ),
      ],
    );

/// Primary filled button style used across all sheets.
ButtonStyle sheetBtnStyle() => FilledButton.styleFrom(
      backgroundColor: DoctorTheme.navy,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
