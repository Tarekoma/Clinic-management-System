// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_pages/doctor_settings_page.dart
//
// CHANGES vs previous version:
//   1. ALL neutral surface/text/divider colors now read from
//      Theme.of(context).colorScheme — so dark mode works everywhere.
//   2. Snackbar uses the global scaffoldMessengerKey from theme_providers.dart
//      so it appears ABOVE the bottom sheet, not behind it on the dashboard.
//   3. Brand colors (navy, teal, urgent, etc.) remain hardcoded — they are
//      intentional identity colors, not theme-neutral surfaces.
//   4. Notifications feature removed entirely (not part of this app).
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';
import 'package:Hakim/providers/theme_providers.dart';
import 'package:Hakim/providers/locale_provider.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/services/settings_service.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/views/auths/login_page.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_profile_page.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';

typedef _T = DoctorTheme;

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — called from DoctorInterface
// ─────────────────────────────────────────────────────────────────────────────

void showDoctorSettings(BuildContext context, UserProfile doctorProfile) {
  _autoClearSnack(
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoctorSettingsSheet(doctorProfile: doctorProfile),
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
        backgroundColor: err ? _T.urgent : _T.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
}

// ── Clear any lingering snackbar the instant a dialog/sheet closes ─────────
// Without this, a SnackBar shown via the global scaffoldMessengerKey keeps
// floating for its full duration even if the user immediately backs out of
// the modal that triggered it — making the toast appear to "belong" to
// whatever screen is now visible behind it. Wrapping every showDialog /
// showModalBottomSheet call with this ensures the toast is cleared the
// moment that modal closes, for ANY reason (Cancel, barrier tap, success).
Future<T?> _autoClearSnack<T>(Future<T?> future) {
  return future.whenComplete(
    () => scaffoldMessengerKey.currentState?.clearSnackBars(),
  );
}
// ─────────────────────────────────────────────────────────────────────────────
// Main sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorSettingsSheet extends ConsumerStatefulWidget {
  final UserProfile doctorProfile;
  const _DoctorSettingsSheet({required this.doctorProfile, Key? key})
    : super(key: key);

  @override
  ConsumerState<_DoctorSettingsSheet> createState() =>
      _DoctorSettingsSheetState();
}

class _DoctorSettingsSheetState extends ConsumerState<_DoctorSettingsSheet> {
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
    // Sync provider with persisted value on every open
    ref.read(themeModeProvider.notifier).state = savedDark
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface, // ← theme-aware (was _T.bgPage)
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
                color: cs.outline, // ← theme-aware
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
                    color: dt.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: dt.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.settingsTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface, // ← theme-aware
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
                        iconColor: _T.navy,
                        iconBg: _T.navy.withOpacity(0.10),
                        title: loc.profile,
                        subtitle: widget.doctorProfile.email,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorProfilePage(
                                doctorProfile: widget.doctorProfile,
                              ),
                            ),
                          );
                        },
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
                        iconBg: const Color(0xFF6A1B9A).withOpacity(0.10),
                        title: loc.changePassword,
                        subtitle: loc.changePasswordSubtitle,
                        onTap: () => _showChangePassword(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Linked Assistants ──────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.people_alt_rounded,
                        iconColor: _T.teal,
                        iconBg: _T.teal.withOpacity(0.10),
                        title: loc.linkedAssistants,
                        subtitle: loc.linkedAssistantsSubtitle,
                        onTap: () => _showLinkedAssistants(),
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
                  const SizedBox(height: 12),

                  // ── Default Fees ───────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.payments_rounded,
                        iconColor: const Color(0xFFE65100),
                        iconBg: const Color(0xFFE65100).withOpacity(0.10),
                        title: loc.defaultFees,
                        subtitle: loc.defaultFeesSubtitle,
                        onTap: () => _showFeeDefaults(),
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
            final cs = Theme.of(ctx).colorScheme;
            final loc = AppLocalizations.of(ctx)!;
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                            // 1. Update local state for the subtitle in the
                            //    parent settings sheet
                            setState(() => _darkMode = v);
                            // 2. Refresh the nested appearance sheet toggle
                            setSheet(() {});
                            // 3. Persist the preference
                            await SettingsService.setBool('dark_mode', v);
                            // 4. Update the global theme provider →
                            //    MaterialApp.themeMode rebuilds the whole app
                            ref.read(themeModeProvider.notifier).state = v
                                ? ThemeMode.dark
                                : ThemeMode.light;
                            // 5. Confirm to the user via global snackbar
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
            final dt = Theme.of(ctx).extension<DoctorThemeData>()!;
            final loc = AppLocalizations.of(ctx)!;
            return AlertDialog(
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
                        color: dt.textM,
                      ),
                      suf: IconButton(
                        icon: Icon(
                          obscureOld
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: dt.textM,
                        ),
                        onPressed: () => setDlg(() => obscureOld = !obscureOld),
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
                      pre: Icon(Icons.lock_rounded, size: 18, color: dt.textM),
                      suf: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: dt.textM,
                        ),
                        onPressed: () => setDlg(() => obscureNew = !obscureNew),
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
                      pre: Icon(Icons.lock_rounded, size: 18, color: dt.textM),
                      suf: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: dt.textM,
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
                            // ── Activate the new password ──────────────────────
                            // Capture the ROOT navigator BEFORE closing anything —
                            // once we pop the dialog/sheet, this `context` is no
                            // longer attached to the tree and navigation would
                            // silently fail.
                            final rootNav = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            if (ctx.mounted) Navigator.pop(ctx); // close dialog
                            if (mounted) Navigator.pop(context); // close sheet
                            _showSnack(loc.passwordChangedSignIn);
                            // Force a fresh login so the new password takes
                            // effect immediately instead of trusting the old
                            // session token to keep working.
                            await ref
                                .read(doctorViewModelProvider.notifier)
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
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Linked Assistants bottom sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showLinkedAssistants() {
    _autoClearSnack(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _LinkedAssistantsSheet(
          doctorId: widget.doctorProfile.id,
          doctorEmail: widget.doctorProfile.email,
          doctorClinicName: widget.doctorProfile.clinicName,
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
          final cs = Theme.of(ctx).colorScheme;
          final dt = Theme.of(ctx).extension<DoctorThemeData>()!;
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
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
                    // ── Actually switch the app's locale ────────────────────
                    // This is what makes Arabic "active": flipping the
                    // localeProvider rebuilds the ENTIRE app under the new
                    // locale, including automatic RTL mirroring for Arabic —
                    // not just a stored preference string.
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
                          ? dt.accent.withOpacity(0.12)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? dt.accent : cs.outline,
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
                            color: isSelected ? dt.accent : cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: dt.accent,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Reports & Export bottom sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showExportOptions() {
    _autoClearSnack(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ExportSheet(doctorProfile: widget.doctorProfile),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Default Fees dialog
  // ─────────────────────────────────────────────────────────────────────────

  void _showFeeDefaults() async {
    final fees = await SettingsService.loadFeeDefaults();
    if (!mounted) return;

    final consultCtrl = TextEditingController(
      text: fees['consultation']!.toStringAsFixed(0),
    );
    final revisitCtrl = TextEditingController(
      text: fees['revisit']!.toStringAsFixed(0),
    );

    _autoClearSnack(
      showDialog(
        context: context,
        builder: (ctx) {
          final dt = Theme.of(ctx).extension<DoctorThemeData>()!;
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFFE65100),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(loc.defaultFees),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: consultCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _T.inpOf(
                    ctx,
                    loc.consultationFeeLabel,
                    pre: Icon(
                      Icons.medical_services_rounded,
                      size: 18,
                      color: dt.textM,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: revisitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _T.inpOf(
                    ctx,
                    loc.revisitFeeLabel,
                    pre: Icon(Icons.refresh_rounded, size: 18, color: dt.textM),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final consult = double.tryParse(consultCtrl.text) ?? 200;
                  final revisit = double.tryParse(revisitCtrl.text) ?? 100;
                  await SettingsService.setConsultationFee(consult);
                  await SettingsService.setRevisitFee(revisit);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnack(loc.defaultFeesUpdated);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(loc.save),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────────────────────────────────

  void _confirmLogout() {
    _autoClearSnack(
      showDialog(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
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
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  await ref.read(doctorViewModelProvider.notifier).logout();
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
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Linked Assistants sub-sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LinkedAssistantsSheet extends StatefulWidget {
  final String doctorId;
  final String? doctorEmail;
  final String? doctorClinicName;

  const _LinkedAssistantsSheet({
    required this.doctorId,
    this.doctorEmail,
    this.doctorClinicName,
    Key? key,
  }) : super(key: key);

  @override
  State<_LinkedAssistantsSheet> createState() => _LinkedAssistantsSheetState();
}

class _LinkedAssistantsSheetState extends State<_LinkedAssistantsSheet> {
  List<Map<String, dynamic>> _assistants = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final all = await ApiService.getAssistants();
      final filtered = List<Map<String, dynamic>>.from(all).where((a) {
        final did =
            (a['doctor_id'] ??
                    a['doctor']?['id'] ??
                    a['linked_doctor_id'] ??
                    '')
                .toString();
        final dEmail = (a['doctor_email'] ?? a['doctor']?['email'] ?? '')
            .toString();
        final aClinic = (a['clinic_name'] ?? '').toString().toLowerCase();
        final dClinic = (widget.doctorClinicName ?? '').toLowerCase();
        return did == widget.doctorId ||
            (dEmail.isNotEmpty && dEmail == widget.doctorEmail) ||
            (aClinic.isNotEmpty && dClinic.isNotEmpty && aClinic == dClinic);
      }).toList();
      if (mounted) {
        setState(() {
          _assistants = filtered;
          _loading = false;
        });
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
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
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
                    color: _T.teal.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: _T.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.linkedAssistants,
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
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _T.teal,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: _T.urgent,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _fetch();
                          },
                          child: Text(loc.retry),
                        ),
                      ],
                    ),
                  )
                : _assistants.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          size: 48,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.noAssistantsLinked,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.noAssistantsLinkedSub,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _assistants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final a = _assistants[i];
                      final fn = a['first_name'] ?? '';
                      final ln = a['last_name'] ?? '';
                      final name = '$fn $ln'.trim().isEmpty
                          ? (a['username'] ?? 'Assistant')
                          : '$fn $ln'.trim();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Row(
                          children: [
                            DoctorAvatar(name: name, size: 44),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    a['email'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _T.tealPale,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                loc.active,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _T.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export sub-sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ExportSheet extends ConsumerStatefulWidget {
  final UserProfile doctorProfile;
  const _ExportSheet({required this.doctorProfile, Key? key}) : super(key: key);

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  String? _exporting;

  Future<void> _export(String type) async {
    setState(() => _exporting = type);
    final state = ref.read(doctorViewModelProvider);
    final loc = AppLocalizations.of(context)!;
    try {
      switch (type) {
        case 'appointments':
          await _exportAppointments(state.appointments);
          break;
        case 'patients':
          await _exportPatients(state.patients);
          break;
        case 'finance':
          await _exportFinance(state.appointments);
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
    buffer.writeln('Dr. ${widget.doctorProfile.fullName}');
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
    buffer.writeln('Dr. ${widget.doctorProfile.fullName}');
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

  Future<void> _exportFinance(List<Map<String, dynamic>> appointments) async {
    double total = 0, paid = 0;
    final buffer = StringBuffer();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    buffer.writeln('FINANCE REPORT');
    buffer.writeln('Dr. ${widget.doctorProfile.fullName}');
    buffer.writeln('Generated: $now');
    buffer.writeln('─' * 50);
    buffer.writeln();
    for (final a in appointments) {
      if ((a['status'] ?? '').toUpperCase() == 'CANCELLED') continue;
      final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
      final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
      final name = '$fn $ln'.trim().isEmpty ? 'Unknown' : '$fn $ln'.trim();
      final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0;
      final isPaid = a['is_paid'] == true;
      total += fee;
      if (isPaid) paid += fee;
      buffer.writeln(
        '${name.padRight(25)} ${fee.toStringAsFixed(0).padLeft(6)} EGP  '
        '${isPaid ? '[PAID]' : '[UNPAID]'}',
      );
    }
    final unpaid = total - paid;
    buffer
      ..writeln()
      ..writeln('─' * 50)
      ..writeln('Total Revenue : ${total.toStringAsFixed(0)} EGP')
      ..writeln('Collected     : ${paid.toStringAsFixed(0)} EGP')
      ..writeln('Outstanding   : ${unpaid.toStringAsFixed(0)} EGP');
    final dir = await getTemporaryDirectory();
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final file = File('${dir.path}/hakim_finance_$date.txt');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Hakim — Finance Report');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(doctorViewModelProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final exportOptions = [
      (
        id: 'appointments',
        icon: Icons.calendar_month_rounded,
        color: dt.accent,
        bg: dt.accent.withOpacity(0.14),
        title: loc.appointmentsReport,
        subtitle: loc.appointmentsCount(state.appointments.length),
      ),
      (
        id: 'patients',
        icon: Icons.people_alt_rounded,
        color: dt.accentTeal,
        bg: dt.accentTeal.withOpacity(0.14),
        title: loc.patientList,
        subtitle: loc.patientsCount(state.patients.length),
      ),
      (
        id: 'finance',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF2E7D32),
        bg: const Color(0xFF2E7D32).withOpacity(0.10),
        title: loc.financeReport,
        subtitle: loc.revenueSummary,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    border: Border.all(color: cs.outline),
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
// Reusable private widgets — all theme-aware via Theme.of(context)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String? header;
  final List<Widget> children;
  const _SectionCard({this.header, required this.children, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface, // ← theme-aware (was _T.bgCard)
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                header!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant, // ← theme-aware
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ...children,
        ],
      ),
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
    Key? key,
  }) : super(key: key);

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
                      color: cs.onSurface, // ← theme-aware
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant, // ← theme-aware
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant, // ← theme-aware
              size: 20,
            ),
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
                    color: cs.onSurface, // ← theme-aware
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant, // ← theme-aware
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            // Colors come from ThemeData.switchTheme set in AppThemes
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
    child: Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outline, // ← theme-aware
    ),
  );
}
