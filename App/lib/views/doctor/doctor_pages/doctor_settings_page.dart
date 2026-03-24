// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_settings_page.dart
//
// Full-featured settings bottom sheet for the Doctor module.
// Sections: Profile · Change Password · Linked Assistants ·
//           Notifications · Language · Theme · Reports & Export
//
// Architecture:
//   - Opens as a showModalBottomSheet from DoctorInterface
//   - Reads DoctorState via Riverpod (read-only — no business logic here)
//   - All API calls delegated to DoctorViewModel / ApiService via callbacks
//   - All local prefs delegated to SettingsService
// ─────────────────────────────────────────────────────────────────────────────

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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DoctorSettingsSheet(doctorProfile: doctorProfile),
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
  // ── Local prefs state ───────────────────────────────────────────────────────
  bool _notifAppointments = true;
  bool _notifUrgent = true;
  bool _notifDailySummary = false;
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
    setState(() {
      _notifAppointments = prefs['notif_appointments'] as bool? ?? true;
      _notifUrgent = prefs['notif_urgent'] as bool? ?? true;
      _notifDailySummary = prefs['notif_daily_summary'] as bool? ?? false;
      _language = prefs['language'] as String? ?? 'English';
      _darkMode = prefs['dark_mode'] as bool? ?? false;
    });
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? _T.urgent : _T.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _T.bgPage,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _T.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _T.navy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: _T.navy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _T.textH,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Scrollable content ───────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  // ── Profile ─────────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.person_rounded,
                        iconColor: _T.navy,
                        iconBg: _T.navy.withOpacity(0.10),
                        title: 'Profile',
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

                  // ── Change Password ──────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_rounded,
                        iconColor: const Color(0xFF6A1B9A),
                        iconBg: const Color(0xFF6A1B9A).withOpacity(0.10),
                        title: 'Change Password',
                        subtitle: 'Update your login password',
                        onTap: () => _showChangePassword(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Linked Assistants ────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.people_alt_rounded,
                        iconColor: _T.teal,
                        iconBg: _T.teal.withOpacity(0.10),
                        title: 'Linked Assistants',
                        subtitle: 'View assistants linked to your account',
                        onTap: () => _showLinkedAssistants(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Notifications ────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_rounded,
                        iconColor: _T.info,
                        iconBg: _T.infoBg,
                        title: 'Notifications',
                        subtitle: _notifSubtitle,
                        onTap: () => _showNotificationsSheet(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Appearance ───────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.palette_rounded,
                        iconColor: const Color(0xFF6A1B9A),
                        iconBg: const Color(0xFF6A1B9A).withOpacity(0.10),
                        title: 'Appearance',
                        subtitle:
                            '$_language · ${_darkMode ? "Dark" : "Light"} Mode',
                        onTap: () => _showAppearanceSheet(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Reports & Export ─────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.file_download_rounded,
                        iconColor: const Color(0xFF2E7D32),
                        iconBg: const Color(0xFF2E7D32).withOpacity(0.10),
                        title: 'Reports & Export',
                        subtitle: 'Export appointments, patients & finance',
                        onTap: () => _showExportOptions(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Default Fees ─────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.payments_rounded,
                        iconColor: const Color(0xFFE65100),
                        iconBg: const Color(0xFFE65100).withOpacity(0.10),
                        title: 'Default Fees',
                        subtitle: 'Set consultation & revisit fee defaults',
                        onTap: () => _showFeeDefaults(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Sign Out ─────────────────────────────────────────────
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
                          const Text(
                            'Sign Out',
                            style: TextStyle(
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

  String get _notifSubtitle {
    final active = [
      if (_notifAppointments) 'Reminders',
      if (_notifUrgent) 'Urgent',
      if (_notifDailySummary) 'Summary',
    ];
    return active.isEmpty ? 'All notifications off' : active.join(' · ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Notifications sub-sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: _T.bgPage,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
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
                    color: _T.divider,
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
                        color: _T.infoBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: _T.info,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _T.textH,
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
                    _SettingsToggle(
                      icon: Icons.calendar_today_rounded,
                      iconColor: _T.info,
                      iconBg: _T.infoBg,
                      title: 'Appointment Reminders',
                      subtitle: 'Notify before each appointment',
                      value: _notifAppointments,
                      onChanged: (v) async {
                        setState(() => _notifAppointments = v);
                        setSheet(() {});
                        await SettingsService.setBool('notif_appointments', v);
                      },
                    ),
                    _Divider(),
                    _SettingsToggle(
                      icon: Icons.warning_amber_rounded,
                      iconColor: _T.urgent,
                      iconBg: _T.urgentBg,
                      title: 'Urgent Alerts',
                      subtitle: 'Notify when urgent appointment added',
                      value: _notifUrgent,
                      onChanged: (v) async {
                        setState(() => _notifUrgent = v);
                        setSheet(() {});
                        await SettingsService.setBool('notif_urgent', v);
                      },
                    ),
                    _Divider(),
                    _SettingsToggle(
                      icon: Icons.summarize_rounded,
                      iconColor: _T.success,
                      iconBg: _T.successBg,
                      title: 'Daily Summary',
                      subtitle: 'End-of-day appointment summary',
                      value: _notifDailySummary,
                      onChanged: (v) async {
                        setState(() => _notifDailySummary = v);
                        setSheet(() {});
                        await SettingsService.setBool('notif_daily_summary', v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Appearance sub-sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showAppearanceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: _T.bgPage,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
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
                    color: _T.divider,
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
                    const Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _T.textH,
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
                      title: 'Language',
                      subtitle: _language,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showLanguagePicker();
                      },
                    ),
                    _Divider(),
                    _SettingsToggle(
                      icon: Icons.dark_mode_rounded,
                      iconColor: const Color(0xFF37474F),
                      iconBg: const Color(0xFF37474F).withOpacity(0.10),
                      title: 'Dark Mode',
                      subtitle: 'Coming soon',
                      value: _darkMode,
                      onChanged: (v) async {
                        setState(() => _darkMode = v);
                        setSheet(() {});
                        await SettingsService.setBool('dark_mode', v);
                        _snack(
                          'Dark mode will be available in a future update',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
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

    showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
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
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: obscureOld,
                decoration: _T.inp(
                  'Current Password',
                  pre: const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: _T.textM,
                  ),
                  suf: IconButton(
                    icon: Icon(
                      obscureOld
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                      color: _T.textM,
                    ),
                    onPressed: () => setDlg(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                decoration: _T.inp(
                  'New Password',
                  pre: const Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: _T.textM,
                  ),
                  suf: IconButton(
                    icon: Icon(
                      obscureNew
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                      color: _T.textM,
                    ),
                    onPressed: () => setDlg(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscureConfirm,
                decoration: _T.inp(
                  'Confirm New Password',
                  pre: const Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: _T.textM,
                  ),
                  suf: IconButton(
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                      color: _T.textM,
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (oldCtrl.text.isEmpty ||
                          newCtrl.text.isEmpty ||
                          confirmCtrl.text.isEmpty) {
                        _snack('All fields are required', err: true);
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        _snack('New passwords do not match', err: true);
                        return;
                      }
                      if (newCtrl.text.length < 6) {
                        _snack(
                          'New password must be at least 6 characters',
                          err: true,
                        );
                        return;
                      }
                      setDlg(() => saving = true);
                      try {
                        await ApiService.changePassword(
                          oldPassword: oldCtrl.text,
                          newPassword: newCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack('Password changed successfully!');
                      } catch (e) {
                        _snack(ApiService.extractError(e), err: true);
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
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Linked Assistants bottom sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showLinkedAssistants() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LinkedAssistantsSheet(doctorId: widget.doctorProfile.id),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Language picker
  // ─────────────────────────────────────────────────────────────────────────

  void _showLanguagePicker() {
    final languages = ['English', 'العربية'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            const Text(
              'Language',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
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
                if (lang == 'العربية') {
                  _snack('Arabic language support coming soon!');
                } else {
                  _snack('Language set to English');
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _T.navy.withOpacity(0.08) : _T.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _T.navy : _T.divider,
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
                        color: isSelected ? _T.navy : _T.textH,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _T.navy,
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
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Reports & Export bottom sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportSheet(doctorProfile: widget.doctorProfile),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            const Text(
              'Default Fees',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: consultCtrl,
              keyboardType: TextInputType.number,
              decoration: _T.inp(
                'Consultation Fee (EGP)',
                pre: const Icon(
                  Icons.medical_services_rounded,
                  size: 18,
                  color: _T.textM,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: revisitCtrl,
              keyboardType: TextInputType.number,
              decoration: _T.inp(
                'Revisit Fee (EGP)',
                pre: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: _T.textM,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final consult = double.tryParse(consultCtrl.text) ?? 200;
              final revisit = double.tryParse(revisitCtrl.text) ?? 100;
              await SettingsService.setConsultationFee(consult);
              await SettingsService.setRevisitFee(revisit);
              if (ctx.mounted) Navigator.pop(ctx);
              _snack('Default fees updated!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────────────────────────────────

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Capture the ROOT navigator BEFORE closing any sheets/dialogs.
              // Once Navigator.pop() executes, `context` belongs to a disposed
              // widget and pushAndRemoveUntil would silently fail.
              final rootNav = Navigator.of(context, rootNavigator: true);
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close settings sheet
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Linked Assistants sub-sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LinkedAssistantsSheet extends StatefulWidget {
  final String doctorId;
  const _LinkedAssistantsSheet({required this.doctorId, Key? key})
    : super(key: key);

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
      // Filter to only assistants linked to this doctor
      final filtered = List<Map<String, dynamic>>.from(all).where((a) {
        final did = (a['doctor_id'] ?? a['doctor']?['id'] ?? '').toString();
        return did == widget.doctorId;
      }).toList();
      if (mounted)
        setState(() {
          _assistants = filtered;
          _loading = false;
        });
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: _T.bgPage,
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
                color: _T.divider,
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
                const Text(
                  'Linked Assistants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _T.textH,
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
                          style: const TextStyle(color: _T.textS),
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
                          child: const Text('Retry'),
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
                          color: _T.textM,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No assistants linked',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _T.textS,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Assistants assigned to your clinic will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: _T.textM),
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
                          color: _T.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _T.navy.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _T.textH,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    a['email'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _T.textS,
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
                              child: const Text(
                                'Active',
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

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? _T.urgent : _T.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _export(String type) async {
    setState(() => _exporting = type);
    final state = ref.read(doctorViewModelProvider);

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
      _snack('Report generated successfully!');
    } catch (e) {
      _snack('Export failed: ${e.toString()}', err: true);
    } finally {
      if (mounted) setState(() => _exporting = null);
    }
  }

  /// Builds a plain-text appointments report and shares it.
  /// Replace body with pdf package calls for a real PDF.
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
      final status = (a['status'] ?? '').toString();
      final fee = (a['fee'] ?? 0).toString();
      final paid = a['is_paid'] == true ? 'Paid' : 'Unpaid';
      final type = a['appointment_type_name'] ?? 'Consultation';
      buffer.writeln('Patient   : $name');
      buffer.writeln('Date/Time : $dt');
      buffer.writeln('Type      : $type');
      buffer.writeln('Status    : $status');
      buffer.writeln('Fee       : $fee EGP  [$paid]');
      buffer.writeln('─' * 50);
    }
    buffer.writeln('\nTotal appointments: ${appointments.length}');

    // Share as text — swap this for share_plus SharePlus.instance.share()
    // once you add the package to pubspec.yaml
    _snack(
      'Appointments export ready (${appointments.length} records). '
      'Add share_plus to pubspec.yaml to enable file sharing.',
    );
  }

  Future<void> _exportPatients(List<Map<String, dynamic>> patients) async {
    _snack(
      'Patients export ready (${patients.length} patients). '
      'Add share_plus to pubspec.yaml to enable file sharing.',
    );
  }

  Future<void> _exportFinance(List<Map<String, dynamic>> appointments) async {
    double total = 0, paid = 0;
    for (final a in appointments) {
      if ((a['status'] ?? '').toUpperCase() == 'CANCELLED') continue;
      final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0;
      total += fee;
      if (a['is_paid'] == true) paid += fee;
    }
    final unpaid = total - paid;
    _snack(
      'Finance: Total ${total.toStringAsFixed(0)} EGP | '
      'Paid ${paid.toStringAsFixed(0)} | '
      'Unpaid ${unpaid.toStringAsFixed(0)}. '
      'Add share_plus to export.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorViewModelProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final exportOptions = [
      (
        id: 'appointments',
        icon: Icons.calendar_month_rounded,
        color: _T.navy,
        bg: _T.navy.withOpacity(0.10),
        title: 'Appointments Report',
        subtitle: '${state.appointments.length} appointments',
      ),
      (
        id: 'patients',
        icon: Icons.people_alt_rounded,
        color: _T.teal,
        bg: _T.teal.withOpacity(0.10),
        title: 'Patient List',
        subtitle: '${state.patients.length} patients',
      ),
      (
        id: 'finance',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF2E7D32),
        bg: const Color(0xFF2E7D32).withOpacity(0.10),
        title: 'Finance Report',
        subtitle: 'Revenue summary',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _T.bgPage,
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
                color: _T.divider,
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports & Export',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _T.textH,
                        ),
                      ),
                      Text(
                        'Add share_plus to pubspec.yaml to enable downloads',
                        style: TextStyle(fontSize: 10, color: _T.textM),
                      ),
                    ],
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
                    color: _T.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _T.navy.withOpacity(0.06),
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _T.textH,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _T.textS,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _T.navy,
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
                                'Export',
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
// Reusable private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String? header;
  final List<Widget> children;
  const _SectionCard({this.header, required this.children, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.bgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withOpacity(0.06),
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
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _T.textM,
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
  Widget build(BuildContext context) => InkWell(
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _T.textH,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: _T.textS),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _T.textM, size: 20),
        ],
      ),
    ),
  );
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
  Widget build(BuildContext context) => Padding(
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _T.textH,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: _T.textS),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: _T.navy,
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: _T.divider),
  );
}
