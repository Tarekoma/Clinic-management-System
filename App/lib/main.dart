import 'dart:convert';

import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/auth_providers.dart';
import 'package:Hakim/providers/locale_provider.dart';
import 'package:Hakim/providers/theme_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/services/settings_service.dart';
import 'package:Hakim/splash/splash_screen.dart';
import 'package:Hakim/utils/app_themes.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/viewmodels/auth_viewmodel.dart';
import 'package:Hakim/views/admin/admin_interface.dart';
import 'package:Hakim/views/assistant/assistant_interface.dart';
import 'package:Hakim/views/auths/login_page.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// ── Session resolution ────────────────────────────────────────────────────────

bool _isTokenExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    var payload = parts[1];
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    final decoded = utf8.decode(base64Url.decode(payload));
    final map = jsonDecode(decoded) as Map<String, dynamic>;
    final exp = map['exp'];
    if (exp == null) return false;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >=
        (exp as num).toInt();
  } catch (_) {
    return true;
  }
}

/// Reads the persisted session and returns the widget that should be the
/// first live screen. Called once per process lifetime — no artificial delay.
Future<Widget> _resolveInitialScreen() async {
  final token = await ApiService.getToken();
  final role = await ApiService.getRole();
  final profileMap = await ApiService.getUserProfile();

  if (token == null ||
      role == null ||
      profileMap == null ||
      _isTokenExpired(token)) {
    return const LoginPage();
  }

  final profile = UserProfile(
    id: profileMap['id']?.toString() ?? '',
    email: profileMap['email']?.toString() ?? '',
    username: profileMap['username']?.toString() ?? '',
    firstName: profileMap['first_name']?.toString() ?? '',
    lastName: profileMap['last_name']?.toString() ?? '',
    userType: profileMap['role']?.toString() ?? role,
    gender: profileMap['gender']?.toString() ?? '',
    birthDate: profileMap['date_of_birth'] != null
        ? DateTime.tryParse(profileMap['date_of_birth'].toString())
        : null,
    clinicName: profileMap['clinic_name']?.toString(),
    licenseNumber: profileMap['license_number']?.toString(),
    phone: profileMap['phone_number']?.toString(),
    region: profileMap['region']?.toString(),
    specialization: profileMap['specialization']?.toString(),
    createdAt: profileMap['created_at'] != null
        ? DateTime.tryParse(profileMap['created_at'].toString()) ??
              DateTime.now()
        : DateTime.now(),
    // Restore doctor_id + doctor_email so AssistantViewModel's Source 1
    // succeeds immediately on session restore, skipping the expensive
    // getAssistants() / getDoctors() discovery chain.
    doctorId: profileMap['doctor_id']?.toString(),
    doctorEmail: profileMap['doctor_email']?.toString(),
  );

  // Restore the last active tab so the user lands on the exact same screen
  // after a process-death restart (common on OEM Android devices).
  // Runs in parallel with nothing — SharedPreferences is already cached by
  // LocaleNotifier._restore(), so this read is essentially instant.
  final tabIndex = await SettingsService.getLastTab(
    role,
    fallback: role == 'assistant' ? 1 : 0,
  );

  if (role == 'doctor') {
    return DoctorInterface(doctorProfile: profile, initialTabIndex: tabIndex);
  }
  if (role == 'assistant') {
    return AssistantInterface(
      assistantProfile: profile,
      initialTabIndex: tabIndex,
    );
  }
  if (role == 'admin') {
    return AdminInterface(adminProfile: profile, initialTabIndex: tabIndex);
  }

  return const LoginPage();
}

// ── StartupRouter ─────────────────────────────────────────────────────────────

/// Shown only on a cold process start (or after a process-death restart).
/// Displays the branded splash immediately, resolves the session without any
/// artificial delay, then replaces itself with the correct role screen.
///
/// On a warm resume (process still alive) this widget is never seen again
/// because pushReplacement already removed it from the navigation stack.
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  @override
  void initState() {
    super.initState();
    _resolveAndNavigate();
  }

  Future<void> _resolveAndNavigate() async {
    final destination = await _resolveInitialScreen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        // Fade the splash out instead of a hard cut
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

// ── MyApp ─────────────────────────────────────────────────────────────────────

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authLogoutCleanupProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      themeMode: themeMode,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,

      // Setting `locale` explicitly (rather than leaving it to system locale
      // detection) means the in-app language picker is the single source of
      // truth — switching it rebuilds the whole app, including automatic
      // RTL mirroring for Arabic (Flutter handles direction based on locale).
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      home: const _StartupRouter(),
    );
  }
}
