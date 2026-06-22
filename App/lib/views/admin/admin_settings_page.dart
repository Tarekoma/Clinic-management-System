// lib/views/admin/admin_settings_page.dart
//
// Admin settings experience — mirrors Doctor and Assistant settings in
// architecture and UX, adapted for the Admin role.
//
// Sections:
//   1. Profile      — read-only view of the admin account
//   2. Change Password
//   3. Appearance   — language + dark mode toggle
//   4. Sign Out
//
// Excluded by design:
//   - Default Fees (doctor-specific)
//   - Linked Assistants / Linked Doctor (role-specific)
//   - Reports & Export (admin has no appointments / patient list in ViewModel)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/admin_providers.dart';
import 'package:Hakim/providers/locale_provider.dart';
import 'package:Hakim/providers/theme_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/services/settings_service.dart';
import 'package:Hakim/utils/admin_theme.dart';
import 'package:Hakim/views/auths/login_page.dart';

typedef _T = AdminTheme;

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — called from AdminInterface's top bar
// ─────────────────────────────────────────────────────────────────────────────

void showAdminSettings(BuildContext context, UserProfile adminProfile) {
  // Capture the admin theme BEFORE entering the Navigator's Overlay — the
  // modal bottom sheet inserts content outside the Theme() wrap in AdminInterface,
  // so we must explicitly re-apply it inside the sheet.
  final adminTheme = Theme.of(context);
  _autoClearSnack(
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: adminTheme,
        child: _AdminSettingsSheet(adminProfile: adminProfile),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Global snackbar helper — renders above modals via scaffoldMessengerKey
// ─────────────────────────────────────────────────────────────────────────────

void _showSnack(String msg, {bool err = false}) {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? _T.urgent : _T.indigo,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
}

// Clears any lingering snackbar the moment a modal closes.
Future<T?> _autoClearSnack<T>(Future<T?> future) {
  return future.whenComplete(
    () => scaffoldMessengerKey.currentState?.clearSnackBars(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main settings sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AdminSettingsSheet extends ConsumerStatefulWidget {
  final UserProfile adminProfile;
  const _AdminSettingsSheet({required this.adminProfile});

  @override
  ConsumerState<_AdminSettingsSheet> createState() =>
      _AdminSettingsSheetState();
}

class _AdminSettingsSheetState extends ConsumerState<_AdminSettingsSheet> {
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
    ref.read(themeModeProvider.notifier).state =
        savedDark ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
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
                    color: _T.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: _T.indigo,
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
                  // ── Profile ──────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.person_rounded,
                        iconColor: _T.indigo,
                        iconBg: _T.indigo.withValues(alpha: 0.10),
                        title: loc.profile,
                        subtitle: widget.adminProfile.email,
                        onTap: () => _showProfileSheet(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Change Password ────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_rounded,
                        iconColor: const Color(0xFF6A1B9A),
                        iconBg: const Color(0xFF6A1B9A).withValues(alpha: 0.10),
                        title: loc.changePassword,
                        subtitle: loc.changePasswordSubtitle,
                        onTap: () => _showChangePassword(),
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
                        iconBg: const Color(0xFF6A1B9A).withValues(alpha: 0.10),
                        title: loc.appearance,
                        subtitle:
                            '$_language · ${_darkMode ? loc.darkMode : loc.lightMode}',
                        onTap: () => _showAppearanceSheet(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Sign Out ───────────────────────────────────────────
                  GestureDetector(
                    onTap: () => _confirmLogout(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _T.urgentBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _T.urgent.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: _T.urgent, size: 20),
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
  // Admin Profile sub-sheet (read-only)
  // ─────────────────────────────────────────────────────────────────────────

  void _showProfileSheet() {
    final p = widget.adminProfile;
    final name = p.fullName.isEmpty ? 'Administrator' : p.fullName;
    final initials = _initials(name);
    final adminTheme = Theme.of(context);

    _autoClearSnack(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Theme(
          data: adminTheme,
          child: Builder(builder: (ctx) {
            final cs = Theme.of(ctx).colorScheme;
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).padding.bottom),
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

                  // ── Gradient header ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: _T.gHeader,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                              width: 2.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'ADMINISTRATOR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Info rows ────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: cs.outline.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: _T.indigoDeep.withValues(alpha: 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _ProfileRow('Email', p.email),
                            _ProfileRow('Full Name', name),
                            _ProfileRow('Role', 'Administrator'),
                            _ProfileRow(
                              'Joined',
                              DateFormat('dd MMM yyyy').format(p.createdAt),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Close button ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurface,
                          side: BorderSide(color: cs.outline),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
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
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDlg) {
            final loc = AppLocalizations.of(ctx);
            final at = Theme.of(context).extension<AdminThemeData>()!;
            return Theme(
              data: Theme.of(context),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_rounded,
                          color: Color(0xFF6A1B9A), size: 18),
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
                      decoration: AdminTheme.inpOf(
                        ctx,
                        loc.currentPassword,
                        pre: Icon(Icons.lock_outline_rounded,
                            size: 18, color: at.textM),
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
                      decoration: AdminTheme.inpOf(
                        ctx,
                        loc.newPassword,
                        pre: Icon(Icons.lock_rounded,
                            size: 18, color: at.textM),
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
                      decoration: AdminTheme.inpOf(
                        ctx,
                        loc.confirmNewPassword,
                        pre: Icon(Icons.lock_rounded,
                            size: 18, color: at.textM),
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
                            // Capture navigator BEFORE any await.
                            final rootNav = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            setDlg(() => saving = true);
                            try {
                              await ApiService.changePassword(
                                oldPassword: oldCtrl.text,
                                newPassword: newCtrl.text,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) Navigator.pop(context);
                              _showSnack(loc.passwordChangedSignIn);
                              await ref
                                  .read(adminViewModelProvider.notifier)
                                  .logout();
                              rootNav.pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                                (_) => false,
                              );
                            } catch (e) {
                              _showSnack(ApiService.extractError(e),
                                  err: true);
                            } finally {
                              if (ctx.mounted) setDlg(() => saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).padding.bottom),
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
                            color: const Color(0xFF6A1B9A)
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.palette_rounded,
                              color: Color(0xFF6A1B9A), size: 20),
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
                          iconBg: const Color(0xFF0277BD).withValues(alpha: 0.10),
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
                          iconBg: const Color(0xFF37474F).withValues(alpha: 0.10),
                          title: loc.darkMode,
                          subtitle: _darkMode ? loc.enabled : loc.disabled,
                          value: _darkMode,
                          onChanged: (v) async {
                            setState(() => _darkMode = v);
                            setSheet(() {});
                            await SettingsService.setBool('dark_mode', v);
                            ref.read(themeModeProvider.notifier).state =
                                v ? ThemeMode.dark : ThemeMode.light;
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
  // Language picker dialog
  // ─────────────────────────────────────────────────────────────────────────

  void _showLanguagePicker() {
    final languages = ['English', 'العربية'];
    _autoClearSnack(
      showDialog(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx);
          final cs = Theme.of(context).colorScheme;
          return Theme(
            data: Theme.of(context),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0277BD).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.language_rounded,
                        color: Color(0xFF0277BD), size: 18),
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
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _T.indigo.withValues(alpha: 0.08)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _T.indigo : cs.outline,
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
                              color: isSelected ? _T.indigo : cs.onSurface,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: _T.indigo, size: 18),
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
  // Logout confirmation dialog
  // ─────────────────────────────────────────────────────────────────────────

  void _confirmLogout() {
    final adminTheme = Theme.of(context);
    _autoClearSnack(
      showDialog(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx);
          return Theme(
            data: adminTheme,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Text(loc.signOutConfirmTitle),
              content: Text(loc.signOutConfirmBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(loc.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final rootNav =
                        Navigator.of(context, rootNavigator: true);
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    await ref
                        .read(adminViewModelProvider.notifier)
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
                        borderRadius: BorderRadius.circular(10)),
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

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AdminTheme.indigoDeep.withValues(alpha: 0.05),
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
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
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
  });

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
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AdminTheme.indigo,
            activeTrackColor: AdminTheme.indigo.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
