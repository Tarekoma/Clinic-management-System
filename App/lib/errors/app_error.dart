// lib/errors/app_error.dart
// Typed error model used across the entire application.

enum AppErrorType {
  network,          // No internet / DNS failure
  timeout,          // Request or connection timed out
  serverUnavailable, // 5xx — backend down
  sessionExpired,   // 401 — token invalid / expired
  forbidden,        // 403 — user lacks permission
  notFound,         // 404 — resource missing
  conflict,         // 409 — duplicate record / overlapping slot
  validation,       // 422 — field-level validation rejected by backend
  fileUpload,       // Multipart/file operation failed
  businessRule,     // App-enforced rule (finalized report, etc.)
  unknown,          // Catch-all
}

class AppError implements Exception {
  final AppErrorType type;

  /// Raw technical message — log only, never show to users.
  final String technical;

  /// Ready-to-display English message (ViewModel layer).
  /// UI layer should prefer localized variants where available.
  final String userMessage;

  const AppError({
    required this.type,
    required this.technical,
    required this.userMessage,
  });

  @override
  String toString() => userMessage;
}
