// ─────────────────────────────────────────────────────────────────────────────
// lib/providers/locale_provider.dart
//
// App-wide locale state. Watched by MaterialApp.locale in main.dart so
// switching languages anywhere rebuilds the whole app — same pattern as
// themeModeProvider for dark/light mode.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/services/settings_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _restore();
  }

  Future<void> _restore() async {
    final saved = await SettingsService.getString('language_code');
    if (saved != null && saved.isNotEmpty) {
      state = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await SettingsService.setString('language_code', locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
