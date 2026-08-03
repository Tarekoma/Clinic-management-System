// ─────────────────────────────────────────────────────────────────────────────
// lib/providers/theme_providers.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Global ScaffoldMessenger key ───────────────────────────────────────────
// Attach to MaterialApp.scaffoldMessengerKey so snackbars shown from
// modal bottom sheets (settings, sub-sheets, dialogs) render ABOVE the modal,
// not behind it on the dashboard.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// ── App-wide theme mode ────────────────────────────────────────────────────
// Watched by MaterialApp — toggling this rebuilds the whole tree instantly.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
