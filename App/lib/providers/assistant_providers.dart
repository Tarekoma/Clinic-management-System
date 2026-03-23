// ─────────────────────────────────────────────────────────────────────────────
// lib/providers/assistant_providers.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// Single provider that wires AssistantViewModel into the Riverpod tree.
//
// Usage inside any ConsumerWidget / ConsumerStatefulWidget:
//
//   final state = ref.watch(assistantViewModelProvider);
//   final vm    = ref.read(assistantViewModelProvider.notifier);
//
// FIX: autoDispose is intentionally NOT used.
//
// Without autoDispose the ViewModel (and its _linkedDoctorId) persist for the
// full app session.  This means:
//   • navigating away and back does not lose the resolved linked doctor.
//   • a second call to initForAssistant() from initState is a no-op for the
//     expensive getAssistants() lookup — _linkedDoctorId is already set.
//
// With autoDispose the ViewModel would be destroyed the moment
// AssistantInterface left the tree (e.g. when the user opened the
// consultation page), causing _linkedDoctorId to reset to null on the next
// navigation.  That would force a full re-lookup every time, and in the window
// between ViewModel creation and initForAssistant() completing the UI would
// briefly show the wrong doctor's data.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/viewmodels/assistant_viewmodel.dart';

/// The single source of truth for all assistant-side state.
final assistantViewModelProvider =
    StateNotifierProvider<AssistantViewModel, AssistantState>(
      (ref) => AssistantViewModel(),
    );
