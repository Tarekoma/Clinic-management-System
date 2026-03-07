// ═══════════════════════════════════════════════════════════════════════════════
// Doctor_Interface.dart  —  Complete Redesign  (paste-ready, single file)
// Replace your existing Doctor_Interface.dart with this file.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Hakim/api_service.dart';
import 'package:Hakim/UserProfile.dart';
import 'package:Hakim/Login Page.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'voice_recording_widget.dart';
import 'package:Hakim/AI_Service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════════

class _T {
  _T._();
  // Brand
  static const Color navy = Color(0xFF0B3D6B);
  static const Color navyDeep = Color(0xFF071E34);
  static const Color navyLight = Color(0xFF1565C0);
  static const Color teal = Color(0xFF00796B);
  static const Color tealLight = Color(0xFF26A69A);
  static const Color tealPale = Color(0xFFE0F2F1);
  // Surface
  static const Color bgPage = Color(0xFFF0F4F8);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFF5F7FA);
  static const Color divider = Color(0xFFE4EAF1);
  // Status
  static const Color urgent = Color(0xFFD32F2F);
  static const Color urgentBg = Color(0xFFFDEDED);
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF1565C0);
  static const Color infoBg = Color(0xFFE3F2FD);
  static const Color muted = Color(0xFF78909C);
  static const Color mutedBg = Color(0xFFF5F5F5);
  // Text
  static const Color textH = Color(0xFF0D1B2A);
  static const Color textS = Color(0xFF546E7A);
  static const Color textM = Color(0xFF90A4AE);
  // Gradients
  static const LinearGradient gNavy = LinearGradient(
    colors: [Color(0xFF071E34), Color(0xFF0B3D6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gTeal = LinearGradient(
    colors: [Color(0xFF004D40), Color(0xFF00796B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gUrgent = LinearGradient(
    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status helpers
  static Color sFg(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':
        return info;
      case 'IN_PROGRESS':
        return teal;
      case 'COMPLETED':
        return success;
      case 'CANCELLED':
        return muted;
      default:
        return textS;
    }
  }

  static Color sBg(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':
        return infoBg;
      case 'IN_PROGRESS':
        return tealPale;
      case 'COMPLETED':
        return successBg;
      case 'CANCELLED':
        return mutedBg;
      default:
        return mutedBg;
    }
  }

  static String sLabel(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':
        return 'Scheduled';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return s;
    }
  }

  // Card decoration
  static BoxDecoration card({double r = 16, Color? bg}) => BoxDecoration(
    color: bg ?? bgCard,
    borderRadius: BorderRadius.circular(r),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0B3D6B).withOpacity(0.07),
        blurRadius: 18,
        offset: const Offset(0, 5),
      ),
    ],
  );
  static BoxDecoration gradCard({LinearGradient g = gNavy, double r = 18}) =>
      BoxDecoration(
        gradient: g,
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D6B).withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // Input decoration
  static InputDecoration inp(
    String label, {
    String? hint,
    Widget? pre,
    Widget? suf,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: pre,
    suffixIcon: suf,
    filled: true,
    fillColor: bgInput,
    labelStyle: const TextStyle(fontSize: 13, color: textS),
    hintStyle: const TextStyle(fontSize: 13, color: textM),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: navy, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  // Avatar colour bucket
  static final _ac = [
    const Color(0xFF1565C0),
    const Color(0xFF00796B),
    const Color(0xFF6A1B9A),
    const Color(0xFFAD1457),
    const Color(0xFF0277BD),
    const Color(0xFF558B2F),
    const Color(0xFF4E342E),
    const Color(0xFF00838F),
  ];
  static Color avatarBg(String name) =>
      name.isEmpty ? _ac[0] : _ac[name.codeUnitAt(0) % _ac.length];
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED MICRO-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, this.size = 44, Key? key})
    : super(key: key);
  String get _init {
    final p = name.trim().split(' ');
    if (p.isEmpty) return '?';
    if (p.length == 1) return p[0].isEmpty ? '?' : p[0][0].toUpperCase();
    return '${p[0][0]}${p.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: _T.avatarBg(name), shape: BoxShape.circle),
    child: Center(
      child: Text(
        _init,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _Badge({
    required this.label,
    required this.fg,
    required this.bg,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: fg,
        letterSpacing: 0.3,
      ),
    ),
  );
}

class _SecHead extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SecHead({required this.title, this.action, this.onAction, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _T.textH,
        ),
      ),
      const Spacer(),
      if (action != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _T.navy,
            ),
          ),
        ),
    ],
  );
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  const _Empty({required this.icon, required this.title, this.sub, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _T.bgInput,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: _T.textM),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _T.textS,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(
              sub!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _T.textM),
            ),
          ],
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN DOCTOR INTERFACE
// ═══════════════════════════════════════════════════════════════════════════════

class DoctorInterface extends StatefulWidget {
  final UserProfile doctorProfile;
  const DoctorInterface({Key? key, required this.doctorProfile})
    : super(key: key);
  @override
  State<DoctorInterface> createState() => _DoctorInterfaceState();
}

class _DoctorInterfaceState extends State<DoctorInterface> {
  int _selectedIndex = 0;

  // ── Data ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _appointmentTypes = [];
  List<Map<String, dynamic>> _reports = [];
  bool _loadingPatients = false;
  bool _loadingAppointments = false;

  final _apptSearchCtrl = TextEditingController();
  final _patientSearchCtrl = TextEditingController();

  String get _clinic => widget.doctorProfile.clinicName ?? '';

  @override
  void initState() {
    super.initState();
    _loadAll();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _apptSearchCtrl.dispose();
    _patientSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() =>
      Future.wait([_loadPatients(), _loadAppointments(), _loadTypes()]);

  Future<void> _loadPatients() async {
    if (!mounted) return;
    setState(() => _loadingPatients = true);
    try {
      final d = await ApiService.getPatients();
      if (mounted)
        setState(() => _patients = List<Map<String, dynamic>>.from(d));
    } catch (e) {
      _snack(
        'Failed to load patients: ${ApiService.extractError(e)}',
        err: true,
      );
    } finally {
      if (mounted) setState(() => _loadingPatients = false);
    }
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() => _loadingAppointments = true);
    try {
      final d = await ApiService.getAppointments();
      if (mounted) {
        final list = List<Map<String, dynamic>>.from(d);
        list.sort((a, b) {
          final da = _dt(a['start_time']) ?? DateTime.now();
          final db = _dt(b['start_time']) ?? DateTime.now();
          return da.compareTo(db);
        });
        setState(() => _appointments = list);
      }
    } catch (e) {
      _snack(
        'Failed to load appointments: ${ApiService.extractError(e)}',
        err: true,
      );
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  Future<void> _loadReports(int patientId) async {
    try {
      final d = await ApiService.getMedicalReports(patientId: patientId);
      if (mounted)
        setState(() => _reports = List<Map<String, dynamic>>.from(d));
    } catch (_) {}
  }

  Future<void> _loadTypes() async {
    try {
      final d = await ApiService.getAppointmentTypes();
      if (mounted)
        setState(() => _appointmentTypes = List<Map<String, dynamic>>.from(d));
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _apptName(Map<String, dynamic> a) {
    final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
    final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
    return '$fn $ln'.trim().ifEmpty('Unknown Patient');
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

  // ── Scaffold ──────────────────────────────────────────────────────────────

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.calendar_month_rounded, 'Appointments'),
    _NavItem(Icons.people_alt_rounded, 'Patients'),
    _NavItem(Icons.account_balance_wallet_rounded, 'Finance'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bgPage,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      ),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _buildPage(),
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(gradient: _T.gNavy),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 10, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        _DoctorProfilePage(doctorProfile: widget.doctorProfile),
                  ),
                ),
                child: Row(
                  children: [
                    _Avatar(name: widget.doctorProfile.fullName, size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${widget.doctorProfile.firstName} ${widget.doctorProfile.lastName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.doctorProfile.specialization ??
                              _clinic.ifEmpty('General Practitioner'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('EEE, dd MMM').format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                color: Colors.white.withOpacity(0.75),
                tooltip: 'Sign Out',
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _T.bgCard,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D6B).withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final sel = i == _selectedIndex;
              final item = _navItems[i];
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = i),
                  splashColor: _T.navy.withOpacity(0.08),
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? _T.navy.withOpacity(0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          color: sel ? _T.navy : _T.textM,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? _T.navy : _T.textM,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Page router ───────────────────────────────────────────────────────────

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardPage(
          doctorProfile: widget.doctorProfile,
          appointments: _appointments,
          patients: _patients,
          loading: _loadingAppointments,
          onRefresh: _loadAll,
          onNav: (i) => setState(() => _selectedIndex = i),
        );
      case 1:
        return _AppointmentsPage(
          doctorProfile: widget.doctorProfile,
          appointments: _appointments,
          patients: _patients,
          types: _appointmentTypes,
          loading: _loadingAppointments,
          searchCtrl: _apptSearchCtrl,
          onRefresh: _loadAppointments,
          onStartConsultation: _openConsultation,
          snack: _snack,
        );
      case 2:
        return _PatientsPage(
          doctorProfile: widget.doctorProfile,
          patients: _patients,
          appointments: _appointments,
          reports: _reports,
          loading: _loadingPatients,
          searchCtrl: _patientSearchCtrl,
          onRefresh: _loadPatients,
          onLoadReports: _loadReports,
          snack: _snack,
        );
      case 3:
        return _FinancePage(
          appointments: _appointments,
          loading: _loadingAppointments,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _openConsultation(Map<String, dynamic> appt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ConsultationPage(
          appointment: appt,
          doctorProfile: widget.doctorProfile,
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE 1 — DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _DashboardPage extends StatelessWidget {
  final UserProfile doctorProfile;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> patients;
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(int) onNav;

  const _DashboardPage({
    required this.doctorProfile,
    required this.appointments,
    required this.patients,
    required this.loading,
    required this.onRefresh,
    required this.onNav,
    Key? key,
  }) : super(key: key);

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _today {
    final now = DateTime.now();
    return appointments.where((a) {
      final dt = _dt(a['start_time']);
      if (dt == null) return false;
      return dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day &&
          (a['status'] ?? '').toUpperCase() != 'CANCELLED';
    }).toList()..sort(
      (a, b) => (_dt(a['start_time']) ?? DateTime.now()).compareTo(
        _dt(b['start_time']) ?? DateTime.now(),
      ),
    );
  }

  Map<String, dynamic>? get _next {
    final now = DateTime.now();
    final upcoming =
        appointments.where((a) {
          final dt = _dt(a['start_time']);
          if (dt == null) return false;
          final s = (a['status'] ?? '').toUpperCase();
          return dt.isAfter(now) && (s == 'SCHEDULED' || s == 'IN_PROGRESS');
        }).toList()..sort(
          (a, b) => _dt(a['start_time'])!.compareTo(_dt(b['start_time'])!),
        );
    return upcoming.isEmpty ? null : upcoming.first;
  }

  String _name(Map<String, dynamic> a) {
    final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
    final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
    return '$fn $ln'.trim().ifEmpty('Unknown Patient');
  }

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final todayList = _today;
    final nextPt = _next;
    final completed = todayList
        .where((a) => (a['status'] ?? '').toUpperCase() == 'COMPLETED')
        .length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _T.navy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // ── Greeting banner ──────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      _DoctorProfilePage(doctorProfile: doctorProfile),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: _T.gradCard(),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greet(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dr. ${doctorProfile.firstName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              todayList.isEmpty
                                  ? 'No appointments today'
                                  : '${todayList.length} appointment${todayList.length > 1 ? "s" : ""} today',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
            ), // ← THIS COMMA is critical

            const SizedBox(height: 18),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _T.navy,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (todayList.isEmpty)
              const _Empty(
                icon: Icons.calendar_today_outlined,
                title: 'No appointments today',
                sub: 'Enjoy your free day!',
              )
            else
              ...todayList.take(6).map((a) => _buildTimelineRow(a)),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildNextCard(Map<String, dynamic>? next) {
    if (next == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _T.card(),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _T.bgInput,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: _T.textM,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No upcoming appointments',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _T.textS,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "You're all caught up!",
                  style: TextStyle(fontSize: 12, color: _T.textM),
                ),
              ],
            ),
          ],
        ),
      );
    }
    final name = _name(next);
    final dt = _dt(next['start_time']);
    final time = dt != null ? DateFormat('hh:mm a').format(dt) : '--:--';
    final type =
        next['appointment_type_name'] ??
        next['appointment_type'] ??
        'Consultation';
    final urgent = next['is_urgent'] == true;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _T.gradCard(g: _T.gTeal),
      child: Row(
        children: [
          _Avatar(name: name, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (urgent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _T.urgent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(Map<String, dynamic> a) {
    final dt = _dt(a['start_time']);
    final time = dt != null ? DateFormat('hh:mm a').format(dt) : '--';
    final name = _name(a);
    final status = (a['status'] ?? 'SCHEDULED').toUpperCase();
    final urgent = a['is_urgent'] == true;
    final type =
        a['appointment_type_name'] ?? a['appointment_type'] ?? 'Consultation';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: _T.card(r: 14),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _T.navy,
              ),
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: urgent ? _T.urgent : _T.sFg(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _T.textH,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: const TextStyle(fontSize: 11, color: _T.textS),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Badge(
                label: _T.sLabel(status),
                fg: _T.sFg(status),
                bg: _T.sBg(status),
              ),
              if (urgent) ...[
                const SizedBox(height: 4),
                const _Badge(label: 'URGENT', fg: _T.urgent, bg: _T.urgentBg),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? sub;
  final Color color, bg;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    required this.color,
    required this.bg,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: _T.card(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: _T.textS),
              ),
              if (sub != null)
                Text(
                  sub!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _T.textM,
                    letterSpacing: 0.4,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE 2 — APPOINTMENTS
// ═══════════════════════════════════════════════════════════════════════════════

enum _AF { all, today, upcoming, urgent, completed }

class _AppointmentsPage extends StatefulWidget {
  final UserProfile doctorProfile;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> types;
  final bool loading;
  final TextEditingController searchCtrl;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onStartConsultation;
  final void Function(String, {bool err}) snack;

  const _AppointmentsPage({
    required this.doctorProfile,
    required this.appointments,
    required this.patients,
    required this.types,
    required this.loading,
    required this.searchCtrl,
    required this.onRefresh,
    required this.onStartConsultation,
    required this.snack,
    Key? key,
  }) : super(key: key);

  @override
  State<_AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<_AppointmentsPage> {
  _AF _filter = _AF.today;
  String _q = '';

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _name(Map<String, dynamic> a) {
    final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
    final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
    return '$fn $ln'.trim().ifEmpty('Unknown');
  }

  List<Map<String, dynamic>> get _filtered {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.appointments.where((a) {
      final dt = _dt(a['start_time']);
      final day = dt != null ? DateTime(dt.year, dt.month, dt.day) : null;
      final s = (a['status'] ?? '').toUpperCase();
      bool ok = switch (_filter) {
        _AF.all => true,
        _AF.today => day == today,
        _AF.upcoming => dt != null && dt.isAfter(now) && s != 'CANCELLED',
        _AF.urgent => a['is_urgent'] == true,
        _AF.completed => s == 'COMPLETED',
      };
      if (!ok) return false;
      if (_q.isNotEmpty) return _name(a).toLowerCase().contains(_q);
      return true;
    }).toList();
  }

  int _cnt(_AF f) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.appointments.where((a) {
      final dt = _dt(a['start_time']);
      final day = dt != null ? DateTime(dt.year, dt.month, dt.day) : null;
      final s = (a['status'] ?? '').toUpperCase();
      return switch (f) {
        _AF.all => true,
        _AF.today => day == today,
        _AF.upcoming => dt != null && dt.isAfter(now) && s != 'CANCELLED',
        _AF.urgent => a['is_urgent'] == true,
        _AF.completed => s == 'COMPLETED',
      };
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        backgroundColor: _T.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: widget.searchCtrl,
              decoration: _T.inp(
                'Search patient name...',
                pre: const Icon(
                  Icons.search_rounded,
                  color: _T.textM,
                  size: 20,
                ),
                suf: _q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          widget.searchCtrl.clear();
                          setState(() => _q = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _q = v.toLowerCase().trim()),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                for (final (f, lbl) in [
                  (_AF.all, 'All'),
                  (_AF.today, 'Today'),
                  (_AF.upcoming, 'Upcoming'),
                  (_AF.urgent, 'Urgent'),
                  (_AF.completed, 'Done'),
                ])
                  _buildChip(f, lbl),
              ],
            ),
          ),
          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              color: _T.navy,
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(_AF f, String lbl) {
    final sel = _filter == f;
    final cnt = _cnt(f);
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: sel ? _T.navy : _T.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _T.navy : _T.divider),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: _T.navy.withOpacity(0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              lbl,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : _T.textS,
              ),
            ),
            if (cnt > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: sel ? Colors.white.withOpacity(0.25) : _T.bgInput,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$cnt',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : _T.navy,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (widget.loading) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }
    final list = _filtered;
    if (list.isEmpty) {
      return const _Empty(
        icon: Icons.calendar_month_outlined,
        title: 'No appointments found',
        sub: 'Try a different filter or book a new appointment.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () {
          final s = (list[i]['status'] ?? '').toUpperCase();
          if (s == 'SCHEDULED' || s == 'IN_PROGRESS') {
            widget.onStartConsultation(list[i]);
          }
        },
        child: _ApptCard(
          appt: list[i],
          onStart: () => widget.onStartConsultation(list[i]),
          onEdit: () => _showForm(ctx, list[i]),
          onStatus: (s) => _setStatus(list[i], s),
          onDelete: () => _delete(list[i]),
        ),
      ),
    );
  }

  Future<void> _setStatus(Map<String, dynamic> a, String status) async {
    try {
      await ApiService.updateAppointmentStatus(
        int.parse(a['id'].toString()),
        status,
      );
      await widget.onRefresh();
    } catch (e) {
      widget.snack(ApiService.extractError(e), err: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Appointment'),
        content: Text(
          'Delete appointment for ${_name(a)}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.urgent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteAppointment(int.parse(a['id'].toString()));
      await widget.onRefresh();
    } catch (e) {
      widget.snack(ApiService.extractError(e), err: true);
    }
  }

  void _showForm(BuildContext context, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApptForm(
        existing: existing,
        patients: widget.patients,
        types: widget.types,
        onSaved: widget.onRefresh,
        snack: widget.snack,
      ),
    );
  }
}

// ── Appointment Card ──────────────────────────────────────────────────────────

class _ApptCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final VoidCallback onStart, onEdit, onDelete;
  final void Function(String) onStatus;

  const _ApptCard({
    required this.appt,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
    required this.onStatus,
    Key? key,
  }) : super(key: key);

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String get _name {
    final fn =
        appt['patient_first_name'] ?? appt['patient']?['first_name'] ?? '';
    final ln = appt['patient_last_name'] ?? appt['patient']?['last_name'] ?? '';
    return '$fn $ln'.trim().ifEmpty('Unknown Patient');
  }

  @override
  Widget build(BuildContext context) {
    final dt = _dt(appt['start_time']);
    final status = (appt['status'] ?? 'SCHEDULED').toUpperCase();
    final urgent = appt['is_urgent'] == true;
    final type =
        appt['appointment_type_name'] ??
        appt['appointment_type'] ??
        'Consultation';
    final phone = appt['patient_phone'] ?? appt['patient']?['phone'] ?? '';
    final fee = double.tryParse((appt['fee'] ?? 0).toString()) ?? 0.0;
    final isPaid = appt['is_paid'] == true;
    final canStart = status == 'SCHEDULED' || status == 'IN_PROGRESS';

    return Container(
      decoration: BoxDecoration(
        color: _T.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent ? _T.urgent.withOpacity(0.35) : _T.divider,
          width: urgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (urgent ? _T.urgent : _T.navy).withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Time
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: urgent ? _T.urgent : _T.sFg(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dt != null ? DateFormat('hh:mm').format(dt) : '--:--',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.navy,
                      ),
                    ),
                    Text(
                      dt != null ? DateFormat('a').format(dt) : '',
                      style: const TextStyle(
                        fontSize: 10,
                        color: _T.textM,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 52, color: _T.divider),
                const SizedBox(width: 12),
                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Avatar(name: _name, size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _T.textH,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (phone.isNotEmpty)
                                  Text(
                                    phone,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _T.textS,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          _MiniChip(
                            icon: Icons.medical_services_outlined,
                            label: type,
                          ),
                          if (fee > 0) ...[
                            const SizedBox(width: 6),
                            _MiniChip(
                              icon: Icons.payments_outlined,
                              label: '${fee.toStringAsFixed(0)} EGP',
                              color: isPaid ? _T.success : _T.warning,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Badge(
                      label: _T.sLabel(status),
                      fg: _T.sFg(status),
                      bg: _T.sBg(status),
                    ),
                    if (urgent) ...[
                      const SizedBox(height: 4),
                      const _Badge(
                        label: 'URGENT',
                        fg: _T.urgent,
                        bg: _T.urgentBg,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Action row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: _T.bgInput,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                if (dt != null) ...[
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: _T.textM,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      DateFormat('EEE, dd MMM yyyy').format(dt),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _T.textM,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (canStart)
                      _ActBtn(
                        label: 'Start',
                        icon: Icons.play_circle_rounded,
                        color: _T.teal,
                        onTap: onStart,
                      ),
                    _ActBtn(
                      label: 'Edit',
                      icon: Icons.edit_rounded,
                      color: _T.navyLight,
                      onTap: onEdit,
                    ),
                    if (status == 'SCHEDULED')
                      _ActBtn(
                        label: 'Done',
                        icon: Icons.check_circle_outline_rounded,
                        color: _T.success,
                        onTap: () => onStatus('COMPLETED'),
                      ),
                    _ActBtn(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      color: _T.urgent,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniChip({
    required this.icon,
    required this.label,
    this.color = _T.textS,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: _T.bgInput,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    ),
  );
}

class _ActBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PatientSearchField extends StatefulWidget {
  final List<Map<String, dynamic>> patients;
  final int? selectedId;
  final void Function(int?) onSelected;
  const _PatientSearchField({
    required this.patients,
    required this.selectedId,
    required this.onSelected,
    Key? key,
  }) : super(key: key);
  @override
  State<_PatientSearchField> createState() => _PatientSearchFieldState();
}

class _PatientSearchFieldState extends State<_PatientSearchField> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selected;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedId != null) {
      _selected = widget.patients.firstWhere(
        (p) => int.tryParse(p['id'].toString()) == widget.selectedId,
        orElse: () => {},
      );
      if (_selected!.isNotEmpty) {
        _ctrl.text =
            '${_selected!['first_name'] ?? ''} ${_selected!['last_name'] ?? ''}'
                .trim();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    final query = q.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }
    setState(() {
      _results = widget.patients.where((p) {
        final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
            .toLowerCase();
        final phone = (p['phone'] ?? '').toLowerCase();
        final nid = (p['national_id'] ?? '').toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            nid.contains(query);
      }).toList();
      _showResults = true;
    });
  }

  void _pick(Map<String, dynamic> p) {
    final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    _ctrl.text = name;
    setState(() {
      _selected = p;
      _showResults = false;
      _results = [];
    });
    widget.onSelected(int.tryParse(p['id'].toString()));
    FocusScope.of(context).unfocus();
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _selected = null;
      _results = [];
      _showResults = false;
    });
    widget.onSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          decoration: _T.inp(
            'Search patient by name, phone or ID...',
            pre: const Icon(
              Icons.person_search_rounded,
              size: 18,
              color: _T.textM,
            ),
            suf: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: _clear,
                  )
                : null,
          ),
          onChanged: _search,
        ),
        if (_selected != null && !_showResults)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _T.tealPale,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _T.teal.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: _T.teal,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selected!['first_name'] ?? ''} ${_selected!['last_name'] ?? ''}'
                        .trim(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _T.teal,
                    ),
                  ),
                ),
                if ((_selected!['phone'] ?? '').isNotEmpty)
                  Text(
                    _selected!['phone'],
                    style: const TextStyle(fontSize: 11, color: _T.textS),
                  ),
              ],
            ),
          ),
        if (_showResults)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: _T.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.divider),
              boxShadow: [
                BoxShadow(
                  color: _T.navy.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: _results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No patients found',
                      style: TextStyle(fontSize: 13, color: _T.textS),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _T.divider),
                    itemBuilder: (_, i) {
                      final p = _results[i];
                      final name =
                          '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
                              .trim();
                      final phone = p['phone'] ?? '';
                      final nid = p['national_id'] ?? '';
                      return InkWell(
                        onTap: () => _pick(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              _Avatar(name: name, size: 34),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _T.textH,
                                      ),
                                    ),
                                    if (phone.isNotEmpty || nid.isNotEmpty)
                                      Text(
                                        [phone, nid]
                                            .where((s) => s.isNotEmpty)
                                            .join('  •  '),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _T.textS,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: _T.textM,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}

// ── Appointment Form Sheet ────────────────────────────────────────────────────

class _ApptForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> types;
  final Future<void> Function() onSaved;
  final void Function(String, {bool err}) snack;
  const _ApptForm({
    this.existing,
    required this.patients,
    required this.types,
    required this.onSaved,
    required this.snack,
    Key? key,
  }) : super(key: key);
  @override
  State<_ApptForm> createState() => _ApptFormState();
}

class _ApptFormState extends State<_ApptForm> {
  int? _patId, _typeId;
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  bool _urgent = false;
  bool _isPaid = false;
  final _feeCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;
  String _visitType = 'consultation'; // 'consultation' or 'revisit'
  static const double _consultDefaultFee = 200.0;
  static const double _revisitDefaultFee = 100.0;
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _patId = int.tryParse(
        (e['patient_id'] ?? e['patient']?['id'] ?? '').toString(),
      );
      _typeId = int.tryParse(
        (e['appointment_type_id'] ?? e['appointment_type']?['id'] ?? '')
            .toString(),
      );
      try {
        _date = DateTime.parse(e['start_time'].toString()).toLocal();
      } catch (_) {}
      _urgent = e['is_urgent'] == true;
      _isPaid = e['is_paid'] == true;
      final existingFee = (e['fee'] ?? '').toString();
      _feeCtrl.text = existingFee;
      final existingType = (e['appointment_type_name'] ?? '')
          .toString()
          .toLowerCase();
      if (existingType.contains('revisit') || existingType.contains('follow')) {
        _visitType = 'revisit';
      } else {
        _visitType = 'consultation';
      }
      _reasonCtrl.text = e['reason'] ?? '';
    }
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_patId == null) {
      widget.snack('Please select a patient', err: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'patient_id': _patId,
        if (_typeId != null) 'appointment_type_id': _typeId,
        'start_time': _date.toUtc().toIso8601String(),
        'is_urgent': _urgent,
        'is_paid': _isPaid,
        if (_feeCtrl.text.isNotEmpty)
          'fee': double.tryParse(_feeCtrl.text) ?? 0,
        'appointment_type_name': _visitType == 'consultation'
            ? 'Consultation'
            : 'Revisit',
        if (_reasonCtrl.text.isNotEmpty) 'reason': _reasonCtrl.text.trim(),
      };
      if (widget.existing != null) {
        await ApiService.updateAppointment(
          int.parse(widget.existing!['id'].toString()),
          data,
        );
      } else {
        await ApiService.createAppointment(data);
      }
      await widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      widget.snack(ApiService.extractError(e), err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _T.navy)),
        child: child!,
      ),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (t == null || !mounted) return;
    setState(() => _date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _T.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 20),
            Text(
              widget.existing != null ? 'Edit Appointment' : 'New Appointment',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _T.textH,
              ),
            ),
            const SizedBox(height: 20),
            // Patient
            // Patient Search
            _PatientSearchField(
              patients: widget.patients,
              selectedId: _patId,
              onSelected: (id) => setState(() => _patId = id),
            ),
            const SizedBox(height: 14),
            // Type
            // ── Visit Type Selector ──────────────────────────────────────────
            const Text(
              'Visit Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _T.textS,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _visitType = 'consultation';
                      _feeCtrl.text = _consultDefaultFee.toStringAsFixed(0);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _visitType == 'consultation'
                            ? _T.navy
                            : _T.bgInput,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _visitType == 'consultation'
                              ? _T.navy
                              : _T.divider,
                        ),
                        boxShadow: _visitType == 'consultation'
                            ? [
                                BoxShadow(
                                  color: _T.navy.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.medical_services_rounded,
                            color: _visitType == 'consultation'
                                ? Colors.white
                                : _T.textM,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Consultation',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _visitType == 'consultation'
                                  ? Colors.white
                                  : _T.textS,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_consultDefaultFee.toStringAsFixed(0)} EGP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _visitType == 'consultation'
                                  ? Colors.white.withOpacity(0.75)
                                  : _T.textM,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _visitType = 'revisit';
                      _feeCtrl.text = _revisitDefaultFee.toStringAsFixed(0);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _visitType == 'revisit' ? _T.teal : _T.bgInput,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _visitType == 'revisit' ? _T.teal : _T.divider,
                        ),
                        boxShadow: _visitType == 'revisit'
                            ? [
                                BoxShadow(
                                  color: _T.teal.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: _visitType == 'revisit'
                                ? Colors.white
                                : _T.textM,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Revisit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _visitType == 'revisit'
                                  ? Colors.white
                                  : _T.textS,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_revisitDefaultFee.toStringAsFixed(0)} EGP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _visitType == 'revisit'
                                  ? Colors.white.withOpacity(0.75)
                                  : _T.textM,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Fee (editable override) ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _T.inp(
                      'Fee (EGP)',
                      pre: const Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: _T.textM,
                      ),
                      hint: _visitType == 'consultation'
                          ? '${_consultDefaultFee.toStringAsFixed(0)}'
                          : '${_revisitDefaultFee.toStringAsFixed(0)}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() {
                    _feeCtrl.text = _visitType == 'consultation'
                        ? _consultDefaultFee.toStringAsFixed(0)
                        : _revisitDefaultFee.toStringAsFixed(0);
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _T.bgInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _T.divider),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: _T.textS,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Date & Time
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: _T.inp(
                  'Date & Time',
                  pre: const Icon(
                    Icons.event_rounded,
                    size: 18,
                    color: _T.textM,
                  ),
                ),
                child: Text(
                  DateFormat('dd MMM yyyy  •  hh:mm a').format(_date),
                  style: const TextStyle(fontSize: 13, color: _T.textH),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Fee
            const SizedBox(height: 14),
            // Reason
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: _T.inp('Reason / Notes (optional)'),
            ),
            const SizedBox(height: 14),
            // Urgent
            // Urgent
            GestureDetector(
              onTap: () => setState(() => _urgent = !_urgent),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _urgent ? _T.urgentBg : _T.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _urgent ? _T.urgent.withOpacity(0.4) : _T.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: _urgent ? _T.urgent : _T.textM,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mark as Urgent',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _urgent ? _T.urgent : _T.textS,
                      ),
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: _urgent,
                      onChanged: (v) => setState(() => _urgent = v),
                      activeColor: _T.urgent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Paid
            GestureDetector(
              onTap: () => setState(() => _isPaid = !_isPaid),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isPaid ? _T.successBg : _T.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPaid ? _T.success.withOpacity(0.4) : _T.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_rounded,
                      color: _isPaid ? _T.success : _T.textM,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mark as Paid',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isPaid ? _T.success : _T.textS,
                      ),
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: _isPaid,
                      onChanged: (v) => setState(() => _isPaid = v),
                      activeColor: _T.success,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.existing != null
                            ? 'Save Changes'
                            : 'Book Appointment',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE 3 — PATIENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _PatientsPage extends StatefulWidget {
  final UserProfile doctorProfile;
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> reports;
  final bool loading;
  final TextEditingController searchCtrl;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int) onLoadReports;
  final void Function(String, {bool err}) snack;

  const _PatientsPage({
    required this.doctorProfile,
    required this.patients,
    required this.appointments,
    required this.reports,
    required this.loading,
    required this.searchCtrl,
    required this.onRefresh,
    required this.onLoadReports,
    required this.snack,
    Key? key,
  }) : super(key: key);

  @override
  State<_PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<_PatientsPage> {
  String _q = '';

  List<Map<String, dynamic>> get _filtered {
    if (_q.isEmpty) return widget.patients;
    return widget.patients.where((p) {
      final nm = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
          .toLowerCase();
      final ph = (p['phone'] ?? '').toLowerCase();
      final nid = (p['national_id'] ?? '').toLowerCase();
      return nm.contains(_q) || ph.contains(_q) || nid.contains(_q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: _T.navy,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add Patient',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: widget.searchCtrl,
              decoration: _T.inp(
                'Search by name, phone, or national ID...',
                pre: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _T.textM,
                ),
                suf: _q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          widget.searchCtrl.clear();
                          setState(() => _q = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _q = v.toLowerCase().trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                Text(
                  '${widget.patients.length} patients total',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _T.textM,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_q.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${_filtered.length} results',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _T.navy,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              color: _T.navy,
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (widget.loading) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }
    final list = _filtered;
    if (list.isEmpty) {
      return const _Empty(
        icon: Icons.people_outline_rounded,
        title: 'No patients found',
        sub: 'Try a different search or add a new patient.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PatCard(
        patient: list[i],
        onTap: () {
          final pid = int.tryParse((list[i]['id'] ?? '').toString()) ?? 0;
          if (pid > 0) widget.onLoadReports(pid);
          _openDetail(list[i]);
        },
        onEdit: () => _showEditSheet(list[i]),
      ),
    );
  }

  void _openDetail(Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientDetail(
        patient: p,
        appointments: widget.appointments,
        reports: widget.reports,
        onRefresh: widget.onRefresh,
        onEditPatient: (pat) => _showEditSheet(pat),
        snack: widget.snack,
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatForm(onSaved: widget.onRefresh, snack: widget.snack),
    );
  }

  void _showEditSheet(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatForm(
        existing: patient,
        onSaved: widget.onRefresh,
        snack: widget.snack,
      ),
    );
  }
}

// ── Patient Card ──────────────────────────────────────────────────────────────

class _PatCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  const _PatCard({
    required this.patient,
    required this.onTap,
    this.onEdit,
    Key? key,
  }) : super(key: key);

  String get _name =>
      '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim();

  int? get _age {
    final dob = patient['birth_date'] ?? patient['date_of_birth'];
    if (dob == null) return null;
    try {
      return ((DateTime.now()
                  .difference(DateTime.parse(dob.toString()))
                  .inDays) /
              365.25)
          .floor();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gender = (patient['gender'] ?? '').toString().toUpperCase();
    final phone = patient['phone'] ?? '';
    final age = _age;
    final conds = (patient['conditions'] as List?)?.cast<Map>() ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _T.card(),
        child: Row(
          children: [
            _Avatar(name: _name, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.textH,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (age != null)
                        Text(
                          '$age yrs',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _T.textS,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (gender.isNotEmpty) ...[
                        Icon(
                          gender == 'MALE'
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          size: 13,
                          color: gender == 'MALE'
                              ? _T.navyLight
                              : const Color(0xFFAD1457),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          gender == 'MALE' ? 'Male' : 'Female',
                          style: const TextStyle(fontSize: 11, color: _T.textS),
                        ),
                        if (phone.isNotEmpty)
                          const Text(
                            '  •  ',
                            style: TextStyle(fontSize: 11, color: _T.textM),
                          ),
                      ],
                      if (phone.isNotEmpty)
                        Expanded(
                          child: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _T.textS,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  if (conds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: conds
                          .take(3)
                          .map(
                            (c) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _T.urgentBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                c['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _T.urgent,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  Builder(
                    builder: (_) {
                      final diseases = List<String>.from(
                        patient['chronic_diseases'] ?? [],
                      );
                      if (diseases.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: diseases
                              .map(
                                (d) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E5F5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    d,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6A1B9A),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chevron_right_rounded, color: _T.textM),
                if (onEdit != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: _T.textM,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Patient Detail Sheet ──────────────────────────────────────────────────────

class _PatientDetail extends StatefulWidget {
  final Map<String, dynamic> patient;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> reports;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onEditPatient;
  final void Function(String, {bool err}) snack;

  const _PatientDetail({
    required this.patient,
    required this.appointments,
    required this.reports,
    required this.onRefresh,
    required this.onEditPatient,
    required this.snack,
    Key? key,
  }) : super(key: key);

  @override
  State<_PatientDetail> createState() => _PatientDetailState();
}

class _PatientDetailState extends State<_PatientDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _visits = [];
  List<Map<String, dynamic>> _conds = [];
  bool _loadingVisits = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _conds = List<Map<String, dynamic>>.from(
      widget.patient['conditions'] ?? [],
    );
    _loadVisits();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadVisits() async {
    final pid = int.tryParse((widget.patient['id'] ?? '').toString()) ?? 0;
    if (pid == 0) {
      setState(() => _loadingVisits = false);
      return;
    }
    try {
      final d = await ApiService.getVisits(patientId: pid);
      if (mounted)
        setState(() {
          _visits = List<Map<String, dynamic>>.from(d);
          _loadingVisits = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingVisits = false);
    }
  }

  String get _name =>
      '${widget.patient['first_name'] ?? ''} ${widget.patient['last_name'] ?? ''}'
          .trim();

  int? get _age {
    final dob = widget.patient['birth_date'] ?? widget.patient['date_of_birth'];
    if (dob == null) return null;
    try {
      return ((DateTime.now()
                  .difference(DateTime.parse(dob.toString()))
                  .inDays) /
              365.25)
          .floor();
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _appts {
    final pid = (widget.patient['id'] ?? '').toString();
    return widget.appointments
        .where(
          (a) =>
              (a['patient_id'] ?? a['patient']?['id'] ?? '').toString() == pid,
        )
        .toList()
      ..sort((a, b) {
        DateTime? da, db;
        try {
          da = DateTime.parse(a['start_time'].toString()).toLocal();
        } catch (_) {}
        try {
          db = DateTime.parse(b['start_time'].toString()).toLocal();
        } catch (_) {}
        return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
      });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _T.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _T.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              decoration: const BoxDecoration(gradient: _T.gNavy),
              child: Row(
                children: [
                  _Avatar(name: _name, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (_age != null) '${_age} yrs',
                            if ((widget.patient['gender'] ?? '')
                                .toString()
                                .isNotEmpty)
                              (widget.patient['gender']
                                          .toString()
                                          .toUpperCase() ==
                                      'MALE'
                                  ? 'Male'
                                  : 'Female'),
                            if (widget.patient['phone'] != null)
                              widget.patient['phone'],
                          ].join('  •  '),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onEditPatient(widget.patient),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                    tooltip: 'Edit Patient',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabs,
              labelColor: _T.navy,
              unselectedLabelColor: _T.textM,
              indicatorColor: _T.navy,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Visits'),
                Tab(text: 'Reports'),
              ],
            ),
            const Divider(height: 1, color: _T.divider),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _overviewTab(ctrl),
                  _visitsTab(ctrl),
                  _reportsTab(ctrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewTab(ScrollController ctrl) {
    final p = widget.patient;
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.all(20),
      children: [
        // Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _T.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _T.textH,
                ),
              ),
              const SizedBox(height: 12),
              _IRow('National ID', p['national_id'] ?? '—'),
              _IRow('Phone', p['phone'] ?? '—'),
              _IRow('Region', p['region'] ?? '—'),
              if (p['birth_date'] != null || p['date_of_birth'] != null)
                _IRow(
                  'Date of Birth',
                  _fmtDate(p['birth_date'] ?? p['date_of_birth']),
                ),
              if ((p['email'] ?? '').toString().isNotEmpty)
                _IRow('Email', p['email']),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Chronic Diseases card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _T.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.monitor_heart_outlined,
                    size: 15,
                    color: Color(0xFF6A1B9A),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chronic Diseases',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _T.textH,
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (_) {
                      final count =
                          (widget.patient['chronic_diseases'] as List?)
                              ?.length ??
                          0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count/5',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (_) {
                  final diseases = List<String>.from(
                    widget.patient['chronic_diseases'] ?? [],
                  );
                  if (diseases.isEmpty) {
                    return const Text(
                      'No chronic diseases recorded',
                      style: TextStyle(fontSize: 12, color: _T.textS),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: diseases
                        .map(
                          (d) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF6A1B9A).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              d,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6A1B9A),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Conditions
        Row(
          children: [
            const Text(
              'Chronic Conditions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _T.textH,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addConditionDialog,
              icon: const Icon(Icons.add_rounded, size: 15),
              label: const Text('Add', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _conds.isEmpty
            ? Container(
                padding: const EdgeInsets.all(18),
                decoration: _T.card(),
                child: const Center(
                  child: Text(
                    'No chronic conditions recorded',
                    style: TextStyle(fontSize: 12, color: _T.textS),
                  ),
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _conds
                    .map(
                      (c) => _CondChip(
                        cond: c,
                        onRemove: () => _removeCondition(c),
                      ),
                    )
                    .toList(),
              ),
        const SizedBox(height: 16),
        const Text(
          'Recent Appointments',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _T.textH,
          ),
        ),
        const SizedBox(height: 8),
        ..._appts.take(3).map((a) {
          DateTime? dt;
          try {
            dt = DateTime.parse(a['start_time'].toString()).toLocal();
          } catch (_) {}
          final s = (a['status'] ?? '').toUpperCase();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: _T.card(r: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: _T.textM,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dt != null
                        ? DateFormat('dd MMM yyyy  •  hh:mm a').format(dt)
                        : 'Unknown date',
                    style: const TextStyle(fontSize: 12, color: _T.textS),
                  ),
                ),
                _Badge(label: _T.sLabel(s), fg: _T.sFg(s), bg: _T.sBg(s)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _visitsTab(ScrollController ctrl) {
    if (_loadingVisits) {
      return const Center(
        child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      );
    }
    if (_visits.isEmpty) {
      return const _Empty(
        icon: Icons.assignment_outlined,
        title: 'No visits recorded',
        sub: 'Visits appear here after consultations.',
      );
    }
    return ListView.separated(
      controller: ctrl,
      padding: const EdgeInsets.all(20),
      itemCount: _visits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final v = _visits[i];
        DateTime? dt;
        try {
          dt = DateTime.parse(
            (v['created_at'] ?? v['start_time'] ?? '').toString(),
          ).toLocal();
        } catch (_) {}
        final s = (v['status'] ?? '').toUpperCase();
        final diag = v['diagnosis'] ?? v['chief_complaint'] ?? '';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _T.card(r: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.assignment_rounded,
                    size: 15,
                    color: _T.navy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dt != null ? DateFormat('dd MMM yyyy').format(dt) : '—',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.textH,
                      ),
                    ),
                  ),
                  _Badge(label: _T.sLabel(s), fg: _T.sFg(s), bg: _T.sBg(s)),
                ],
              ),
              if (diag.toString().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  diag.toString(),
                  style: const TextStyle(fontSize: 12, color: _T.textS),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _reportsTab(ScrollController ctrl) {
    if (widget.reports.isEmpty) {
      return const _Empty(
        icon: Icons.description_outlined,
        title: 'No reports yet',
      );
    }
    return ListView.separated(
      controller: ctrl,
      padding: const EdgeInsets.all(20),
      itemCount: widget.reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = widget.reports[i];
        DateTime? dt;
        try {
          dt = DateTime.parse(r['created_at'].toString()).toLocal();
        } catch (_) {}
        final content = r['content'] ?? r['transcription'] ?? r['notes'] ?? '';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _T.card(r: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    size: 15,
                    color: _T.teal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r['report_type'] ?? 'Medical Report',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.textH,
                      ),
                    ),
                  ),
                  if (dt != null)
                    Text(
                      DateFormat('dd MMM').format(dt),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _T.textM,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
              if (content.toString().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  content.toString(),
                  style: const TextStyle(fontSize: 12, color: _T.textS),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    try {
      return DateFormat(
        'dd MMM yyyy',
      ).format(DateTime.parse(v.toString()).toLocal());
    } catch (_) {
      return '—';
    }
  }

  Future<void> _addConditionDialog() async {
    List<dynamic> catalog = [];
    try {
      catalog = await ApiService.getConditions();
    } catch (_) {}
    if (!mounted) return;
    int? selId;
    final nc = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Add Condition'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: _T.inp('Select Condition'),
                items: catalog
                    .cast<Map<String, dynamic>>()
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: int.tryParse(c['id'].toString()),
                        child: Text(c['name'] ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (v) => ss(() => selId = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: nc, decoration: _T.inp('Notes (optional)')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selId == null
                  ? null
                  : () async {
                      final pid =
                          int.tryParse(
                            (widget.patient['id'] ?? '').toString(),
                          ) ??
                          0;
                      await ApiService.assignCondition(pid, selId!, nc.text);
                      await widget.onRefresh();
                      if (mounted) Navigator.pop(ctx);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeCondition(Map<String, dynamic> c) async {
    final pid = int.tryParse((widget.patient['id'] ?? '').toString()) ?? 0;
    final cid =
        int.tryParse((c['id'] ?? c['condition_id'] ?? '').toString()) ?? 0;
    if (pid == 0 || cid == 0) return;
    try {
      await ApiService.removeCondition(pid, cid);
      await widget.onRefresh();
      if (mounted)
        setState(
          () => _conds.removeWhere((x) => x['id'].toString() == cid.toString()),
        );
    } catch (e) {
      widget.snack(ApiService.extractError(e), err: true);
    }
  }
}

class _IRow extends StatelessWidget {
  final String label, value;
  const _IRow(this.label, this.value, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _T.textS,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _T.textH,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CondChip extends StatelessWidget {
  final Map<String, dynamic> cond;
  final VoidCallback onRemove;
  const _CondChip({required this.cond, required this.onRemove, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _T.urgentBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _T.urgent.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          cond['name'] ?? '',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _T.urgent,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 14, color: _T.urgent),
        ),
      ],
    ),
  );
}

// ── Patient Add Form Sheet ────────────────────────────────────────────────────

const List<String> _kChronicDiseases = [
  'Diabetes',
  'Hypertension',
  'Heart Disease',
  'Asthma',
  'Chronic Kidney Disease',
];

class _PatForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final Future<void> Function() onSaved;
  final void Function(String, {bool err}) snack;
  const _PatForm({
    this.existing,
    required this.onSaved,
    required this.snack,
    Key? key,
  }) : super(key: key);
  @override
  State<_PatForm> createState() => _PatFormState();
}

class _PatFormState extends State<_PatForm> {
  final _fn = TextEditingController();
  final _ln = TextEditingController();
  final _ph = TextEditingController();
  final _nid = TextEditingController();
  final _em = TextEditingController();
  String _gender = 'MALE';
  DateTime? _dob;
  bool _saving = false;
  final List<String> _selectedDiseases = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _fn.text = e['first_name'] ?? '';
      _ln.text = e['last_name'] ?? '';
      _ph.text = e['phone'] ?? '';
      _nid.text = e['national_id'] ?? '';
      _em.text = e['email'] ?? '';
      _gender = (e['gender'] ?? 'MALE').toString().toUpperCase();
      try {
        final dob = e['birth_date'] ?? e['date_of_birth'];
        if (dob != null) _dob = DateTime.parse(dob.toString());
      } catch (_) {}
      final saved = e['chronic_diseases'];
      if (saved is List) {
        _selectedDiseases.addAll(saved.cast<String>());
      }
    }
  }

  @override
  void dispose() {
    _fn.dispose();
    _ln.dispose();
    _ph.dispose();
    _nid.dispose();
    _em.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_fn.text.trim().isEmpty || _ln.text.trim().isEmpty) {
      widget.snack('First and last name are required.', err: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'first_name': _fn.text.trim(),
        'last_name': _ln.text.trim(),
        if (_ph.text.isNotEmpty) 'phone': _ph.text.trim(),
        if (_nid.text.isNotEmpty) 'national_id': _nid.text.trim(),
        if (_em.text.isNotEmpty) 'email': _em.text.trim(),
        'gender': _gender,
        if (_dob != null) 'birth_date': DateFormat('yyyy-MM-dd').format(_dob!),
        'chronic_diseases': _selectedDiseases,
      };
      if (widget.existing != null) {
        final pid = int.parse(widget.existing!['id'].toString());
        await ApiService.updatePatient(pid, data);
      } else {
        await ApiService.createPatient(data);
      }
      await widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      widget.snack(ApiService.extractError(e), err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _T.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 20),
            Text(
              widget.existing != null ? 'Edit Patient' : 'Add New Patient',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _T.textH,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fn,
                    decoration: _T.inp('First Name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ln,
                    decoration: _T.inp('Last Name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ph,
              keyboardType: TextInputType.phone,
              decoration: _T.inp(
                'Phone Number',
                pre: const Icon(Icons.phone_rounded, size: 18, color: _T.textM),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nid,
              decoration: _T.inp(
                'National ID',
                pre: const Icon(Icons.badge_rounded, size: 18, color: _T.textM),
              ),
            ),
            const SizedBox(height: 14),
            // Gender
            Row(
              children: [
                const Text(
                  'Gender: ',
                  style: TextStyle(fontSize: 13, color: _T.textS),
                ),
                const SizedBox(width: 8),
                _GBtn(
                  label: 'Male',
                  val: 'MALE',
                  sel: _gender == 'MALE',
                  onTap: () => setState(() => _gender = 'MALE'),
                ),
                const SizedBox(width: 8),
                _GBtn(
                  label: 'Female',
                  val: 'FEMALE',
                  sel: _gender == 'FEMALE',
                  onTap: () => setState(() => _gender = 'FEMALE'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // DOB
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime(1990),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _dob = d);
              },
              child: InputDecorator(
                decoration: _T.inp(
                  'Date of Birth',
                  pre: const Icon(
                    Icons.cake_rounded,
                    size: 18,
                    color: _T.textM,
                  ),
                ),
                child: Text(
                  _dob != null
                      ? DateFormat('dd MMM yyyy').format(_dob!)
                      : 'Tap to select',
                  style: TextStyle(
                    fontSize: 13,
                    color: _dob != null ? _T.textH : _T.textM,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Diseases / Conditions
            // Chronic Diseases
            Row(
              children: [
                const Text(
                  'Chronic Diseases',
                  style: TextStyle(fontSize: 13, color: _T.textS),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${_selectedDiseases.length}/5)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Cannot add new diseases',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: _T.textM,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kChronicDiseases.map((disease) {
                final selected = _selectedDiseases.contains(disease);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedDiseases.remove(disease);
                    } else {
                      _selectedDiseases.add(disease);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFF3E5F5) : _T.bgInput,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF6A1B9A).withOpacity(0.5)
                            : _T.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Color(0xFF6A1B9A),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          disease,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? const Color(0xFF6A1B9A)
                                : _T.textS,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.existing != null
                            ? 'Save Changes'
                            : 'Add Patient',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GBtn extends StatelessWidget {
  final String label, val;
  final bool sel;
  final VoidCallback onTap;
  const _GBtn({
    required this.label,
    required this.val,
    required this.sel,
    required this.onTap,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: sel ? _T.navy : _T.bgInput,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? _T.navy : _T.divider),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: sel ? Colors.white : _T.textS,
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE 4 — FINANCE
// ═══════════════════════════════════════════════════════════════════════════════

class _FinancePage extends StatefulWidget {
  final List<Map<String, dynamic>> appointments;
  final bool loading;
  const _FinancePage({
    required this.appointments,
    required this.loading,
    Key? key,
  }) : super(key: key);
  @override
  State<_FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<_FinancePage> {
  bool _unpaidOnly = false;

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _name(Map<String, dynamic> a) {
    final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
    final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
    return '$fn $ln'.trim().ifEmpty('Unknown');
  }

  List<Map<String, dynamic>> get _billable {
    final list =
        widget.appointments
            .where((a) => (a['status'] ?? '').toUpperCase() != 'CANCELLED')
            .toList()
          ..sort(
            (a, b) => (_dt(b['start_time']) ?? DateTime.now()).compareTo(
              _dt(a['start_time']) ?? DateTime.now(),
            ),
          );
    return _unpaidOnly
        ? list.where((a) => a['is_paid'] != true).toList()
        : list;
  }

  Map<String, double> get _stats {
    double total = 0, paid = 0;
    for (final a in widget.appointments) {
      if ((a['status'] ?? '').toUpperCase() == 'CANCELLED') continue;
      final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0;
      total += fee;
      if (a['is_paid'] == true) paid += fee;
    }
    return {'total': total, 'paid': paid, 'unpaid': total - paid};
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    final rate = s['total']! > 0 ? s['paid']! / s['total']! : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // ── Revenue hero ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(22),
            decoration: _T.gradCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Revenue',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${s['total']!.toStringAsFixed(0)} EGP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _FinChip(
                        label: 'Collected',
                        value: '${s['paid']!.toStringAsFixed(0)} EGP',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF69F0AE),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FinChip(
                        label: 'Outstanding',
                        value: '${s['unpaid']!.toStringAsFixed(0)} EGP',
                        icon: Icons.pending_rounded,
                        color: const Color(0xFFFFD54F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Collection rate ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _T.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Collection Rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _T.textH,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(rate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _T.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 10,
                    backgroundColor: _T.bgInput,
                    valueColor: const AlwaysStoppedAnimation<Color>(_T.teal),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── List header ──────────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'Payment Records',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _T.textH,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _unpaidOnly = !_unpaidOnly),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _unpaidOnly ? _T.warningBg : _T.bgInput,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _unpaidOnly
                          ? _T.warning.withOpacity(0.4)
                          : _T.divider,
                    ),
                  ),
                  child: Text(
                    'Unpaid only',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _unpaidOnly ? _T.warning : _T.textS,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── List ─────────────────────────────────────────────────────────
          if (widget.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: _T.navy,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_billable.isEmpty)
            const _Empty(
              icon: Icons.receipt_long_outlined,
              title: 'No payment records',
              sub: 'Payments appear here after booking.',
            )
          else
            ..._billable.map((a) => _buildRow(a)),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> a) {
    final dt = _dt(a['start_time']);
    final isPaid = a['is_paid'] == true;
    final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0.0;
    final type =
        a['appointment_type_name'] ?? a['appointment_type'] ?? 'Consultation';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid
              ? _T.success.withOpacity(0.2)
              : _T.warning.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPaid ? _T.successBg : _T.warningBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: isPaid ? _T.success : _T.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name(a),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.textH,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    type,
                    if (dt != null) DateFormat('dd MMM').format(dt),
                  ].join('  •  '),
                  style: const TextStyle(fontSize: 11, color: _T.textS),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${fee.toStringAsFixed(0)} EGP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isPaid ? _T.success : _T.warning,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isPaid ? _T.successBg : _T.warningBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isPaid ? 'PAID' : 'UNPAID',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isPaid ? _T.success : _T.warning,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _FinChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONSULTATION PAGE  (pushed as a full screen route)
// ═══════════════════════════════════════════════════════════════════════════════

class _ConsultationPage extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final UserProfile doctorProfile;
  const _ConsultationPage({
    required this.appointment,
    required this.doctorProfile,
    Key? key,
  }) : super(key: key);
  @override
  State<_ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<_ConsultationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  Map<String, dynamic>? _visit;
  bool _startingVisit = true;

  // Clinical
  final _complaintCtrl = TextEditingController();
  final _diagCtrl = TextEditingController();
  final _examCtrl = TextEditingController();
  final _symptomCtrl = TextEditingController();
  final List<String> _symptoms = [];

  // Prescription
  final _medName = TextEditingController();
  final _medDose = TextEditingController();
  final _medFreq = TextEditingController();
  final _medDur = TextEditingController();
  final List<Map<String, String>> _rx = [];

  // Notes
  final _notesCtrl = TextEditingController();
  bool _transcribing = false;

  // AI
  bool _aiLoading = false;
  String? _aiResult;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _initVisit();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _complaintCtrl.dispose();
    _diagCtrl.dispose();
    _examCtrl.dispose();
    _symptomCtrl.dispose();
    _medName.dispose();
    _medDose.dispose();
    _medFreq.dispose();
    _medDur.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // Helpers
  String get _patientName {
    final fn =
        widget.appointment['patient_first_name'] ??
        widget.appointment['patient']?['first_name'] ??
        '';
    final ln =
        widget.appointment['patient_last_name'] ??
        widget.appointment['patient']?['last_name'] ??
        '';
    return '$fn $ln'.trim().ifEmpty('Unknown Patient');
  }

  int get _patId =>
      int.tryParse(
        (widget.appointment['patient_id'] ??
                widget.appointment['patient']?['id'] ??
                '0')
            .toString(),
      ) ??
      0;

  int get _apptId =>
      int.tryParse((widget.appointment['id'] ?? '0').toString()) ?? 0;

  int get _visitId => int.tryParse((_visit?['id'] ?? '0').toString()) ?? 0;

  Future<void> _initVisit() async {
    try {
      if (_apptId > 0) {
        await ApiService.updateAppointmentStatus(_apptId, 'IN_PROGRESS');
      }
      final v = await ApiService.startVisit({
        'patient_id': _patId,
        if (_apptId > 0) 'appointment_id': _apptId,
        'status': 'IN_PROGRESS',
      });
      if (mounted) setState(() => _visit = v);
    } catch (e) {
      _snack('Could not start visit: ${ApiService.extractError(e)}', err: true);
    } finally {
      if (mounted) setState(() => _startingVisit = false);
    }
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bgPage,
      body: Column(
        children: [
          _buildHeader(),
          _buildPatientBar(),
          _buildTabBar(),
          Expanded(
            child: _startingVisit
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: _T.navy,
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Starting consultation...',
                          style: TextStyle(fontSize: 13, color: _T.textS),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabs,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _clinicalTab(),
                      _prescriptionTab(),
                      _notesTab(),
                      _aiTab(),
                    ],
                  ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(gradient: _T.gNavy),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
              onPressed: _confirmExit,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consultation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd MMM yyyy  •  hh:mm a',
                    ).format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (_visit != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _buildPatientBar() {
    final type =
        widget.appointment['appointment_type_name'] ??
        widget.appointment['appointment_type'] ??
        'Consultation';
    final urgent = widget.appointment['is_urgent'] == true;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      color: const Color(0xFF0F4C75),
      child: Row(
        children: [
          _Avatar(name: _patientName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (_) {
              final diseases = List<String>.from(
                widget.appointment['patient']?['chronic_diseases'] ?? [],
              );
              if (diseases.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Wrap(
                  spacing: 4,
                  children: diseases
                      .map(
                        (d) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          if (urgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: _T.urgent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() => Container(
    color: _T.bgCard,
    child: TabBar(
      controller: _tabs,
      labelColor: _T.navy,
      unselectedLabelColor: _T.textM,
      indicatorColor: _T.navy,
      indicatorWeight: 2.5,
      isScrollable: true,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      tabs: const [
        Tab(text: 'Clinical'),
        Tab(text: 'Prescription'),
        Tab(text: 'Notes & Voice'),
        Tab(text: 'AI Assist'),
      ],
    ),
  );

  // ── Tab: Clinical ─────────────────────────────────────────────────────────

  Widget _clinicalTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        _Card(
          title: 'Chief Complaint',
          icon: Icons.chat_bubble_outline_rounded,
          child: TextField(
            controller: _complaintCtrl,
            maxLines: 2,
            decoration: _T.inp('What brings the patient in today?'),
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Symptoms',
          icon: Icons.sick_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _symptomCtrl,
                      decoration: _T.inp('Add symptom...'),
                      onSubmitted: _addSymptom,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _addSymptom(_symptomCtrl.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _T.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
              if (_symptoms.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _symptoms
                      .map(
                        (s) => _SympChip(
                          label: s,
                          onRemove: () => setState(() => _symptoms.remove(s)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Physical Examination',
          icon: Icons.monitor_heart_outlined,
          child: TextField(
            controller: _examCtrl,
            maxLines: 4,
            decoration: _T.inp('Vitals, examination findings...'),
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Diagnosis',
          icon: Icons.psychology_outlined,
          child: Column(
            children: [
              TextField(
                controller: _diagCtrl,
                maxLines: 3,
                decoration: _T.inp('Enter diagnosis or ICD code...'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _tabs.animateTo(3);
                    _runAI();
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('AI Diagnosis Suggestions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _T.navy,
                    side: const BorderSide(color: _T.navy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Tab: Prescription ─────────────────────────────────────────────────────

  Widget _prescriptionTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        _Card(
          title: 'Add Medicine',
          icon: Icons.medication_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _medName,
                      decoration: _T.inp('Medicine Name'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _medDose,
                      decoration: _T.inp('Dose'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _medFreq,
                      decoration: _T.inp('Frequency (e.g. 3x/day)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _medDur,
                      decoration: _T.inp('Duration (e.g. 7 days)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _addRx,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add to Prescription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_rx.isNotEmpty) ...[
          _SecHead(title: 'Prescription (${_rx.length})'),
          const SizedBox(height: 10),
          ..._rx.asMap().entries.map(
            (e) => _RxItem(
              index: e.key + 1,
              med: e.value,
              onRemove: () => setState(() => _rx.removeAt(e.key)),
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _T.card(),
            child: const Center(
              child: Text(
                'No medicines added yet.\nUse the form above to build the prescription.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _T.textS),
              ),
            ),
          ),
      ],
    ),
  );

  // ── Tab: Notes & Voice ────────────────────────────────────────────────────

  Widget _notesTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        _Card(
          title: 'Voice Report',
          icon: Icons.mic_rounded,
          child: Column(
            children: [
              VoiceRecordingWidget(
                onRecordingComplete: (path) => _transcribe(path),
              ),
              if (_transcribing) ...[
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _T.navy,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Transcribing audio...',
                      style: TextStyle(fontSize: 12, color: _T.textS),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Medical Images',
          icon: Icons.image_outlined,
          child: Row(
            children: [
              _ImgBtn(
                label: 'Camera',
                icon: Icons.camera_alt_rounded,
                onTap: () => _pickImg(ImageSource.camera),
              ),
              const SizedBox(width: 10),
              _ImgBtn(
                label: 'Gallery',
                icon: Icons.photo_library_rounded,
                onTap: () => _pickImg(ImageSource.gallery),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: "Doctor's Notes",
          icon: Icons.edit_note_rounded,
          child: TextField(
            controller: _notesCtrl,
            maxLines: 8,
            decoration: _T.inp('Additional notes, follow-up instructions...'),
          ),
        ),
      ],
    ),
  );

  // ── Tab: AI Assist ────────────────────────────────────────────────────────

  Widget _aiTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _T.gradCard(),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Clinical Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Based on symptoms & findings',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _aiLoading ? null : _runAI,
            icon: _aiLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.psychology_rounded, size: 18),
            label: Text(_aiLoading ? 'Analyzing...' : 'Analyze & Suggest'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        if (_aiResult != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _T.tealPale,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _T.teal.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      color: _T.teal,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Suggestions',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _T.teal,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() => _diagCtrl.text = _aiResult!);
                        _tabs.animateTo(0);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Apply to Diagnosis',
                        style: TextStyle(
                          color: _T.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _aiResult!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _T.textH,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _T.bgInput,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'For better suggestions:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _T.textS,
                ),
              ),
              const SizedBox(height: 8),
              for (final hint in const [
                '• Fill in the Chief Complaint',
                '• Add patient symptoms',
                '• Enter examination findings',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    hint,
                    style: const TextStyle(fontSize: 12, color: _T.textS),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Bottom actions ────────────────────────────────────────────────────────

  Widget _buildActions() => Container(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 14,
      bottom: MediaQuery.of(context).padding.bottom + 14,
    ),
    decoration: BoxDecoration(
      color: _T.bgCard,
      boxShadow: [
        BoxShadow(
          color: _T.navy.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => _save(complete: false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _T.navy),
              foregroundColor: _T.navy,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Draft',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _saving ? null : () => _save(complete: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Complete Consultation',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
          ),
        ),
      ],
    ),
  );

  // ── Logic ─────────────────────────────────────────────────────────────────

  void _addSymptom(String s) {
    final t = s.trim();
    if (t.isNotEmpty && !_symptoms.contains(t)) {
      setState(() => _symptoms.add(t));
    }
    _symptomCtrl.clear();
  }

  void _addRx() {
    if (_medName.text.trim().isEmpty) {
      _snack('Enter medicine name', err: true);
      return;
    }
    setState(() {
      _rx.add({
        'name': _medName.text.trim(),
        'dose': _medDose.text.trim(),
        'frequency': _medFreq.text.trim(),
        'duration': _medDur.text.trim(),
      });
    });
    _medName.clear();
    _medDose.clear();
    _medFreq.clear();
    _medDur.clear();
  }

  Future<void> _transcribe(String path) async {
    if (_visitId == 0) {
      _snack('Visit not started yet.', err: true);
      return;
    }
    setState(() => _transcribing = true);
    try {
      final r = await ApiService.transcribeAudio(
        audioFile: File(path),
        visitId: _visitId,
      );
      final txt = r['transcription'] ?? r['text'] ?? r['content'] ?? '';
      if (txt.toString().isNotEmpty && mounted) {
        setState(
          () => _notesCtrl.text =
              '${_notesCtrl.text}\n\n[Voice Transcript]\n$txt'.trim(),
        );
        _snack('Transcription added to notes');
      }
    } catch (e) {
      _snack('Transcription failed: ${ApiService.extractError(e)}', err: true);
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  Future<void> _pickImg(ImageSource src) async {
    final file = await AIService.pickImage(source: src);
    if (file == null || !mounted) return;
    _snack('Analyzing image...');
    try {
      final r = await AIService.scanMedicalImage(file);
      if (r['error'] != null) {
        _snack('Analysis failed: ${r['error']}', err: true);
        return;
      }
      final findings = r['findings'] ?? 'No findings';
      final severity = r['severity'] ?? '';
      if (mounted) {
        setState(
          () => _notesCtrl.text =
              '${_notesCtrl.text}\n\n[AI Image Analysis]\nFindings: $findings\nSeverity: $severity'
                  .trim(),
        );
        _snack('Image analysis complete');
      }
      if (_visitId > 0) {
        await ApiService.uploadMedicalImage(
          imageFile: file,
          visitId: _visitId,
          imageType: 'general',
          description: findings,
        );
      }
    } catch (e) {
      _snack('Image error: $e', err: true);
    }
  }

  Future<void> _runAI() async {
    final complaint = _complaintCtrl.text.trim();
    final syms = _symptoms.join(', ');
    final exam = _examCtrl.text.trim();
    if (complaint.isEmpty && syms.isEmpty) {
      _snack('Fill in complaint or symptoms first', err: true);
      return;
    }
    setState(() => _aiLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted)
        setState(
          () => _aiResult =
              'Based on the clinical presentation:\n'
              '${complaint.isNotEmpty ? "• Chief Complaint: $complaint\n" : ""}'
              '${syms.isNotEmpty ? "• Symptoms: $syms\n" : ""}'
              '${exam.isNotEmpty ? "• Examination: $exam\n" : ""}'
              '\nConsiderations:\n'
              '• Review patient history and previous visits\n'
              '• Consider relevant differential diagnoses\n'
              '• Order lab tests if clinically indicated\n'
              '• Schedule follow-up in 1–2 weeks\n\n'
              '⚠️ AI suggestions are advisory only. Clinical judgment prevails.',
        );
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _save({required bool complete}) async {
    if (_visitId == 0) {
      _snack('Visit not started.', err: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final rxTxt = _rx.isEmpty
          ? ''
          : _rx
                .map(
                  (m) =>
                      '${m['name']} — ${m['dose']} — ${m['frequency']} — ${m['duration']}',
                )
                .join('\n');

      final content = [
        if (_complaintCtrl.text.isNotEmpty)
          'Chief Complaint: ${_complaintCtrl.text.trim()}',
        if (_symptoms.isNotEmpty) 'Symptoms: ${_symptoms.join(', ')}',
        if (_examCtrl.text.isNotEmpty) 'Examination: ${_examCtrl.text.trim()}',
        if (_diagCtrl.text.isNotEmpty) 'Diagnosis: ${_diagCtrl.text.trim()}',
        if (rxTxt.isNotEmpty) 'Prescription:\n$rxTxt',
        if (_notesCtrl.text.isNotEmpty) 'Notes: ${_notesCtrl.text.trim()}',
      ].join('\n\n');

      await ApiService.createMedicalReport({
        'visit_id': _visitId,
        'patient_id': _patId,
        'content': content,
        if (_diagCtrl.text.isNotEmpty) 'diagnosis': _diagCtrl.text.trim(),
        if (_complaintCtrl.text.isNotEmpty)
          'chief_complaint': _complaintCtrl.text.trim(),
        if (rxTxt.isNotEmpty) 'prescription': rxTxt,
        'status': complete ? 'COMPLETED' : 'DRAFT',
      });

      if (complete) {
        await ApiService.updateVisitStatus(_visitId, 'COMPLETED');
        if (_apptId > 0) {
          await ApiService.updateAppointmentStatus(_apptId, 'COMPLETED');
        }
      }
      _snack(complete ? 'Consultation completed!' : 'Draft saved');
      if (complete && mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Error: ${ApiService.extractError(e)}', err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave Consultation?'),
        content: const Text('Save a draft before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _save(complete: false);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Draft'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.urgent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

// ── Consultation sub-widgets ──────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _T.card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: _T.navy),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _T.textH,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _SympChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _SympChip({required this.label, required this.onRemove, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _T.infoBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _T.info.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _T.info,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 14, color: _T.info),
        ),
      ],
    ),
  );
}

class _RxItem extends StatelessWidget {
  final int index;
  final Map<String, String> med;
  final VoidCallback onRemove;
  const _RxItem({
    required this.index,
    required this.med,
    required this.onRemove,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: _T.card(r: 12),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: _T.tealPale, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _T.teal,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                med['name'] ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _T.textH,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                [
                  med['dose'],
                  med['frequency'],
                  med['duration'],
                ].where((s) => s != null && s.isNotEmpty).join('  •  '),
                style: const TextStyle(fontSize: 11, color: _T.textS),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: _T.urgent,
            size: 20,
          ),
          onPressed: onRemove,
        ),
      ],
    ),
  );
}

class _ImgBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ImgBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _T.bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: _T.navy, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: _T.textS)),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTENSION
// ═══════════════════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════════
// DOCTOR PROFILE PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class _DoctorProfilePage extends StatelessWidget {
  final UserProfile doctorProfile;
  const _DoctorProfilePage({required this.doctorProfile, Key? key})
    : super(key: key);

  String _fmt(DateTime? d) {
    if (d == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(d);
  }

  int? get _age {
    if (doctorProfile.birthDate == null) return null;
    return ((DateTime.now().difference(doctorProfile.birthDate!).inDays) /
            365.25)
        .floor();
  }

  @override
  Widget build(BuildContext context) {
    final name = doctorProfile.fullName.ifEmpty('${doctorProfile.username}');

    return Scaffold(
      backgroundColor: _T.bgPage,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(gradient: _T.gNavy),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Back button row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'My Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar + name
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
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
                          child: _Avatar(name: name, size: 72),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. $name',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if ((doctorProfile.clinicName ?? '')
                                      .isNotEmpty)
                                    _ProfileBadge(
                                      icon: Icons.local_hospital_rounded,
                                      label: doctorProfile.clinicName!,
                                    ),
                                  _ProfileBadge(
                                    icon: Icons.medical_services_rounded,
                                    label:
                                        doctorProfile.specialization ??
                                        'Doctor',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Personal info card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: _T.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: _T.navy,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _T.textH,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: _T.divider),
                        const SizedBox(height: 14),
                        _ProfileRow('Full Name', 'Dr. $name'),
                        _ProfileRow('Email', doctorProfile.email),
                        _ProfileRow(
                          'Gender',
                          doctorProfile.gender.isEmpty
                              ? 'N/A'
                              : doctorProfile.gender[0].toUpperCase() +
                                    doctorProfile.gender.substring(1),
                        ),
                        _ProfileRow(
                          'Date of Birth',
                          doctorProfile.birthDate != null
                              ? _fmt(doctorProfile.birthDate)
                              : 'N/A',
                        ),
                        if (_age != null) _ProfileRow('Age', '$_age years'),
                        _ProfileRow('Role', 'Doctor'),
                        _ProfileRow(
                          'Clinic',
                          doctorProfile.clinicName ?? 'N/A',
                        ),
                        _ProfileRow(
                          'Specialization',
                          doctorProfile.specialization ?? 'N/A',
                        ),
                        if ((doctorProfile.licenseNumber ?? '').isNotEmpty)
                          _ProfileRow(
                            'License No.',
                            doctorProfile.licenseNumber!,
                          ),
                        _ProfileRow('Joined', _fmt(doctorProfile.createdAt)),
                      ],
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
}

class _ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ProfileBadge({required this.icon, required this.label, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
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
          width: 120,
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

extension _Str on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
