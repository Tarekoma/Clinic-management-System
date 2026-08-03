// lib/widgets/shared/app_dialogs.dart
// Centralized dialog and snackbar components used across all interfaces.

import 'package:flutter/material.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';

class AppDialogs {
  AppDialogs._();

  // ── Confirmation dialog ─────────────────────────────────────────────────────

  /// Shows a modal confirmation dialog. Returns true when the user confirms.
  ///
  /// Set [destructive] = true for irreversible actions — the confirm button
  /// turns red.  Use [accentColor] to override for non-destructive confirmations.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String body,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
    IconData? icon,
    Color? accentColor,
  }) async {
    final loc = AppLocalizations.of(context);
    final Color confirmColor = destructive
        ? Colors.red.shade600
        : (accentColor ?? Theme.of(context).colorScheme.primary);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: confirmColor, size: 22),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          body,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.72),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(cancelLabel ?? loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              confirmLabel ?? loc.yes,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Error dialog ────────────────────────────────────────────────────────────

  /// Shows a non-dismissable error dialog.
  /// Pass [onAction] + [actionLabel] to add a retry button.
  static Future<void> showError(
    BuildContext context, {
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title ?? 'Error',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.72),
          ),
        ),
        actions: [
          if (onAction != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onAction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(actionLabel ?? 'Retry'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
        ],
      ),
    );
  }

  // ── Specialized confirmations ───────────────────────────────────────────────

  /// Delete confirmation for a named record. Returns true when user confirms.
  static Future<bool> confirmDelete(
    BuildContext context, {
    required String itemName,
    String? body,
  }) {
    final loc = AppLocalizations.of(context);
    return confirm(
      context,
      title: loc.confirmDeleteTitle,
      body: body ?? loc.confirmDeleteBody(itemName),
      confirmLabel: loc.delete,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
  }

  /// Delete-patient confirmation (includes warning about associated records).
  static Future<bool> confirmDeletePatient(
    BuildContext context, {
    required String patientName,
  }) {
    final loc = AppLocalizations.of(context);
    return confirm(
      context,
      title: loc.confirmDeletePatientTitle,
      body: loc.confirmDeletePatientBody(patientName),
      confirmLabel: loc.delete,
      destructive: true,
      icon: Icons.person_remove_outlined,
    );
  }

  /// Cancel-appointment confirmation.
  static Future<bool> confirmCancelAppointment(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return confirm(
      context,
      title: loc.confirmCancelApptTitle,
      body: loc.confirmCancelApptBody,
      confirmLabel: loc.yes,
      cancelLabel: loc.no,
      destructive: true,
      icon: Icons.cancel_outlined,
    );
  }

  /// Complete-consultation confirmation (finalizes + sends report).
  static Future<bool> confirmCompleteConsultation(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return confirm(
      context,
      title: loc.confirmCompleteConsultationTitle,
      body: loc.confirmCompleteConsultationBody,
      confirmLabel: loc.completeConsultationBtn,
      icon: Icons.check_circle_outline_rounded,
      accentColor: Colors.green.shade600,
    );
  }

  /// Mark-as-no-show confirmation.
  static Future<bool> confirmMarkNoShow(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return confirm(
      context,
      title: loc.confirmMarkNoShowTitle,
      body: loc.confirmMarkNoShowBody,
      confirmLabel: loc.markAsNoShow,
      destructive: true,
      icon: Icons.person_off_outlined,
    );
  }

  /// Sign-out confirmation.
  static Future<bool> confirmSignOut(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return confirm(
      context,
      title: loc.signOutConfirmTitle,
      body: loc.signOutConfirmBody,
      confirmLabel: loc.signOut,
      destructive: true,
      icon: Icons.logout_rounded,
    );
  }

  /// Unsaved-changes warning before navigation away from a form.
  static Future<bool> confirmLeaveWithoutSaving(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return confirm(
      context,
      title: loc.leaveWithoutSaving,
      body: loc.warnUnsavedChanges,
      confirmLabel: loc.leaveWithoutSaving,
      cancelLabel: loc.keepEditing,
      destructive: true,
      icon: Icons.warning_amber_rounded,
    );
  }

  // ── Snackbar helpers ────────────────────────────────────────────────────────

  /// Success snackbar (green).
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      _snack(
        message: message,
        color: Colors.green.shade600,
        icon: Icons.check_circle_rounded,
      ),
    );
  }

  /// Error snackbar (red).
  static void showErrorSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      _snack(
        message: message,
        color: Colors.red.shade600,
        icon: Icons.error_outline_rounded,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Warning snackbar (orange).
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      _snack(
        message: message,
        color: Colors.orange.shade700,
        icon: Icons.warning_amber_rounded,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Info snackbar (blue).
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      _snack(
        message: message,
        color: Colors.blue.shade700,
        icon: Icons.info_outline_rounded,
      ),
    );
  }

  // ── Internal builder ────────────────────────────────────────────────────────

  static SnackBar _snack({
    required String message,
    required Color color,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) =>
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
      );
}
