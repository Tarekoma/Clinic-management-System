// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_settings_page.dart
//
// Full-featured settings bottom sheet for the Assistant module.
// Sections: Profile · Change Password · Linked Doctor ·
//           Notifications · Appearance · Reports & Export
//
// Architecture:
//   - Opens as showModalBottomSheet from AssistantInterface
//   - All API calls via ApiService / AssistantViewModel
//   - All local prefs via SettingsService
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/services/settings_service.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/views/auths/login_page.dart';
import 'package:Hakim/widgets/assistant/assistant_shared_widgets.dart';

typedef _T = AssistantTheme;

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — called from AssistantInterface
// ─────────────────────────────────────────────────────────────────────────────

void showAssistantSettings(BuildContext context, UserProfile assistantProfile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AssistantSettingsSheet(assistantProfile: assistantProfile),
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
        backgroundColor: err ? _T.urgent : _T.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

          // ── Header ─────────────────────────────────────────────────────────
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

          // ── Scrollable content ──────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  // ── Profile ───────────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.person_rounded,
                        iconColor: _T.green,
                        iconBg: _T.green.withOpacity(0.10),
                        title: 'Profile',
                        subtitle: widget.assistantProfile.email,
                        onTap: () => _showProfileSheet(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Change Password ───────────────────────────────────────
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

                  // ── Linked Doctor ─────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.medical_services_rounded,
                        iconColor: const Color(0xFF0277BD),
                        iconBg: const Color(0xFF0277BD).withOpacity(0.10),
                        title: 'Linked Doctor',
                        subtitle: 'View the doctor you are assigned to',
                        onTap: () => _showLinkedDoctor(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Notifications ─────────────────────────────────────────
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

                  // ── Appearance ────────────────────────────────────────────
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

                  // ── Reports & Export ──────────────────────────────────────
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.file_download_rounded,
                        iconColor: const Color(0xFF2E7D32),
                        iconBg: const Color(0xFF2E7D32).withOpacity(0.10),
                        title: 'Reports & Export',
                        subtitle: 'Export appointments & patients',
                        onTap: () => _showExportOptions(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Sign Out ──────────────────────────────────────────────
                  GestureDetector(
                    onTap: _confirmLogout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _T.urgentBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _T.urgent.withOpacity(0.25)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: _T.urgent,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
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

  // ─────────────────────────────────────────────────────────────────────────
  // Profile sub-sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showProfileSheet() {
    final p = widget.assistantProfile;
    final name = p.fullName.isEmpty ? p.username : p.fullName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _T.bgPage,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
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
            // ── Gradient header ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: _T.gGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                          child: const Text(
                            'Assistant',
                            style: TextStyle(
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
            // ── Info rows ───────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _T.card(),
                  child: Column(
                    children: [
                      _ProfileRow('Email', p.email),
                      _ProfileRow('Username', p.username),
                      _ProfileRow(
                        'Gender',
                        p.gender.isEmpty
                            ? 'N/A'
                            : p.gender[0].toUpperCase() +
                                  p.gender.substring(1).toLowerCase(),
                      ),
                      _ProfileRow(
                        'Date of Birth',
                        p.birthDate != null
                            ? DateFormat('dd MMM yyyy').format(p.birthDate!)
                            : 'N/A',
                      ),
                      _ProfileRow('Role', 'Assistant'),
                      if ((p.clinicName ?? '').isNotEmpty)
                        _ProfileRow('Clinic', p.clinicName!),
                      _ProfileRow(
                        'Joined',
                        DateFormat('dd MMM yyyy').format(p.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                          'Password must be at least 6 characters',
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
  // Linked Doctor sub-sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showLinkedDoctor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _LinkedDoctorSheet(assistantProfile: widget.assistantProfile),
    );
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
                      activeColor: _T.green,
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
                      activeColor: _T.green,
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
                      activeColor: _T.green,
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
                      activeColor: _T.green,
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
                  color: isSelected ? _T.green.withOpacity(0.08) : _T.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _T.green : _T.divider,
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
                        color: isSelected ? _T.green : _T.textH,
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
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Reports & Export sub-sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AssistantExportSheet(assistantProfile: widget.assistantProfile),
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
              // Capture root navigator BEFORE popping anything.
              final rootNav = Navigator.of(context, rootNavigator: true);
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close settings sheet
              await ref.read(assistantViewModelProvider.notifier).logout();
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
      // Use cached activeDoctor from ViewModel first (fast path)
      final state = ref.read(assistantViewModelProvider);
      if (state.activeDoctor != null) {
        if (mounted)
          setState(() {
            _doctor = state.activeDoctor;
            _loading = false;
          });
        return;
      }
      // Fallback: fetch by doctorId from profile
      final did = int.tryParse(widget.assistantProfile.doctorId ?? '');
      if (did != null && did > 0) {
        final d = await ApiService.getDoctorById(did);
        if (mounted)
          setState(() {
            _doctor = d;
            _loading = false;
          });
      } else {
        if (mounted)
          setState(() {
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
                const Text(
                  'Linked Doctor',
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
                    onRetry: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _fetch();
                    },
                  )
                : _doctor == null
                ? const _EmptyCard(
                    icon: Icons.person_off_rounded,
                    title: 'No doctor linked',
                    subtitle:
                        'Contact your clinic admin to link a doctor account.',
                  )
                : _DoctorCard(doctor: _doctor!),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assistant Export sub-sheet
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

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? _T.urgent : _T.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _export(String type) async {
    setState(() => _exporting = type);
    final state = ref.read(assistantViewModelProvider);
    try {
      switch (type) {
        case 'appointments':
          _snack(
            'Appointments export ready '
            '(${state.appointments.length} records). '
            'Add share_plus to pubspec.yaml to enable file sharing.',
          );
          break;
        case 'patients':
          _snack(
            'Patients export ready (${state.patients.length} patients). '
            'Add share_plus to pubspec.yaml to enable file sharing.',
          );
          break;
      }
    } catch (e) {
      _snack('Export failed: ${e.toString()}', err: true);
    } finally {
      if (mounted) setState(() => _exporting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantViewModelProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final exportOptions = [
      (
        id: 'appointments',
        icon: Icons.calendar_month_rounded,
        color: _T.green,
        bg: _T.green.withOpacity(0.10),
        title: 'Appointments Report',
        subtitle: '${state.appointments.length} appointments',
      ),
      (
        id: 'patients',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF0277BD),
        bg: const Color(0xFF0277BD).withOpacity(0.10),
        title: 'Patient List',
        subtitle: '${state.patients.length} patients',
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
                            color: _T.green,
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
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _T.bgCard,
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
  final Color iconColor, iconBg;
  final String title, subtitle;
  final bool value;
  final Color activeColor;
  final void Function(bool) onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.activeColor = _T.green,
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
          activeColor: activeColor,
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

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _DoctorCard({required this.doctor, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fn = (doctor['first_name'] ?? '').toString().trim();
    final ln = (doctor['last_name'] ?? '').toString().trim();
    final name = '$fn $ln'.trim().isEmpty ? 'Doctor' : '$fn $ln'.trim();
    final spec = (doctor['specialization'] ?? '').toString();
    final clinic = (doctor['clinic_name'] ?? '').toString();
    final email = (doctor['email'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.bgCard,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _T.textH,
                      ),
                    ),
                    if (spec.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        spec,
                        style: const TextStyle(fontSize: 12, color: _T.textS),
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
                child: const Text(
                  'Active',
                  style: TextStyle(
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
            const Divider(height: 1, color: _T.divider),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 15, color: _T.textM),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: _T.textS),
          ),
        ),
      ],
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _T.textS,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _T.textH,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _T.bgCard,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(Icons.error_outline_rounded, color: _T.urgent, size: 40),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _T.textS, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: _T.bgCard,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(icon, size: 48, color: _T.textM),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _T.textS,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _T.textM),
        ),
      ],
    ),
  );
}
