// ─────────────────────────────────────────────────────────────────────────────
// lib/providers/settings_providers.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/viewmodels/settings_viewmodel.dart';

final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>(
  (ref) => SettingsViewModel(),
);
