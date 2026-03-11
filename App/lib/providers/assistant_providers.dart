// ─────────────────────────────────────────────────────────────────────────────
// lib/providers/assistant_providers.dart
//
// Single provider that wires AssistantViewModel into the Riverpod tree.
//
// Usage inside any ConsumerWidget / ConsumerStatefulWidget:
//
//   final state = ref.watch(assistantViewModelProvider);
//   final vm    = ref.read(assistantViewModelProvider.notifier);
//
// autoDispose ensures the ViewModel (and its in-flight API calls) are cleaned
// up when the AssistantInterface is no longer in the widget tree.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/viewmodels/assistant_viewmodel.dart';

/// The single source of truth for all assistant-side state.
final assistantViewModelProvider =
    StateNotifierProvider<AssistantViewModel, AssistantState>(
  (ref) => AssistantViewModel(),
);
