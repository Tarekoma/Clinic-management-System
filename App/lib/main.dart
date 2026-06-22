import 'package:Hakim/providers/theme_providers.dart';
import 'package:Hakim/providers/locale_provider.dart';
import 'package:Hakim/utils/app_themes.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/splash/splash_screen.dart';
import 'package:Hakim/views/auths/login_page.dart';
import 'package:Hakim/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/services/API_Service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  ApiService.init();
  ApiService.registerUnauthorizedHandler(() {
    AuthViewModel.resetCurrentInstance();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  });
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider); // ← watches language selection

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      themeMode: themeMode,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,

      // ── Localization ──────────────────────────────────────────────────────
      // Setting `locale` explicitly (rather than leaving it to system locale
      // detection) means the in-app language picker is the single source of
      // truth — switching it rebuilds the whole app, including automatic
      // RTL mirroring for Arabic (Flutter handles direction based on locale).
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      home: const SplashScreen(),
    );
  }
}
