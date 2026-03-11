// ─────────────────────────────────────────────────────────────────────────────
// lib/providers/doctor_providers.dart
//
// Single Riverpod provider for the entire Doctor module.
// No autoDispose — the ViewModel lives for the full app session so navigating
// away and back does not trigger unnecessary API reloads.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';

/// The single source of truth for all doctor-side state.
final doctorViewModelProvider =
    StateNotifierProvider<DoctorViewModel, DoctorState>(
  (ref) => DoctorViewModel(),
);
