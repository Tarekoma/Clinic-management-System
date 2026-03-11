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

/// The single source of truth for authentication state.
///
/// Usage in views:
///   final state = ref.watch(authProvider);
///   final vm    = ref.read(authProvider.notifier);
final authProvider =
    StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(),
);
