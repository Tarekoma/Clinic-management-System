// ═══════════════════════════════════════════════════════════════════════════════
// Assistant_Interface.dart  —  Complete Redesign  (paste-ready, single file)
// Replace your existing Assistant_Interface.dart with this file.
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Hakim/Login%20Page.dart';
import 'package:Hakim/UserProfile.dart';
import 'package:Hakim/api_service.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS  (green / teal theme — distinct from Doctor navy theme)
// ═══════════════════════════════════════════════════════════════════════════════

class _T {
  _T._();
  // Brand
  static const Color green = Color(0xFF00695C);
  static const Color greenDeep = Color(0xFF004D40);
  static const Color greenLight = Color(0xFF26A69A);
  static const Color greenPale = Color(0xFFE0F2F1);
  static const Color emerald = Color(0xFF43A047);
  // Surface
  static const Color bgPage = Color(0xFFF0F7F5);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFF5F9F8);
  static const Color divider = Color(0xFFDCEDE9);
  // Status
  static const Color urgent = Color(0xFFD32F2F);
  static const Color urgentBg = Color(0xFFFDEDED);
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF1565C0);
  static const Color infoBg = Color(0xFFE3F2FD);
  static const Color confirmed = Color(0xFF6A1B9A);
  static const Color confirmedBg = Color(0xFFF3E5F5);
  static const Color muted = Color(0xFF78909C);
  static const Color mutedBg = Color(0xFFF5F5F5);
  // Text
  static const Color textH = Color(0xFF0D1F1C);
  static const Color textS = Color(0xFF4A6360);
  static const Color textM = Color(0xFF90A4A0);
  // Gradients
  static const LinearGradient gGreen = LinearGradient(
    colors: [Color(0xFF004D40), Color(0xFF00695C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gEmerald = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
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
      case 'CONFIRMED':
        return confirmed;
      case 'IN_PROGRESS':
        return green;
      case 'COMPLETED':
        return success;
      case 'CANCELLED':
      case 'NO_SHOW':
        return muted;
      default:
        return textS;
    }
  }

  static Color sBg(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':
        return infoBg;
      case 'CONFIRMED':
        return confirmedBg;
      case 'IN_PROGRESS':
        return greenPale;
      case 'COMPLETED':
        return successBg;
      case 'CANCELLED':
      case 'NO_SHOW':
        return mutedBg;
      default:
        return mutedBg;
    }
  }

  static String sLabel(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':
        return 'Scheduled';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'NO_SHOW':
        return 'No Show';
      default:
        return s;
    }
  }

  static BoxDecoration card({double r = 16, Color? bg}) => BoxDecoration(
    color: bg ?? bgCard,
    borderRadius: BorderRadius.circular(r),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF00695C).withOpacity(0.07),
        blurRadius: 18,
        offset: const Offset(0, 5),
      ),
    ],
  );
  static BoxDecoration gradCard({LinearGradient g = gGreen, double r = 18}) =>
      BoxDecoration(
        gradient: g,
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      );

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
      borderSide: const BorderSide(color: green, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  static final _ac = [
    const Color(0xFF00695C),
    const Color(0xFF388E3C),
    const Color(0xFF0277BD),
    const Color(0xFF6A1B9A),
    const Color(0xFF00838F),
    const Color(0xFFAD1457),
    const Color(0xFF4E342E),
    const Color(0xFF1565C0),
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

class _SectionHead extends StatelessWidget {
  final String title;
  const _SectionHead({required this.title, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _T.textH,
        letterSpacing: 0.2,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN ASSISTANT INTERFACE
// ═══════════════════════════════════════════════════════════════════════════════

class AssistantInterface extends StatefulWidget {
  final UserProfile assistantProfile;
  const AssistantInterface({Key? key, required this.assistantProfile})
    : super(key: key);
  @override
  State<AssistantInterface> createState() => _AssistantInterfaceState();
}

class _AssistantInterfaceState extends State<AssistantInterface> {
  int _selectedIndex = 1;

  // ── Data ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _doctors = [];

  bool _loadingPatients = false;
  bool _loadingAppointments = false;
  bool _patientsError = false;
  bool _appointmentsError = false;

  final _apptSearchCtrl = TextEditingController();
  final _patientSearchCtrl = TextEditingController();

  String get _clinic => widget.assistantProfile.clinicName ?? '';

  // ── Init ──────────────────────────────────────────────────────────────────

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

  // ── Data Fetchers ─────────────────────────────────────────────────────────

  Future<void> _loadAll() =>
      Future.wait([_fetchPatients(), _fetchAppointments(), _fetchDoctors()]);

  Future<void> _fetchPatients({String search = ''}) async {
    if (!mounted) return;
    setState(() {
      _loadingPatients = true;
      _patientsError = false;
    });
    try {
      final data = await ApiService.getPatients(search: search);
      if (mounted)
        setState(() => _patients = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) {
        setState(() => _patientsError = true);
        _snack(
          'Failed to load patients: ${ApiService.extractError(e)}',
          err: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPatients = false);
    }
  }

  Future<void> _fetchAppointments() async {
    if (!mounted) return;
    setState(() {
      _loadingAppointments = true;
      _appointmentsError = false;
    });
    try {
      final data = await ApiService.getAppointments();
      if (mounted) {
        final list = List<Map<String, dynamic>>.from(data);
        list.sort((a, b) {
          DateTime? da, db;
          try {
            da = DateTime.parse(a['start_time'].toString()).toLocal();
          } catch (_) {}
          try {
            db = DateTime.parse(b['start_time'].toString()).toLocal();
          } catch (_) {}
          return (da ?? DateTime.now()).compareTo(db ?? DateTime.now());
        });
        setState(() => _appointments = list);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _appointmentsError = true);
        _snack(
          'Failed to load appointments: ${ApiService.extractError(e)}',
          err: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      final data = await ApiService.getDoctors();
      if (mounted)
        setState(() => _doctors = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  // ── Filtered lists ────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredPatients {
    final q = _patientSearchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _patients;
    return _patients.where((p) {
      final nm = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
          .toLowerCase();
      final ph = (p['phone'] ?? '').toString().toLowerCase();
      final nid = (p['national_id'] ?? '').toString().toLowerCase();
      return nm.contains(q) || ph.contains(q) || nid.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    final q = _apptSearchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _appointments;
    return _appointments.where((a) {
      final nm = _apptName(a).toLowerCase();
      final ph = (a['patient']?['phone'] ?? '').toString().toLowerCase();
      final nid = (a['patient']?['national_id'] ?? '').toString().toLowerCase();
      return nm.contains(q) || ph.contains(q) || nid.contains(q);
    }).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _patName(Map<String, dynamic> p) =>
      '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();

  String _apptName(Map<String, dynamic> a) {
    if (a['patient_name'] != null) return a['patient_name'].toString();
    final fn = a['patient_first_name'] ?? a['patient']?['first_name'] ?? '';
    final ln = a['patient_last_name'] ?? a['patient']?['last_name'] ?? '';
    return '$fn $ln'.trim().ifEmpty('Unknown Patient');
  }

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _toIso8601WithTz(DateTime dt) {
    final tz = dt.timeZoneOffset;
    final sign = tz.isNegative ? '-' : '+';
    final hh = tz.inHours.abs().toString().padLeft(2, '0');
    final mm = (tz.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${DateFormat("yyyy-MM-ddTHH:mm:ss").format(dt)}$sign$hh:$mm';
  }

  Map<String, double> _paymentStats() {
    double total = 0, paid = 0;
    for (final a in _appointments) {
      if ((a['status'] ?? '').toUpperCase() == 'CANCELLED') continue;
      final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0.0;
      total += fee;
      if (a['is_paid'] == true) paid += fee;
    }
    return {'total': total, 'paid': paid, 'unpaid': total - paid};
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

  // ── Scaffold ──────────────────────────────────────────────────────────────

  static const _navItems = [
    _NavItem(Icons.person_rounded, 'Profile'),
    _NavItem(Icons.calendar_month_rounded, 'Appointments'),
    _NavItem(Icons.people_alt_rounded, 'Patients'),
    _NavItem(Icons.account_balance_wallet_rounded, 'Payments'),
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

  Widget _buildTopBar() => Container(
    decoration: const BoxDecoration(gradient: _T.gGreen),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 10, 12),
        child: Row(
          children: [
            _Avatar(name: widget.assistantProfile.fullName, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.assistantProfile.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (_clinic.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          _clinic,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
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
            ),
          ],
        ),
      ),
    ),
  );

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() => Container(
    decoration: BoxDecoration(
      color: _T.bgCard,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF00695C).withOpacity(0.10),
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
                splashColor: _T.green.withOpacity(0.08),
                highlightColor: Colors.transparent,
                child: Column(
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
                            ? _T.green.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        color: sel ? _T.green : _T.textM,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? _T.green : _T.textM,
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

  // ── Page router ───────────────────────────────────────────────────────────

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildProfile();
      case 1:
        return _buildAppointments();
      case 2:
        return _buildPatients();
      case 3:
        return _buildPayments();
      default:
        return _buildAppointments();
    }
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 0 — PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfile() {
    final p = widget.assistantProfile;
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _T.green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Hero banner ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: _T.gradCard(),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.firstName.isEmpty ? p.fullName : p.firstName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _infoPill(
                              Icons.local_hospital_outlined,
                              _clinic.isEmpty ? 'No Clinic' : _clinic,
                            ),
                            const SizedBox(width: 8),
                            _infoPill(Icons.badge_rounded, 'Assistant'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        p.fullName.isNotEmpty
                            ? p.fullName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Quick stats ───────────────────────────────────────────────
            Row(
              children: [
                _StatCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Appointments',
                  value: '${_appointments.length}',
                  color: _T.green,
                  bg: _T.greenPale,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.people_alt_rounded,
                  label: 'Patients',
                  value: '${_patients.length}',
                  color: _T.emerald,
                  bg: const Color(0xFFE8F5E9),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Info card ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _T.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: _T.green,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _T.textH,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _IRow('Full Name', p.fullName),
                  _IRow('Email', p.email),
                  _IRow('Gender', p.gender.isEmpty ? 'N/A' : p.gender),
                  _IRow('Role', p.userType.isEmpty ? 'Assistant' : p.userType),
                  _IRow('Clinic', _clinic.isEmpty ? 'N/A' : _clinic),
                  if (p.birthDate != null)
                    _IRow(
                      'Birth Date',
                      DateFormat('dd MMM yyyy').format(p.birthDate!),
                    ),
                  _IRow(
                    'Joined',
                    DateFormat('dd MMM yyyy').format(p.createdAt),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white70),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — APPOINTMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppointments() {
    if (_appointmentsError) {
      return _errorWidget('Failed to load appointments', _fetchAppointments);
    }

    final now = DateTime.now();
    final todayDay = DateTime(now.year, now.month, now.day);
    final tomorrow = todayDay.add(const Duration(days: 1));
    final all = _filteredAppointments;

    final todayList = <Map<String, dynamic>>[];
    final upList = <Map<String, dynamic>>[];
    final pastList = <Map<String, dynamic>>[];

    for (final a in all) {
      final dt = _dt(a['start_time']);
      if (dt == null) continue;
      final day = DateTime(dt.year, dt.month, dt.day);
      if (!day.isBefore(todayDay) && day.isBefore(tomorrow)) {
        todayList.add(a);
      } else if (!day.isBefore(tomorrow)) {
        upList.add(a);
      } else {
        pastList.add(a);
      }
    }

    int queueSort(Map a, Map b) {
      if ((a['is_urgent'] == true) != (b['is_urgent'] == true)) {
        return a['is_urgent'] == true ? -1 : 1;
      }
      final da = _dt(a['start_time']) ?? now;
      final db = _dt(b['start_time']) ?? now;
      return da.compareTo(db);
    }

    todayList.sort(queueSort);
    upList.sort(queueSort);

    final serving = todayList.where((a) {
      final s = (a['status'] ?? '').toUpperCase();
      return s == 'SCHEDULED' || s == 'CONFIRMED';
    }).firstOrNull;

    return Scaffold(
      backgroundColor: _T.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApptForm(context, null),
        backgroundColor: _T.green,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAppointments,
        color: _T.green,
        child: CustomScrollView(
          slivers: [
            // Search + summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    TextField(
                      controller: _apptSearchCtrl,
                      decoration: _T.inp(
                        'Search by patient name, phone...',
                        pre: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: _T.textM,
                        ),
                        suf: _apptSearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () =>
                                    setState(() => _apptSearchCtrl.clear()),
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    // Summary chips row
                    Row(
                      children: [
                        _CountChip(
                          label: 'Today',
                          count: todayList.length,
                          color: _T.green,
                          bg: _T.greenPale,
                        ),
                        const SizedBox(width: 8),
                        _CountChip(
                          label: 'Upcoming',
                          count: upList.length,
                          color: _T.info,
                          bg: _T.infoBg,
                        ),
                        const SizedBox(width: 8),
                        _CountChip(
                          label: 'Urgent',
                          count: all
                              .where((a) => a['is_urgent'] == true)
                              .length,
                          color: _T.urgent,
                          bg: _T.urgentBg,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_loadingAppointments)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: _T.green,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (all.isEmpty)
              const SliverFillRemaining(
                child: _Empty(
                  icon: Icons.calendar_month_outlined,
                  title: 'No appointments found',
                  sub: 'Tap + to create a new appointment.',
                ),
              )
            else ...[
              // Now serving
              if (serving != null) ...[
                _sectionHeader('Now Serving', _T.green),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _ApptCard(
                      appt: serving,
                      highlight: true,
                      onTap: () => _showApptOptions(serving),
                    ),
                  ),
                ),
              ],
              // Today
              if (todayList.isNotEmpty) ...[
                _sectionHeader("Today's Queue", _T.green),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ApptCard(
                        appt: todayList[i],
                        onTap: () => _showApptOptions(todayList[i]),
                      ),
                      childCount: todayList.length,
                    ),
                  ),
                ),
              ],
              // Upcoming
              if (upList.isNotEmpty) ...[
                _sectionHeader('Upcoming', _T.info),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ApptCard(
                        appt: upList[i],
                        onTap: () => _showApptOptions(upList[i]),
                      ),
                      childCount: upList.length,
                    ),
                  ),
                ),
              ],
              // Past
              if (pastList.isNotEmpty) ...[
                _sectionHeader('Past', _T.muted),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ApptCard(
                        appt: pastList[i],
                        onTap: () => _showApptOptions(pastList[i]),
                      ),
                      childCount: pastList.length,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String label, Color color) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );

  // Appointment options bottom sheet
  void _showApptOptions(Map<String, dynamic> a) {
    final status = (a['status'] ?? '').toUpperCase();
    final id = int.tryParse((a['id'] ?? '0').toString()) ?? 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _T.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 8,
          left: 8,
          right: 8,
          bottom: MediaQuery.of(ctx).padding.bottom + 8,
        ),
        child: Column(
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
            const SizedBox(height: 8),
            _BottomSheetTile(
              icon: Icons.edit_rounded,
              label: 'Edit Appointment',
              color: _T.info,
              onTap: () {
                Navigator.pop(ctx);
                _showApptForm(context, a);
              },
            ),
            if (status == 'SCHEDULED')
              _BottomSheetTile(
                icon: Icons.lock_clock_rounded,
                label: 'Confirm Appointment',
                color: _T.confirmed,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateApptStatus(id, 'CONFIRMED');
                },
              ),
            if (status == 'SCHEDULED' || status == 'CONFIRMED')
              _BottomSheetTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Mark as Completed',
                color: _T.success,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateApptStatus(id, 'COMPLETED');
                },
              ),
            if (status != 'CANCELLED' && status != 'COMPLETED')
              _BottomSheetTile(
                icon: Icons.cancel_outlined,
                label: 'Cancel Appointment',
                color: _T.warning,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateApptStatus(id, 'CANCELLED');
                },
              ),
            _BottomSheetTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Appointment',
              color: _T.urgent,
              onTap: () {
                Navigator.pop(ctx);
                _deleteAppt(a);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateApptStatus(int id, String status) async {
    try {
      await ApiService.updateAppointmentStatus(id, status);
      _snack('Status updated to ${_T.sLabel(status)}');
      await _fetchAppointments();
    } catch (e) {
      _snack('Failed: ${ApiService.extractError(e)}', err: true);
    }
  }

  Future<void> _deleteAppt(Map<String, dynamic> a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Appointment'),
        content: Text(
          'Delete appointment for ${_apptName(a)}? This cannot be undone.',
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
      await ApiService.deleteAppointment(
        int.tryParse((a['id'] ?? '0').toString()) ?? 0,
      );
      await _fetchAppointments();
      _snack('Appointment deleted');
    } catch (e) {
      _snack('Failed: ${ApiService.extractError(e)}', err: true);
    }
  }

  // Appointment create / edit form
  void _showApptForm(BuildContext context, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApptForm(
        existing: existing,
        patients: _patients,
        doctors: _doctors,
        onSaved: _fetchAppointments,
        snack: _snack,
        toIso: _toIso8601WithTz,
        patName: _patName,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 2 — PATIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPatients() {
    if (_patientsError) {
      return _errorWidget('Failed to load patients', _fetchPatients);
    }
    return Scaffold(
      backgroundColor: _T.bgPage,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPatientForm(context, null),
        backgroundColor: _T.green,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add Patient',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPatients,
        color: _T.green,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _patientSearchCtrl,
                decoration: _T.inp(
                  'Search by name, phone, or national ID...',
                  pre: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: _T.textM,
                  ),
                  suf: _patientSearchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _patientSearchCtrl.clear();
                            setState(() {});
                            _fetchPatients();
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  setState(() {});
                  if (v.length >= 2 || v.isEmpty) _fetchPatients(search: v);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    '${_patients.length} patients total',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _T.textM,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (_patientSearchCtrl.text.isNotEmpty) ...[
                    const Text(
                      '  •  ',
                      style: TextStyle(fontSize: 11, color: _T.textM),
                    ),
                    Text(
                      '${_filteredPatients.length} results',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _T.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _loadingPatients
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _T.green,
                        strokeWidth: 2,
                      ),
                    )
                  : _filteredPatients.isEmpty
                  ? const _Empty(
                      icon: Icons.people_outline_rounded,
                      title: 'No patients found',
                      sub: 'Try a different search or add a new patient.',
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: _filteredPatients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = _filteredPatients[i];
                        return _PatCard(
                          patient: p,
                          onTap: () => _showPatientDetail(p),
                          onEdit: () => _showPatientForm(context, p),
                          onDelete: () => _deletePatient(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPatientDetail(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (_) => _PatientDetailPage(
        patient: p,
        appointments: _appointments,
        onEdit: () => _showPatientForm(context, p),
      ),
    );
  }

  void _showPatientForm(BuildContext context, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PatForm(existing: existing, onSaved: _fetchPatients, snack: _snack),
    );
  }

  Future<void> _deletePatient(Map<String, dynamic> p) async {
    final name = _patName(p);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Patient'),
        content: Text('Delete $name? This cannot be undone.'),
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
      await ApiService.deletePatient(p['id'] as int);
      _snack('$name deleted');
      await _fetchPatients();
    } catch (e) {
      _snack('Failed: ${ApiService.extractError(e)}', err: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 3 — PAYMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPayments() {
    final stats = _paymentStats();
    final total = stats['total']!;
    final paid = stats['paid']!;
    final unpaid = stats['unpaid']!;
    final rate = total > 0 ? paid / total : 0.0;
    final billable =
        _appointments
            .where((a) => (a['status'] ?? '').toUpperCase() != 'CANCELLED')
            .toList()
          ..sort(
            (a, b) => (_dt(b['start_time']) ?? DateTime.now()).compareTo(
              _dt(a['start_time']) ?? DateTime.now(),
            ),
          );

    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      color: _T.green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // ── Revenue hero ──────────────────────────────────────────────
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
                    '${total.toStringAsFixed(0)} EGP',
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
                          value: '${paid.toStringAsFixed(0)} EGP',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF69F0AE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FinChip(
                          label: 'Outstanding',
                          value: '${unpaid.toStringAsFixed(0)} EGP',
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

            // ── Collection rate ───────────────────────────────────────────
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
                          color: _T.green,
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
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _T.greenLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            const Text(
              'Payment Records',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _T.textH,
              ),
            ),
            const SizedBox(height: 10),

            if (_loadingAppointments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: _T.green,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (billable.isEmpty)
              const _Empty(
                icon: Icons.receipt_long_outlined,
                title: 'No payment records',
              )
            else
              ...billable.map((a) => _buildPaymentRow(a)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(Map<String, dynamic> a) {
    final isPaid = a['is_paid'] == true;
    final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0.0;
    final dt = _dt(a['start_time']);
    final name = _apptName(a);
    final type =
        (a['appointment_type'] as Map?)?['name'] ??
        a['appointment_type_name'] ??
        'Consultation';
    final id = int.tryParse((a['id'] ?? '0').toString()) ?? 0;

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
            color: _T.green.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
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
                  name,
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
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _togglePayment(id, isPaid),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid ? _T.successBg : _T.warningBg,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isPaid
                          ? _T.success.withOpacity(0.4)
                          : _T.warning.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    isPaid ? 'PAID ✓' : 'UNPAID — Tap',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isPaid ? _T.success : _T.warning,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _togglePayment(int id, bool currentlyPaid) async {
    try {
      await ApiService.updateAppointment(id, {'is_paid': !currentlyPaid});
      _snack(currentlyPaid ? 'Marked as unpaid' : 'Marked as paid');
      await _fetchAppointments();
    } catch (e) {
      _snack(
        'Failed to update payment: ${ApiService.extractError(e)}',
        err: true,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Utility Widgets
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _errorWidget(String msg, VoidCallback onRetry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _T.urgentBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: _T.urgent,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: const TextStyle(fontSize: 14, color: _T.textS),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Nav Item ──────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _IRow extends StatelessWidget {
  final String label, value;
  const _IRow(this.label, this.value, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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
              fontWeight: FontWeight.w600,
              color: _T.textH,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, bg;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
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
            ],
          ),
        ],
      ),
    ),
  );
}

// ── Finance Chip ──────────────────────────────────────────────────────────────

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

// ── Count Chip ────────────────────────────────────────────────────────────────

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color, bg;
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Bottom Sheet Tile ─────────────────────────────────────────────────────────

class _BottomSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BottomSheetTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(
      label,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onTap: onTap,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// APPOINTMENT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ApptCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final VoidCallback onTap;
  final bool highlight;
  const _ApptCard({
    required this.appt,
    required this.onTap,
    this.highlight = false,
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
    if (appt['patient_name'] != null) return appt['patient_name'].toString();
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
    final isPaid = appt['is_paid'] == true;
    final fee = double.tryParse((appt['fee'] ?? 0).toString()) ?? 0.0;
    final type =
        (appt['appointment_type'] as Map?)?['name'] ??
        appt['appointment_type_name'] ??
        'Consultation';
    final reason = (appt['reason'] ?? '').toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _T.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: urgent
                ? _T.urgent.withOpacity(0.4)
                : highlight
                ? _T.green.withOpacity(0.5)
                : _T.divider,
            width: (urgent || highlight) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (urgent ? _T.urgent : _T.green).withOpacity(0.07),
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
                  // Time column
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
                          color: _T.green,
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
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Avatar(name: _name, size: 34),
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
                                  Text(
                                    type,
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
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Badge(
                              label: _T.sLabel(status),
                              fg: _T.sFg(status),
                              bg: _T.sBg(status),
                            ),
                            _Badge(
                              label: isPaid ? 'PAID' : 'UNPAID',
                              fg: isPaid ? _T.success : _T.warning,
                              bg: isPaid ? _T.successBg : _T.warningBg,
                            ),
                            if (urgent)
                              const _Badge(
                                label: 'URGENT',
                                fg: _T.urgent,
                                bg: _T.urgentBg,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _T.textM,
                    size: 20,
                  ),
                ],
              ),
            ),
            // Footer
            if (fee > 0 || dt != null || reason.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: _T.bgInput,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    if (dt != null) ...[
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: _T.textM,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('EEE, dd MMM yyyy').format(dt),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _T.textM,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (fee > 0)
                      Text(
                        '${fee.toStringAsFixed(0)} EGP',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _T.green,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APPOINTMENT FORM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _ApptForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> doctors;
  final Future<void> Function() onSaved;
  final void Function(String, {bool err}) snack;
  final String Function(DateTime) toIso;
  final String Function(Map<String, dynamic>) patName;

  const _ApptForm({
    this.existing,
    required this.patients,
    required this.doctors,
    required this.onSaved,
    required this.snack,
    required this.toIso,
    required this.patName,
    Key? key,
  }) : super(key: key);

  @override
  State<_ApptForm> createState() => _ApptFormState();
}

class _ApptFormState extends State<_ApptForm> {
  Map<String, dynamic>? _selPatient;
  Map<String, dynamic>? _selDoctor;
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _time = TimeOfDay.now();
  String _feeType = 'consultation';
  final _feeCtrl = TextEditingController(text: '300');
  final _reasonCtrl = TextEditingController();
  bool _isPaid = false;
  bool _isUrgent = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      // pre-fill patient
      final pid = (e['patient_id'] ?? e['patient']?['id'] ?? '').toString();
      _selPatient = widget.patients
          .where((p) => p['id'].toString() == pid)
          .firstOrNull;
      // pre-fill doctor
      final did = (e['doctor_id'] ?? e['doctor']?['id'] ?? '').toString();
      _selDoctor =
          widget.doctors.where((d) => d['id'].toString() == did).firstOrNull ??
          (widget.doctors.isNotEmpty ? widget.doctors.first : null);
      // date/time
      try {
        final dt = DateTime.parse(e['start_time'].toString()).toLocal();
        _date = dt;
        _time = TimeOfDay.fromDateTime(dt);
      } catch (_) {}
      _isPaid = e['is_paid'] == true;
      _isUrgent = e['is_urgent'] == true;
      _feeCtrl.text = (e['fee'] ?? '300').toString();
      _reasonCtrl.text = e['reason'] ?? '';
    } else {
      _selDoctor = widget.doctors.isNotEmpty ? widget.doctors.first : null;
    }
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _T.green)),
        child: child!,
      ),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _T.green)),
        child: child!,
      ),
    );
    if (t == null || !mounted) return;
    setState(() {
      _date = d;
      _time = t;
    });
  }

  Future<void> _pickPatient() async {
    final ctrl = TextEditingController();
    var filtered = List.of(widget.patients);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Select Patient'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: _T.inp(
                    'Search patient...',
                    pre: const Icon(Icons.search_rounded, size: 18),
                  ),
                  onChanged: (v) {
                    final q = v.toLowerCase().trim();
                    ss(
                      () => filtered = q.isEmpty
                          ? List.of(widget.patients)
                          : widget.patients.where((p) {
                              final nm = widget.patName(p).toLowerCase();
                              final ph = (p['phone'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final nid = (p['national_id'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              return nm.contains(q) ||
                                  ph.contains(q) ||
                                  nid.contains(q);
                            }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${filtered.length} patients',
                  style: const TextStyle(fontSize: 12, color: _T.textM),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const _Empty(
                          icon: Icons.search_off_rounded,
                          title: 'No results',
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            final name = widget.patName(p);
                            return GestureDetector(
                              onTap: () => Navigator.pop(ctx, p),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: _T.card(r: 12),
                                child: Row(
                                  children: [
                                    _Avatar(name: name, size: 36),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            p['phone'] ?? '',
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) setState(() => _selPatient = result);
  }

  Future<void> _save() async {
    if (_selPatient == null) {
      widget.snack('Please select a patient', err: true);
      return;
    }
    setState(() => _saving = true);
    final dt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    try {
      final data = {
        'patient_id': _selPatient!['id'],
        if (_selDoctor != null) 'doctor_id': _selDoctor!['id'],
        'start_time': widget.toIso(dt),
        'is_paid': _isPaid,
        'is_urgent': _isUrgent,
        'fee': double.tryParse(_feeCtrl.text.trim()) ?? 0.0,
        if (_reasonCtrl.text.trim().isNotEmpty)
          'reason': _reasonCtrl.text.trim(),
      };
      if (widget.existing != null) {
        await ApiService.updateAppointment(
          int.tryParse(widget.existing!['id'].toString()) ?? 0,
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

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
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
              widget.existing != null ? 'Edit Appointment' : 'New Appointment',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _T.textH,
              ),
            ),
            const SizedBox(height: 20),

            // Patient picker
            GestureDetector(
              onTap: _pickPatient,
              child: InputDecorator(
                decoration: _T.inp(
                  'Patient *',
                  pre: const Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: _T.textM,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selPatient != null
                            ? widget.patName(_selPatient!)
                            : 'Tap to select patient',
                        style: TextStyle(
                          fontSize: 13,
                          color: _selPatient != null ? _T.textH : _T.textM,
                        ),
                      ),
                    ),
                    const Icon(Icons.search_rounded, size: 18, color: _T.textM),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Doctor picker
            if (widget.doctors.isNotEmpty) ...[
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selDoctor,
                decoration: _T.inp(
                  'Doctor',
                  pre: const Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: _T.textM,
                  ),
                ),
                items: widget.doctors
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'
                              .trim(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selDoctor = v),
              ),
              const SizedBox(height: 14),
            ],

            // Appointment type
            DropdownButtonFormField<String>(
              value: _feeType,
              decoration: _T.inp(
                'Appointment Type',
                pre: const Icon(
                  Icons.medical_services_outlined,
                  size: 18,
                  color: _T.textM,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'consultation',
                  child: Text(
                    'Consultation — 300 EGP',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                DropdownMenuItem(
                  value: 'revisit',
                  child: Text(
                    'Revisit — 150 EGP',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                _feeType = v ?? 'consultation';
                _feeCtrl.text = _feeType == 'consultation' ? '300' : '150';
              }),
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
                  DateFormat('dd MMM yyyy  •  hh:mm a').format(dateTime),
                  style: const TextStyle(fontSize: 13, color: _T.textH),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Fee
            TextField(
              controller: _feeCtrl,
              keyboardType: TextInputType.number,
              decoration: _T.inp(
                'Fee (EGP)',
                pre: const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: _T.textM,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Reason
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: _T.inp('Reason / Notes (optional)'),
            ),
            const SizedBox(height: 14),

            // Toggles
            _ToggleRow(
              label: 'Mark as Paid',
              icon: Icons.payments_rounded,
              value: _isPaid,
              color: _T.success,
              bg: _T.successBg,
              onChanged: (v) => setState(() => _isPaid = v),
            ),
            const SizedBox(height: 10),
            _ToggleRow(
              label: 'Mark as Urgent',
              icon: Icons.warning_amber_rounded,
              value: _isUrgent,
              color: _T.urgent,
              bg: _T.urgentBg,
              onChanged: (v) => setState(() => _isUrgent = v),
            ),
            const SizedBox(height: 24),

            // Save
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.green,
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

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final Color color, bg;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
    required this.bg,
    required this.onChanged,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? bg : _T.bgInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? color.withOpacity(0.4) : _T.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? color : _T.textM, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: value ? color : _T.textS,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PATIENT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _PatCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap, onEdit, onDelete;
  const _PatCard({
    required this.patient,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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
    final conds =
        (patient['conditions'] as List?)
            ?.map(
              (c) =>
                  (c['condition'] as Map? ?? {})['name']?.toString() ??
                  (c['name']?.toString() ?? ''),
            )
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    final chronic = patient['chronic_disease'] ?? '';

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
                              ? _T.info
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
                  // Conditions
                  if (conds.isNotEmpty || chronic.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children:
                          (conds.isNotEmpty
                                  ? conds.take(3)
                                  : [chronic.toString()])
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
                                    c,
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (_) => [
                _menuItem(Icons.info_outline_rounded, 'View', _T.info),
                _menuItem(Icons.edit_rounded, 'Edit', _T.green),
                _menuItem(Icons.delete_outline_rounded, 'Delete', _T.urgent),
              ],
              onSelected: (v) {
                if (v == 'View') onTap();
                if (v == 'Edit') onEdit();
                if (v == 'Delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(IconData icon, String label, Color color) =>
      PopupMenuItem<String>(
        value: label,
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PATIENT DETAIL  (full-screen dialog)
// ═══════════════════════════════════════════════════════════════════════════════

class _PatientDetailPage extends StatelessWidget {
  final Map<String, dynamic> patient;
  final List<Map<String, dynamic>> appointments;
  final VoidCallback onEdit;

  const _PatientDetailPage({
    required this.patient,
    required this.appointments,
    required this.onEdit,
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

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _appts {
    final pid = (patient['id'] ?? '').toString();
    return appointments
        .where(
          (a) =>
              (a['patient_id'] ?? a['patient']?['id'] ?? '').toString() == pid,
        )
        .toList()
      ..sort(
        (a, b) => (_dt(b['start_time']) ?? DateTime.now()).compareTo(
          _dt(a['start_time']) ?? DateTime.now(),
        ),
      );
  }

  String get _conditionsText {
    final list =
        (patient['conditions'] as List?)
            ?.map(
              (c) =>
                  (c['condition'] as Map? ?? {})['name']?.toString() ??
                  (c['name']?.toString() ?? ''),
            )
            .where((s) => s.isNotEmpty)
            .join(', ') ??
        '';
    if (list.isNotEmpty) return list;
    return (patient['chronic_disease'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final age = _age;
    final gender = (patient['gender'] ?? '').toString().toUpperCase();
    final hasChronic = _conditionsText.isNotEmpty;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: _T.bgPage,
        body: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(gradient: _T.gGreen),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      _Avatar(name: _name, size: 48),
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
                                if (age != null) '$age yrs',
                                if (gender.isNotEmpty)
                                  gender == 'MALE' ? 'Male' : 'Female',
                                if ((patient['phone'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  patient['phone'],
                              ].join('  •  '),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                            if (hasChronic) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _T.urgent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '⚠ Chronic Condition',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    _InfoCard(
                      icon: Icons.badge_rounded,
                      title: 'Patient Information',
                      color: _T.green,
                      rows: [
                        _patRow(
                          Icons.badge_outlined,
                          'ID',
                          patient['id'].toString(),
                        ),
                        _patRow(
                          Icons.phone_rounded,
                          'Phone',
                          patient['phone'] ?? 'N/A',
                        ),
                        _patRow(
                          Icons.email_rounded,
                          'Email',
                          patient['email'] ?? 'N/A',
                        ),
                        _patRow(
                          Icons.wc_rounded,
                          'Gender',
                          patient['gender'] ?? 'N/A',
                        ),
                        _patRow(
                          Icons.cake_rounded,
                          'Date of Birth',
                          patient['date_of_birth'] ??
                              patient['birth_date'] ??
                              'N/A',
                        ),
                        _patRow(
                          Icons.location_on_outlined,
                          'Address',
                          patient['address'] ?? 'N/A',
                        ),
                        _patRow(
                          Icons.fingerprint_rounded,
                          'National ID',
                          patient['national_id'] ?? 'N/A',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Conditions
                    if (hasChronic)
                      _InfoCard(
                        icon: Icons.local_hospital_outlined,
                        title: 'Chronic Conditions',
                        color: _T.urgent,
                        rows: [
                          _patRow(
                            Icons.warning_amber_rounded,
                            'Conditions',
                            _conditionsText,
                            isWarning: true,
                          ),
                        ],
                      ),

                    if (hasChronic) const SizedBox(height: 16),

                    // Appointments
                    _SectionHead(title: 'Appointments (${_appts.length})'),
                    if (_appts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _T.card(),
                        child: const Center(
                          child: Text(
                            'No appointments found',
                            style: TextStyle(fontSize: 12, color: _T.textS),
                          ),
                        ),
                      )
                    else
                      ..._appts.take(5).map((a) {
                        final dt = _dt(a['start_time']);
                        final status = (a['status'] ?? '').toUpperCase();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: _T.card(r: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: _T.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dt != null
                                      ? DateFormat(
                                          'dd MMM yyyy  •  hh:mm a',
                                        ).format(dt)
                                      : 'Unknown date',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _T.textS,
                                  ),
                                ),
                              ),
                              _Badge(
                                label: _T.sLabel(status),
                                fg: _T.sFg(status),
                                bg: _T.sBg(status),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patRow(
    IconData icon,
    String label,
    String value, {
    bool isWarning = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isWarning ? _T.urgent : _T.textM),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _T.textS),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isWarning ? _T.urgent : _T.textH,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> rows;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.rows,
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
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: _T.divider),
        const SizedBox(height: 8),
        ...rows,
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PATIENT FORM SHEET  (add / edit)
// ═══════════════════════════════════════════════════════════════════════════════

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
  final _em = TextEditingController();
  final _nid = TextEditingController();
  final _adr = TextEditingController();

  String _gender = 'male';
  DateTime? _dob;
  final Set<String> _diseases = {};
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  static const _commonDiseases = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Heart Disease',
    'Arthritis',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _fn.text = e['first_name'] ?? '';
      _ln.text = e['last_name'] ?? '';
      _ph.text = e['phone'] ?? '';
      _em.text = e['email'] ?? '';
      _nid.text = e['national_id'] ?? '';
      _adr.text = e['address'] ?? '';
      _gender = (e['gender'] ?? 'male').toString().toLowerCase();
      try {
        final dob = e['birth_date'] ?? e['date_of_birth'];
        if (dob != null) _dob = DateTime.parse(dob.toString());
      } catch (_) {}
      final chronic = (e['chronic_disease'] ?? '').toString();
      for (final d in _commonDiseases) {
        if (chronic.toLowerCase().contains(d.toLowerCase())) _diseases.add(d);
      }
    }
  }

  @override
  void dispose() {
    _fn.dispose();
    _ln.dispose();
    _ph.dispose();
    _em.dispose();
    _nid.dispose();
    _adr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'first_name': _fn.text.trim(),
      'last_name': _ln.text.trim(),
      'phone': _ph.text.trim(),
      'gender': _gender,
      if (_em.text.trim().isNotEmpty) 'email': _em.text.trim(),
      if (_nid.text.trim().isNotEmpty) 'national_id': _nid.text.trim(),
      if (_adr.text.trim().isNotEmpty) 'address': _adr.text.trim(),
      if (_dob != null) 'date_of_birth': DateFormat('yyyy-MM-dd').format(_dob!),
      if (_diseases.isNotEmpty) 'chronic_disease': _diseases.join(', '),
    };
    try {
      if (widget.existing != null) {
        await ApiService.updatePatient(widget.existing!['id'] as int, data);
        widget.snack('Patient updated successfully');
      } else {
        await ApiService.createPatient(data);
        widget.snack('Patient added successfully');
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
        child: Form(
          key: _formKey,
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

              // Name row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fn,
                      decoration: _T.inp(
                        'First Name *',
                        pre: const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: _T.textM,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ln,
                      decoration: _T.inp(
                        'Last Name *',
                        pre: const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: _T.textM,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ph,
                keyboardType: TextInputType.phone,
                decoration: _T.inp(
                  'Phone Number *',
                  pre: const Icon(
                    Icons.phone_rounded,
                    size: 18,
                    color: _T.textM,
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _em,
                keyboardType: TextInputType.emailAddress,
                decoration: _T.inp(
                  'Email (optional)',
                  pre: const Icon(
                    Icons.email_rounded,
                    size: 18,
                    color: _T.textM,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nid,
                decoration: _T.inp(
                  'National ID (optional)',
                  pre: const Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: _T.textM,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _adr,
                maxLines: 2,
                decoration: _T.inp(
                  'Address (optional)',
                  pre: const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: _T.textM,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Gender toggle
              Row(
                children: [
                  const Text(
                    'Gender: ',
                    style: TextStyle(fontSize: 13, color: _T.textS),
                  ),
                  const SizedBox(width: 8),
                  _GBtn(
                    label: 'Male',
                    val: 'male',
                    sel: _gender == 'male',
                    onTap: () => setState(() => _gender = 'male'),
                  ),
                  const SizedBox(width: 8),
                  _GBtn(
                    label: 'Female',
                    val: 'female',
                    sel: _gender == 'female',
                    onTap: () => setState(() => _gender = 'female'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // DOB
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate:
                        _dob ??
                        DateTime.now().subtract(const Duration(days: 365 * 20)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(primary: _T.green),
                      ),
                      child: child!,
                    ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dob != null
                            ? DateFormat('dd MMM yyyy').format(_dob!)
                            : 'Tap to select',
                        style: TextStyle(
                          fontSize: 13,
                          color: _dob != null ? _T.textH : _T.textM,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _T.textM,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Chronic diseases
              Row(
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 16,
                    color: Colors.red[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Chronic Diseases',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _T.divider),
                  borderRadius: BorderRadius.circular(12),
                  color: _T.bgInput,
                ),
                child: Column(
                  children: _commonDiseases.map((d) {
                    final sel = _diseases.contains(d);
                    return CheckboxListTile(
                      dense: true,
                      title: Text(d, style: const TextStyle(fontSize: 13)),
                      value: sel,
                      activeColor: Colors.red[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onChanged: (v) => setState(() {
                        if (v == true)
                          _diseases.add(d);
                        else
                          _diseases.remove(d);
                      }),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.green,
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
        color: sel ? _T.green : _T.bgInput,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? _T.green : _T.divider),
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
// EXTENSION
// ═══════════════════════════════════════════════════════════════════════════════

extension _StrExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
