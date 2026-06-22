// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_settings_page.dart
//
// Brought to parity with doctor_settings_page.dart:
//   1. Notifications section REMOVED (matches doctor — not part of this app).
//   2. Dark mode toggle now wired to themeModeProvider — actually switches
//      the whole app's theme (was a "coming soon" no-op before).
//   3. Language picker now wired to localeProvider — actually switches the
//      app's Locale (incl. RTL mirroring for Arabic), not just a saved string.
//   4. Snackbars use the global scaffoldMessengerKey + _autoClearSnack()
//      wrapper so they render ABOVE modals and clear when the modal closes.
//   5. Reports & Export now does a REAL export via share_plus (was a
//      placeholder snackbar saying "Add share_plus to pubspec.yaml" before).
//   6. Change Password now forces logout + redirect to LoginPage after
//      success, same as doctor (old session token shouldn't keep working).
//   7. All strings localized via AppLocalizations.
//   8. "Linked Assistants" + "Default Fees" (doctor-only concepts) replaced
//      with "Linked Doctor" (assistant-only), unchanged from before.
//   9. Neutral surface/text/divider colors now read from
//      Theme.of(context).colorScheme — exactly like doctor_settings_page.dart
//      — so dark mode works identically everywhere. AssistantThemeData is
//      only used for the few non-colorScheme tokens (textM, bgInput) that
//      doctor_settings_page.dart also keeps on its own DoctorThemeData.
//      Brand colors (green, urgent, success, etc.) stay as static
//      AssistantTheme constants — identity colors, not theme-neutral.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/providers/locale_provider.dart';
import 'package:Hakim/providers/theme_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/services/settings_service.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/views/assistant/assistant_edit_profile_page.dart';
import 'package:Hakim/views/auths/login_page.dart';
import 'package:Hakim/widgets/assistant/assistant_shared_widgets.dart';

typedef _T = AssistantTheme;

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — called from AssistantInterface
// ─────────────────────────────────────────────────────────────────────────────

void showAssistantSettings(BuildContext context, UserProfile assistantProfile) {
  // Captured here — `context` is inside AssistantInterface's Theme(...)
  // wrap, so this resolves to the dedicated Assistant theme. showModalBottomSheet
  // inserts its content into the Navigator's Overlay, which sits OUTSIDE that
  // Theme() wrap, so we must explicitly re-apply it on the sheet itself.
  final assistantTheme = Theme.of(context);
  _autoClearSnack(
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: assistantTheme,
        child: _AssistantSettingsSheet(assistantProfile: assistantProfile),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Snackbar helper — uses the global key so it renders ABOVE any modal
// ─────────────────────────────────────────────────────────────────────────────

void _showSnack(String msg, {bool err = false}) {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? _T.urgent : _T.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
}

// ── Clear any lingering snackbar the instant a dialog/sheet closes ─────────
Future<T?> _autoClearSnack<T>(Future<T?> future) {
  return future.whenComplete(
    () => scaffoldMessengerKey.currentState?.clearSnackBars(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AssistantSettingsSheet extends ConsumerStatefulWidget {
  final UserProfile assistantProfile;
  const _AssistantSettingsSheet({required this.assistantProfile, Key? key})
    : super(key: key);

  @override
  ConsumerState<_AssistantSettingsSheet> createState() =>
      _AssistantSettingsSheetState();
}

class _AssistantSettingsSheetState
    extends ConsumerState<_AssistantSettingsSheet> {
  // ── Local prefs state ───────────────────────────────────────────────────
  String _language = 'English';
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SettingsService.loadAllPrefs();
    if (!mounted) return;
    final savedDark = prefs['dark_mode'] as bool? ?? false;
    setState(() {
      _language = prefs['language'] as String? ?? 'English';
      _darkMode = savedDark;
    });
    // Sync provider with persisted value on every open — same as doctor.
    ref.read(themeModeProvider.notifier).state = savedDark
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _T.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: _T.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.settingsTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Scrollable content ──────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  // ── Profile ───────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.person_rounded,
                        iconColor: _T.green,
                        iconBg: _T.green.withOpacity(0.10),
                        title: loc.profile,
                        subtitle: widget.assistantProfile.email,
                        onTap: () => _showProfileSheet(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Change Password ───────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_rounded,
                        iconColor: const Color(0xFF6A1B9A),
                        iconBg: const Color(0xFF6A1B9A).withOpacity(0.10),
                        title: loc.changePassword,
                        subtitle: loc.changePasswordSubtitle,
                        onTap: () => _showChangePassword(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Linked Doctor ──────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.medical_services_rounded,
                        iconColor: const Color(0xFF0277BD),
                        iconBg: const Color(0xFF0277BD).withOpacity(0.10),
                        title: loc.linkedDoctor,
                        subtitle: loc.linkedDoctorSubtitle,
                        onTap: () => _showLinkedDoctor(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Appearance ─────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.palette_rounded,
                        iconColor: const Color(0xFF6A1B9A),
                        iconBg: const Color(0xFF6A1B9A).withOpacity(0.10),
                        title: loc.appearance,
                        subtitle:
                            '$_language · ${_darkMode ? loc.darkMode : loc.lightMode}',
                        onTap: () => _showAppearanceSheet(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Reports & Export ───────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.file_download_rounded,
                        iconColor: const Color(0xFF2E7D32),
                        iconBg: const Color(0xFF2E7D32).withOpacity(0.10),
                        title: loc.reportsExport,
                        subtitle: loc.reportsExportSubtitle,
                        onTap: () => _showExportOptions(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Sign Out ────────────────────────────────────────────
                  GestureDetector(
                    onTap: () => _confirmLogout(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _T.urgentBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _T.urgent.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: _T.urgent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            loc.signOut,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _T.urgent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile sub-sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showProfileSheet() {
    final p = widget.assistantProfile;
    final name = p.fullName.isEmpty ? p.username : p.fullName;
    final outerContext = context;
    final assistantTheme = Theme.of(context);

    _autoClearSnack(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx);
          final cs = Theme.of(context).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ── Gradient header ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: _T.gGreen,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: AssistantAvatar(name: name, size: 64),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                loc.assistantRoleLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Info rows ─────────────────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AssistantTheme.cardOf(ctx),
                      child: Column(
                        children: [
                          _ProfileRow(loc.emailLabel, p.email),
                          _ProfileRow(loc.fullNameLabel, name),
                          _ProfileRow(
                            loc.genderLabel,
                            p.gender.isEmpty
                                ? loc.notAvailable
                                : p.gender[0].toUpperCase() +
                                      p.gender.substring(1).toLowerCase(),
                          ),
                          _ProfileRow(
                            loc.dateOfBirthLabel,
                            p.birthDate != null
                                ? DateFormat('dd MMM yyyy').format(p.birthDate!)
                                : loc.notAvailable,
                          ),
                          _ProfileRow(loc.roleLabel, loc.assistantRoleLabel),
                          if ((p.clinicName ?? '').isNotEmpty)
                            _ProfileRow(loc.clinicLabel, p.clinicName!),
                          _ProfileRow(
                            loc.joinedLabel,
                            DateFormat('dd MMM yyyy').format(p.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(loc.editProfile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _T.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          outerContext,
                          MaterialPageRoute(
                            builder: (_) => Theme(
                              data: assistantTheme,
                              child: AssistantEditProfilePage(profile: p),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Change Password dialog
  // ─────────────────────────────────────────────────────────────────────────

  void _showChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    _autoClearSnack(
      showDialog(
        context: context,
        barrierDismissible: !saving,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDlg) {
            final loc = AppLocalizations.of(ctx);
            final at = Theme.of(context).extension<AssistantThemeData>()!;
            return Theme(
              data: Theme.of(context),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF6A1B9A),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(loc.changePassword),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldCtrl,
                      obscureText: obscureOld,
                      decoration: _T.inpOf(
                        ctx,
                        loc.currentPassword,
                        pre: Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: at.textM,
                        ),
                        suf: IconButton(
                          icon: Icon(
                            obscureOld
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                            color: at.textM,
                          ),
                          onPressed: () =>
                              setDlg(() => obscureOld = !obscureOld),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newCtrl,
                      obscureText: obscureNew,
                      decoration: _T.inpOf(
                        ctx,
                        loc.newPassword,
                        pre: Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: at.textM,
                        ),
                        suf: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                            color: at.textM,
                          ),
                          onPressed: () =>
                              setDlg(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: obscureConfirm,
                      decoration: _T.inpOf(
                        ctx,
                        loc.confirmNewPassword,
                        pre: Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: at.textM,
                        ),
                        suf: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                            color: at.textM,
                          ),
                          onPressed: () =>
                              setDlg(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(ctx),
                    child: Text(loc.cancel),
                  ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (oldCtrl.text.isEmpty ||
                                newCtrl.text.isEmpty ||
                                confirmCtrl.text.isEmpty) {
                              _showSnack(loc.allFieldsRequired, err: true);
                              return;
                            }
                            if (newCtrl.text != confirmCtrl.text) {
                              _showSnack(loc.passwordsDoNotMatch, err: true);
                              return;
                            }
                            if (newCtrl.text.length < 6) {
                              _showSnack(loc.passwordMinLength, err: true);
                              return;
                            }
                            setDlg(() => saving = true);
                            try {
                              await ApiService.changePassword(
                                oldPassword: oldCtrl.text,
                                newPassword: newCtrl.text,
                              );
                              // Capture the ROOT navigator BEFORE closing
                              // anything — once we pop the dialog/sheet, this
                              // `context` is no longer attached to the tree.
                              final rootNav = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              if (ctx.mounted) Navigator.pop(ctx); // dialog
                              if (mounted) Navigator.pop(context); // sheet
                              _showSnack(loc.passwordChangedSignIn);
                              // Force fresh login so the new password takes
                              // effect immediately.
                              await ref
                                  .read(assistantViewModelProvider.notifier)
                                  .logout();
                              rootNav.pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                                (_) => false,
                              );
                            } catch (e) {
                              _showSnack(ApiService.extractError(e), err: true);
                            } finally {
                              if (ctx.mounted) setDlg(() => saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(loc.update),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Linked Doctor sub-sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showLinkedDoctor() {
    final assistantTheme = Theme.of(context);
    _autoClearSnack(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Theme(
          data: assistantTheme,
          child: _LinkedDoctorSheet(assistantProfile: widget.assistantProfile),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Appearance sub-sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showAppearanceSheet() {
    _autoClearSnack(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setSheet) {
            final loc = AppLocalizations.of(ctx);
            final cs = Theme.of(context).colorScheme;
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A1B9A).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.palette_rounded,
                            color: Color(0xFF6A1B9A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          loc.appearance,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _SectionCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF0277BD),
                          iconBg: const Color(0xFF0277BD).withOpacity(0.10),
                          title: loc.language,
                          subtitle: _language,
                          onTap: () {
                            Navigator.pop(ctx);
                            _showLanguagePicker();
                          },
                        ),
                        const _Divider(),
                        _SettingsToggle(
                          icon: Icons.dark_mode_rounded,
                          iconColor: const Color(0xFF37474F),
                          iconBg: const Color(0xFF37474F).withOpacity(0.10),
                          title: loc.darkMode,
                          subtitle: _darkMode ? loc.enabled : loc.disabled,
                          value: _darkMode,
                          onChanged: (v) async {
                            // 1. Update local state for parent sheet subtitle.
                            setState(() => _darkMode = v);
                            // 2. Refresh this nested sheet's toggle.
                            setSheet(() {});
                            // 3. Persist the preference.
                            await SettingsService.setBool('dark_mode', v);
                            // 4. Update the global theme provider →
                            //    MaterialApp.themeMode rebuilds the whole app.
                            ref.read(themeModeProvider.notifier).state = v
                                ? ThemeMode.dark
                                : ThemeMode.light;
                            // 5. Confirm via global snackbar.
                            _showSnack(
                              v ? loc.darkModeEnabled : loc.lightModeEnabled,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Language picker
  // ─────────────────────────────────────────────────────────────────────────

  void _showLanguagePicker() {
    final languages = ['English', 'العربية'];
    _autoClearSnack(
      showDialog(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx);
          final at = Theme.of(context).extension<AssistantThemeData>()!;
          final cs = Theme.of(context).colorScheme;
          return Theme(
            data: Theme.of(context),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0277BD).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      color: Color(0xFF0277BD),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(loc.language),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: languages.map((lang) {
                  final isSelected = _language == lang;
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() => _language = lang);
                      await SettingsService.setString('language', lang);
                      // ── Actually switch the app's locale ──────────────────
                      // Flipping localeProvider rebuilds the ENTIRE app under
                      // the new locale, including automatic RTL mirroring for
                      // Arabic — not just a stored preference string.
                      final newLocale = lang == 'العربية'
                          ? const Locale('ar')
                          : const Locale('en');
                      await ref
                          .read(localeProvider.notifier)
                          .setLocale(newLocale);
                      _showSnack(
                        loc.languageSetTo(
                          lang == 'العربية' ? loc.arabic : loc.english,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _T.green.withOpacity(0.08)
                            : at.bgInput,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _T.green : cs.outline,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            lang,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? _T.green : cs.onSurface,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: _T.green,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Reports & Export sub-sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showExportOptions() {
    final assistantTheme = Theme.of(context);
    _autoClearSnack(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Theme(
          data: assistantTheme,
          child: _AssistantExportSheet(
            assistantProfile: widget.assistantProfile,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────────────────────────────────

  void _confirmLogout() {
    final assistantTheme = Theme.of(context);
    _autoClearSnack(
      showDialog(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx);
          return Theme(
            data: assistantTheme,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(loc.signOutConfirmTitle),
              content: Text(loc.signOutConfirmBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(loc.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final rootNav = Navigator.of(context, rootNavigator: true);
                    Navigator.pop(ctx); // close dialog
                    Navigator.pop(context); // close settings sheet
                    await ref
                        .read(assistantViewModelProvider.notifier)
                        .logout();
                    rootNav.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.urgent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(loc.signOut),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Linked Doctor sub-sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LinkedDoctorSheet extends ConsumerStatefulWidget {
  final UserProfile assistantProfile;
  const _LinkedDoctorSheet({required this.assistantProfile, Key? key})
    : super(key: key);

  @override
  ConsumerState<_LinkedDoctorSheet> createState() => _LinkedDoctorSheetState();
}

class _LinkedDoctorSheetState extends ConsumerState<_LinkedDoctorSheet> {
  Map<String, dynamic>? _doctor;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      // Use cached activeDoctor from ViewModel first (fast path).
      final state = ref.read(assistantViewModelProvider);
      if (state.activeDoctor != null) {
        if (mounted) {
          setState(() {
            _doctor = state.activeDoctor;
            _loading = false;
          });
        }
        return;
      }
      // Fallback: fetch by doctorId from profile.
      final did = int.tryParse(widget.assistantProfile.doctorId ?? '');
      if (did != null && did > 0) {
        final d = await ApiService.getDoctorById(did);
        if (mounted) {
          setState(() {
            _doctor = d;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiService.extractError(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0277BD).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Color(0xFF0277BD),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.linkedDoctor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: _T.green,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _error != null
                ? _ErrorCard(
                    message: _error!,
                    retryLabel: loc.retry,
                    onRetry: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _fetch();
                    },
                  )
                : _doctor == null
                ? _EmptyCard(
                    icon: Icons.person_off_rounded,
                    title: loc.noDoctorLinked,
                    subtitle: loc.noDoctorLinkedSub,
                  )
                : _DoctorCard(doctor: _doctor!, activeLabel: loc.active),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assistant Export sub-sheet — now does a REAL export via share_plus
// ─────────────────────────────────────────────────────────────────────────────

class _AssistantExportSheet extends ConsumerStatefulWidget {
  final UserProfile assistantProfile;
  const _AssistantExportSheet({required this.assistantProfile, Key? key})
    : super(key: key);

  @override
  ConsumerState<_AssistantExportSheet> createState() =>
      _AssistantExportSheetState();
}

class _AssistantExportSheetState extends ConsumerState<_AssistantExportSheet> {
  String? _exporting;

  Future<void> _export(String type) async {
    setState(() => _exporting = type);
    final state = ref.read(assistantViewModelProvider);
    final loc = AppLocalizations.of(context);
    try {
      switch (type) {
        case 'appointments':
          await _exportAppointments(state.appointments);
          break;
        case 'patients':
          await _exportPatients(state.patients);
          break;
      }
      _showSnack(loc.reportGeneratedSuccess);
    } catch (e) {
      _showSnack(loc.exportFailed(e.toString()), err: true);
    } finally {
      if (mounted) setState(() => _exporting = null);
    }
  }

  Future<void> _exportAppointments(
    List<Map<String, dynamic>> appointments,
  ) async {
    final buffer = StringBuffer();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    buffer.writeln('APPOINTMENTS REPORT');
    buffer.writeln('Assistant: ${widget.assistantProfile.fullName}');
    buffer.writeln('Generated: $now');
    buffer.writeln('─' * 50);
    buffer.writeln();
    for (final a in appointments) {
      final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
      final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
      final name = '$fn $ln'.trim().isEmpty ? 'Unknown' : '$fn $ln'.trim();
      final dt = a['start_time'] != null
          ? DateFormat(
              'dd MMM yyyy  hh:mm a',
            ).format(DateTime.parse(a['start_time'].toString()).toLocal())
          : 'N/A';
      final typeRaw = a['appointment_type'];
      final type = typeRaw is Map
          ? (typeRaw['name'] ?? 'Consultation').toString()
          : (a['appointment_type_name'] ?? typeRaw ?? 'Consultation')
                .toString();
      buffer
        ..writeln('Patient   : $name')
        ..writeln('Date/Time : $dt')
        ..writeln('Type      : $type')
        ..writeln('Status    : ${a['status'] ?? ''}')
        ..writeln(
          'Fee       : ${a['fee'] ?? 0} EGP  '
          '[${a['is_paid'] == true ? 'Paid' : 'Unpaid'}]',
        )
        ..writeln('─' * 50);
    }
    buffer.writeln('\nTotal appointments: ${appointments.length}');
    final dir = await getTemporaryDirectory();
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final file = File('${dir.path}/hakim_appointments_$date.txt');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Hakim — Appointments Report');
  }

  Future<void> _exportPatients(List<Map<String, dynamic>> patients) async {
    final buffer = StringBuffer();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    buffer.writeln('PATIENTS LIST');
    buffer.writeln('Assistant: ${widget.assistantProfile.fullName}');
    buffer.writeln('Generated: $now');
    buffer.writeln('─' * 50);
    buffer.writeln();
    for (final p in patients) {
      final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
      final diseases = (p['chronic_diseases'] as List? ?? []).join(', ');
      buffer.writeln('Name     : ${name.isEmpty ? 'Unknown' : name}');
      buffer.writeln('Phone    : ${p['phone_number'] ?? p['phone'] ?? 'N/A'}');
      buffer.writeln('Gender   : ${p['gender'] ?? 'N/A'}');
      buffer.writeln('DOB      : ${p['date_of_birth'] ?? 'N/A'}');
      if (diseases.isNotEmpty) buffer.writeln('Diseases : $diseases');
      buffer.writeln('─' * 50);
    }
    buffer.writeln('\nTotal patients: ${patients.length}');
    final dir = await getTemporaryDirectory();
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final file = File('${dir.path}/hakim_patients_$date.txt');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Hakim — Patient List');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(assistantViewModelProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final exportOptions = [
      (
        id: 'appointments',
        icon: Icons.calendar_month_rounded,
        color: _T.green,
        bg: _T.green.withOpacity(0.10),
        title: loc.appointmentsReport,
        subtitle: loc.appointmentsCount(state.appointments.length),
      ),
      (
        id: 'patients',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF0277BD),
        bg: const Color(0xFF0277BD).withOpacity(0.10),
        title: loc.patientList,
        subtitle: loc.patientsCount(state.patients.length),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.file_download_rounded,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.reportsExport,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: exportOptions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final opt = exportOptions[i];
              final isLoading = _exporting == opt.id;
              return GestureDetector(
                onTap: isLoading ? null : () => _export(opt.id),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _T.green.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: opt.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(opt.icon, color: opt.color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: opt.color,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: opt.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.download_rounded,
                                size: 14,
                                color: opt.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                loc.export,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: opt.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _T.green.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: at.textM, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _T.green,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: Theme.of(context).colorScheme.outline),
  );
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final String activeLabel;
  const _DoctorCard({required this.doctor, required this.activeLabel, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fn = (doctor['first_name'] ?? '').toString().trim();
    final ln = (doctor['last_name'] ?? '').toString().trim();
    final name = '$fn $ln'.trim().isEmpty ? 'Doctor' : '$fn $ln'.trim();
    final spec = (doctor['specialization'] ?? '').toString();
    final clinic = (doctor['clinic_name'] ?? '').toString();
    final email = (doctor['email'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _T.green.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AssistantAvatar(name: name, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. $name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    if (spec.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        spec,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _T.greenPale,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _T.green,
                  ),
                ),
              ),
            ],
          ),
          if (email.isNotEmpty || clinic.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: cs.outline),
            const SizedBox(height: 14),
            if (email.isNotEmpty) _InfoRow(Icons.email_outlined, email),
            if (clinic.isNotEmpty)
              _InfoRow(Icons.local_hospital_rounded, clinic),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: at.textM),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  const _ErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _T.urgent, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: at.textM),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: at.textM),
          ),
        ],
      ),
    );
  }
}
