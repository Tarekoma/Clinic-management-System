// ─────────────────────────────────────────────────────────────────────────────
// lib/providers/auth_providers.dart
//
// Single Riverpod provider for the Auth module.
//
// No autoDispose — the ViewModel persists for the app session so that a
// back-navigation to the login screen does not lose state mid-flight.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/viewmodels/auth_viewmodel.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/providers/admin_providers.dart';

/// The single source of truth for authentication state.
///
/// Usage in views:
///   final state = ref.watch(authProvider);
///   final vm    = ref.read(authProvider.notifier);
final authProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(),
);

/// Clears stale role-VM state when the user logs out.
/// Mount this provider once near the app root (e.g. in main.dart or App widget)
/// via `ref.watch(authLogoutCleanupProvider)`.
final authLogoutCleanupProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    final wasAuthenticated = previous?.isAuthenticated ?? false;
    if (wasAuthenticated && !next.isAuthenticated) {
      ref.invalidate(doctorViewModelProvider);
      ref.invalidate(assistantViewModelProvider);
      ref.invalidate(adminViewModelProvider);
    }
  });
});
