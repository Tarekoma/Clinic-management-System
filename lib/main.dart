import 'package:Hakim/splash/splash_screen.dart';
import 'package:Hakim/views/auths/login_page.dart';
import 'package:Hakim/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/services/API_Service.dart';

// ── Global navigator key ───────────────────────────────────────────────────
// Gives ApiService access to the navigator from outside the widget tree so
// the 401 handler can redirect to LoginPage without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  ApiService.init();

  // ── Register the 401 unauthorized handler ──────────────────────────────
  //
  // Two things must happen together:
  //
  //   1. AuthViewModel.resetCurrentInstance()
  //      Sets isAuthenticated=false, destination=none on the live AuthState.
  //
  //      WITHOUT THIS: LoginPage's ref.listen sees the stale
  //      isAuthenticated=true and immediately re-navigates back to the
  //      doctor/assistant interface, which fires loadAll() with no token,
  //      gets 401 again, navigates to LoginPage again → infinite loop.
  //
  //   2. navigatorKey.pushAndRemoveUntil(LoginPage)
  //      Sends the user to login and clears the entire back stack.
  //
  //      WITHOUT THIS (the original bug): the callback was never registered,
  //      so _onUnauthorized was null — token was cleared but user stayed
  //      on the doctor/assistant screen with no token in storage.
  //
  // AuthViewModel.resetCurrentInstance() works because authProvider has no
  // autoDispose — exactly one AuthViewModel instance exists per session, and
  // it registers itself as the static _instance in its constructor.
  // This avoids ProviderContainer / UncontrolledProviderScope entirely.
  //
  ApiService.registerUnauthorizedHandler(() {
    AuthViewModel.resetCurrentInstance(); // step 1: clear stale auth state
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false, // step 2: navigate to login, remove all routes
    );
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
