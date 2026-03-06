import 'dart:io';

import 'package:Hakim/api_service.dart';
import 'package:flutter/material.dart';
import 'package:Hakim/UserProfile.dart';
import 'package:Hakim/Login Page.dart';
import 'package:intl/intl.dart';
import 'voice_recording_widget.dart';
import 'package:Hakim/AI_Service.dart';
import 'package:image_picker/image_picker.dart';

class DoctorInterface extends StatefulWidget {
  final UserProfile doctorProfile;

  const DoctorInterface({Key? key, required this.doctorProfile})
    : super(key: key);

  @override
  State<DoctorInterface> createState() => _DoctorInterfaceState();
}

class _DoctorInterfaceState extends State<DoctorInterface> {
  int _selectedIndex = 1;
  bool _isLoadingPatients = false;
  bool _isLoadingAppointments = false;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _appointmentTypes = [];

  final TextEditingController _patientSearchController =
      TextEditingController();
  final TextEditingController _appointmentSearchController =
      TextEditingController();

  String get _clinic => widget.doctorProfile.clinicName ?? '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _loadAppointments();
    _fetchAppointmentTypes();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoadingPatients = true);
    try {
      final data = await ApiService.getPatients();
      setState(() => _patients = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load patients: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      setState(() => _isLoadingPatients = false);
    }
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAppointments = true;
    });
    try {
      final data = await ApiService.getAppointments();
      if (mounted) {
        setState(() => _appointments = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoadingAppointments = false);
    }
  }

  Future<void> _loadReports({required int patientId}) async {
    try {
      final data = await ApiService.getMedicalReports(patientId: patientId);
      setState(() => _reports = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  Future<void> _fetchAppointmentTypes() async {
    try {
      final data = await ApiService.getAppointmentTypes();
      if (mounted)
        setState(
          () => _appointmentTypes = List<Map<String, dynamic>>.from(data),
        );
    } catch (_) {}
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    _appointmentSearchController.dispose();
    super.dispose();
  }

  // ─── PATIENTS ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _getPatients() => _patients;

  List<Map<String, dynamic>> _getFilteredPatients() {
    final query = _patientSearchController.text.toLowerCase().trim();
    if (query.isEmpty) return _patients;
    return _patients.where((p) {
      final name = '${p['first_name']} ${p['last_name']}'.toLowerCase();
      final phone = (p['phone'] ?? '').toLowerCase();
      final nationalId = (p['national_id'] ?? '').toLowerCase();
      return name.contains(query) ||
          phone.contains(query) ||
          nationalId.contains(query);
    }).toList();
  }

  // ─── APPOINTMENTS ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _getAppointments() {
    final list = List<Map<String, dynamic>>.from(_appointments);
    list.sort((a, b) {
      final da = _parseDate(a['start_time']) ?? DateTime.now();
      final db = _parseDate(b['start_time']) ?? DateTime.now();
      return da.compareTo(db);
    });
    return list;
  }

  List<Map<String, dynamic>> _getFilteredAppointments() {
    final query = _appointmentSearchController.text.toLowerCase().trim();
    if (query.isEmpty) return _getAppointments();
    return _getAppointments().where((a) {
      final name = _appointmentPatientName(a).toLowerCase();
      return name.contains(query);
    }).toList();
  }

  bool _isUrgentAppointment(Map<String, dynamic> a) {
    return a['is_urgent'] == true;
  }

  int _queueSort(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aStatus = (a['status'] ?? '').toLowerCase();
    final bStatus = (b['status'] ?? '').toLowerCase();
    if (aStatus != bStatus) {
      if (aStatus == 'scheduled') return -1;
      if (bStatus == 'scheduled') return 1;
    }
    final au = _isUrgentAppointment(a);
    final bu = _isUrgentAppointment(b);
    if (au != bu) return au ? -1 : 1;
    final da = _parseDate(a['start_time']) ?? DateTime.now();
    final db = _parseDate(b['start_time']) ?? DateTime.now();
    return da.compareTo(db);
  }

  String _applyUrgentPrefix(String reason, bool urgent) {
    final trimmed = reason.trim();
    final hasTag =
        trimmed.toLowerCase().startsWith('[urgent]') ||
        trimmed.toLowerCase().startsWith('urgent:');
    if (urgent) {
      if (hasTag) return trimmed;
      return trimmed.isEmpty ? '[URGENT]' : '[URGENT] $trimmed';
    } else {
      if (!hasTag) return trimmed;
      return trimmed
          .replaceFirst(RegExp(r'^\[urgent\]\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^urgent:\s*', caseSensitive: false), '')
          .trim();
    }
  }

  // ─── PAYMENTS ────────────────────────────────────────────────────────────────

  Map<String, double> _doctorPaymentStats() {
    double total = 0;
    double paid = 0;
    for (final a in _getAppointments()) {
      if ((a['status'] ?? '').toUpperCase() == 'CANCELLED') continue;
      final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0.0;
      total += fee;
      if (a['is_paid'] == true) paid += fee;
    }
    return {'total': total, 'paid': paid, 'unpaid': total - paid};
  }

  // ─── NAVIGATION ──────────────────────────────────────────────────────────────
  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDoctorProfile();
      case 1:
        return _buildDoctorAppointments();
      case 2:
        return _buildPatients();
      case 3:
        return _buildPaymentsPage();
      default:
        return _buildDoctorAppointments();
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              ApiService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.blue[700]),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.doctorProfile.fullName.substring(0, 1).toUpperCase(),
                    style: TextStyle(fontSize: 32, color: Colors.blue[700]),
                  ),
                ),
                accountName: Text(
                  widget.doctorProfile.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(widget.doctorProfile.email),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Doctor Profile'),
                selected: _selectedIndex == 0,
                onTap: () {
                  setState(() => _selectedIndex = 0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Appointments'),
                selected: _selectedIndex == 1,
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Patients'),
                selected: _selectedIndex == 2,
                onTap: () {
                  setState(() => _selectedIndex = 2);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Payments'),
                selected: _selectedIndex == 3,
                onTap: () {
                  setState(() => _selectedIndex = 3);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: _getSelectedPage(),
    );
  }

  // ─── PROFILE PAGE ─────────────────────────────────────────────────────────────

  Widget _buildDoctorProfile() {
    final p = widget.doctorProfile;
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_loadPatients(), _loadAppointments()]);
      },
      color: Colors.blue[700],
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 60,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            // ── Hero banner ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      p.fullName.isNotEmpty
                          ? p.fullName.substring(0, 1).toUpperCase()
                          : 'D',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        if ((p.specialization ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p.specialization!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Info Card ────────────────────────────────────────────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileRow(Icons.badge_outlined, 'ID', p.id),
                    _buildProfileRow(
                      Icons.person,
                      'First Name',
                      p.firstName.isEmpty ? 'N/A' : p.firstName,
                    ),
                    _buildProfileRow(
                      Icons.person_outline,
                      'Last Name',
                      p.lastName.isEmpty ? 'N/A' : p.lastName,
                    ),
                    _buildProfileRow(
                      Icons.wc,
                      'Gender',
                      p.gender.isEmpty ? 'N/A' : p.gender,
                    ),
                    _buildProfileRow(
                      Icons.phone,
                      'Phone',
                      p.phone?.isNotEmpty == true ? p.phone! : 'N/A',
                    ),
                    _buildProfileRow(
                      Icons.medical_services_outlined,
                      'Specialization',
                      p.specialization?.isNotEmpty == true
                          ? p.specialization!
                          : 'N/A',
                    ),
                    _buildProfileRow(
                      Icons.location_on_outlined,
                      'Region',
                      p.region?.isNotEmpty == true ? p.region! : 'N/A',
                    ),
                    _buildProfileRow(
                      Icons.local_hospital_outlined,
                      'Clinic',
                      p.clinicName?.isNotEmpty == true ? p.clinicName! : 'N/A',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 10),
          SizedBox(
            width: 115,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // ─── APPOINTMENTS PAGE ────────────────────────────────────────────────────────

  Widget _buildDoctorAppointments() {
    if (_isLoadingAppointments) {
      return const Center(child: CircularProgressIndicator());
    }
    final appointments = _getFilteredAppointments();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todayAppointments = appointments.where((a) {
      final dt = _parseDate(a['start_time']);
      if (dt == null) return false;
      return !dt.isBefore(today) && dt.isBefore(tomorrow);
    }).toList()..sort(_queueSort);

    final upcomingAppointments = appointments.where((a) {
      final dt = _parseDate(a['start_time']);
      if (dt == null) return false;
      return !dt.isBefore(tomorrow);
    }).toList()..sort(_queueSort);

    final pastAppointments = appointments.where((a) {
      final dt = _parseDate(a['start_time']);
      if (dt == null) return false;
      return dt.isBefore(today);
    }).toList()..sort(_queueSort);

    final nextUp = todayAppointments
        .where((a) => (a['status'] ?? '').toLowerCase() == 'scheduled')
        .toList();
    final firstUp = nextUp.isNotEmpty ? nextUp.first : null;

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: Colors.blue[700],
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 60,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointments',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Clinic: ${_clinic.isEmpty ? "N/A" : _clinic}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showCreateAppointmentDialog,
                icon: const Icon(Icons.add),
                label: const Text('New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _appointmentSearchController,
            decoration: InputDecoration(
              hintText: 'Search by patient name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _appointmentSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _appointmentSearchController.clear()),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (firstUp != null) ...[
            const Text(
              'Now Serving',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildAppointmentCard(firstUp, highlight: true),
            const SizedBox(height: 16),
          ],
          if (todayAppointments.isNotEmpty) ...[
            const Text(
              "Today's Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...todayAppointments.map((a) => _buildAppointmentCard(a)),
            const SizedBox(height: 10),
          ],
          if (upcomingAppointments.isNotEmpty) ...[
            const Text(
              'Upcoming Appointments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...upcomingAppointments.map((a) => _buildAppointmentCard(a)),
          ],
          if (pastAppointments.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Past Appointments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...pastAppointments.map((a) => _buildAppointmentCard(a)),
          ],
          if (todayAppointments.isEmpty &&
              upcomingAppointments.isEmpty &&
              pastAppointments.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  'No appointments scheduled',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment, {
    bool highlight = false,
  }) {
    final status = (appointment['status'] ?? '').toLowerCase();
    final statusColor = status == 'completed'
        ? Colors.green
        : status == 'cancelled'
        ? Colors.red
        : Colors.blue;
    final isPaid = appointment['is_paid'] == true;
    final paidColor = isPaid ? Colors.green : Colors.orange;
    final urgent = _isUrgentAppointment(appointment);
    final patientName = _appointmentPatientName(appointment);
    final dateTime = _parseDate(appointment['start_time']) ?? DateTime.now();
    final reason = appointment['reason'] ?? '';
    final fee = double.tryParse((appointment['fee'] ?? 0).toString()) ?? 0.0;

    return InkWell(
      onTap: () => _showStartNewReportDialog(appointment),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: highlight ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highlight
              ? BorderSide(color: Colors.blue.shade300, width: 1.5)
              : BorderSide.none,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: urgent ? Colors.red : statusColor,
            child: Icon(
              status == 'completed' ? Icons.check : Icons.calendar_today,
              color: Colors.white,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  patientName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (urgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(DateFormat('dd/MM/yyyy - hh:mm a').format(dateTime)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      status.toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: statusColor,
                  ),
                  Chip(
                    label: Text(
                      isPaid ? 'PAID' : 'UNPAID',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: paidColor,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Fee: ${fee.toStringAsFixed(2)} EGP',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              if (reason.isNotEmpty)
                Text(
                  reason,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              if (status == 'scheduled')
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Mark Completed'),
                    ],
                  ),
                ),
              if (status == 'scheduled')
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Cancel'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              final id = appointment['id'] as int;
              if (value == 'details') {
                _showAppointmentDetails(appointment);
              } else if (value == 'edit') {
                _showEditAppointmentDialog(appointment);
              } else if (value == 'complete') {
                await ApiService.updateAppointmentStatus(id, 'COMPLETED');
                await _loadAppointments();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment marked as completed'),
                  ),
                );
              } else if (value == 'cancel') {
                await ApiService.updateAppointmentStatus(id, 'CANCELLED');
                await _loadAppointments();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled')),
                );
              } else if (value == 'delete') {
                _confirmDelete('Delete Appointment', 'Are you sure?', () async {
                  await ApiService.deleteAppointment(id);
                  await _loadAppointments();
                });
              }
            },
          ),
        ),
      ),
    );
  }

  // ─── REPORT FLOW ──────────────────────────────────────────────────────────────

  void _showStartNewReportDialog(Map<String, dynamic> appointment) {
    final patientId =
        (appointment['patient_id'] ??
                (appointment['patient'] as Map?)?['id'] ??
                0)
            as int;
    final patientName = _appointmentPatientName(appointment);
    _loadReports(patientId: patientId);

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.person, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    patientName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue[700],
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientDetailsFromMap(appointment),
                const SizedBox(height: 20),
                const Divider(),
                _buildPreviousReportsSectionFromApi(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _createNewReport(appointment);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text(
                      'Start New Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientDetailsFromMap(Map<String, dynamic> appointment) {
    final name = _appointmentPatientName(appointment);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.blue[100]!]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.blue[700],
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousReportsSectionFromApi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text(
              'Previous Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_reports.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No previous reports found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ..._reports
              .take(3)
              .map(
                (r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[700],
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      r['created_at'] != null
                          ? DateFormat(
                              'dd/MM/yyyy',
                            ).format(DateTime.parse(r['created_at']))
                          : 'Report',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Diagnosis: ${r['ai_diagnosis'] ?? 'N/A'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  void _createNewReport(Map<String, dynamic> appointment) {
    String? audioPath;
    String? imagePath;
    String? imageAnalysis;
    bool isProcessing = false;
    bool isScanning = false;
    final patientName = _appointmentPatientName(appointment);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blue[700],
              iconTheme: const IconThemeData(color: Colors.white),
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: isProcessing || isScanning
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text('Cancel Recording?'),
                              ],
                            ),
                            content: const Text(
                              'Are you sure? Any recorded audio or scanned images will be lost.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Continue'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pop(context);
                                  _showStartNewReportDialog(appointment);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                      },
              ),
              title: const Row(
                children: [
                  Icon(Icons.mic, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Record Medical Report',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Patient Info
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[700],
                            child: Text(
                              patientName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Voice Recording
                  VoiceRecordingWidget(
                    onRecordingComplete: (path) {
                      audioPath = path;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Image Scanner Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medical_information,
                              color: Colors.purple[700],
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Medical Image Scan',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (imagePath != null) ...[
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(imagePath!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (imageAnalysis != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'AI Analysis Complete',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    imageAnalysis!,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                        // ── Gallery & Camera Buttons ──────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isScanning
                                    ? null
                                    : () async {
                                        final image = await AIService.pickImage(
                                          source: ImageSource.gallery,
                                        );
                                        if (image != null) {
                                          setDialogState(() {
                                            imagePath = image.path;
                                            isScanning = true;
                                            imageAnalysis = null;
                                          });
                                          try {
                                            final visitData =
                                                await ApiService.startVisit({
                                                  'appointment_id':
                                                      appointment['id'],
                                                  'chief_complaint': '',
                                                });
                                            final result =
                                                await ApiService.uploadMedicalImage(
                                                  imageFile: File(image.path),
                                                  visitId:
                                                      visitData['id'] as int,
                                                  imageType: 'xray',
                                                );
                                            setDialogState(
                                              () => imageAnalysis =
                                                  result['ai_analysis'] ??
                                                  'Analysis complete',
                                            );
                                          } catch (e) {
                                            setDialogState(
                                              () => imageAnalysis =
                                                  'Analysis failed: $e',
                                            );
                                          } finally {
                                            setDialogState(
                                              () => isScanning = false,
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[700],
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 52),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_library, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      'Gallery',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isScanning
                                    ? null
                                    : () async {
                                        final image = await AIService.pickImage(
                                          source: ImageSource.camera,
                                        );
                                        if (image != null) {
                                          setDialogState(() {
                                            imagePath = image.path;
                                            isScanning = true;
                                            imageAnalysis = null;
                                          });
                                          try {
                                            final visitData =
                                                await ApiService.startVisit({
                                                  'appointment_id':
                                                      appointment['id'],
                                                  'chief_complaint': '',
                                                });
                                            final result =
                                                await ApiService.uploadMedicalImage(
                                                  imageFile: File(image.path),
                                                  visitId:
                                                      visitData['id'] as int,
                                                  imageType: 'xray',
                                                );
                                            setDialogState(
                                              () => imageAnalysis =
                                                  result['ai_analysis'] ??
                                                  'Analysis complete',
                                            );
                                          } catch (e) {
                                            setDialogState(
                                              () => imageAnalysis =
                                                  'Analysis failed: $e',
                                            );
                                          } finally {
                                            setDialogState(
                                              () => isScanning = false,
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[700],
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 52),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      'Camera',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isScanning)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 8),
                                Text(
                                  'Analyzing image with AI...',
                                  style: TextStyle(
                                    color: Colors.purple[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (isProcessing) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            'Processing audio with AI...',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[700]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Record your medical report by voice. Optionally scan medical images for AI analysis.',
                            style: TextStyle(
                              color: Colors.amber[900],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: isProcessing || isScanning
                      ? null
                      : () async {
                          if (audioPath == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please record audio before saving',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isProcessing = true);
                          try {
                            final visit = await ApiService.startVisit({
                              'appointment_id': appointment['id'],
                              'chief_complaint': '',
                            });
                            final visitId = visit['id'] as int;
                            final result = await ApiService.transcribeAudio(
                              audioFile: File(audioPath!),
                              visitId: visitId,
                            );
                            if (result.isEmpty)
                              throw Exception('No data from AI');

                            final diagnosis =
                                result['diagnosis'] ?? 'غير مذكور';
                            final followUp = result['follow_up'] ?? 'غير مذكور';

                            String medications = '';
                            if (result['medications'] is List &&
                                (result['medications'] as List).isNotEmpty) {
                              for (var med in result['medications']) {
                                medications +=
                                    '${med['name'] ?? 'غير مذكور'}: ';
                                medications +=
                                    '${med['dose'] ?? 'غير مذكور'}, ';
                                medications +=
                                    '${med['frequency'] ?? 'غير مذكور'}, ';
                                medications +=
                                    '${med['duration'] ?? 'غير مذكور'}\n';
                                if ((med['notes'] ?? '').toString().isNotEmpty)
                                  medications += 'ملاحظات: ${med['notes']}\n';
                                medications += '\n';
                              }
                            } else {
                              medications = 'لا توجد أدوية';
                            }

                            String recommendations = '';
                            if (result['recommendations'] != null &&
                                (result['recommendations'] as List)
                                    .isNotEmpty) {
                              for (var rec in result['recommendations'])
                                recommendations += '• $rec\n';
                            } else {
                              recommendations = 'لا توجد توصيات';
                            }

                            setDialogState(() => isProcessing = false);
                            Navigator.pop(context);

                            _showReportPreviewDialog(
                              appointment: appointment,
                              patientName: patientName,
                              diagnosis: diagnosis,
                              symptoms: 'تم استخراجها تلقائياً',
                              treatment: recommendations,
                              prescriptions: medications,
                              doctorNotes: followUp,
                              aiSummary:
                                  'التشخيص: $diagnosis\n\nالمتابعة: $followUp',
                              audioPath: audioPath!,
                              imagePath: imagePath,
                              imageAnalysis: imageAnalysis,
                            );
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('AI processing failed: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          } finally {
                            if (mounted)
                              setDialogState(() => isProcessing = false);
                          }
                        },
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isProcessing ? 'Processing...' : 'Generate Report',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReportPreviewDialog({
    required Map<String, dynamic> appointment,
    required String patientName,
    required String diagnosis,
    required String symptoms,
    required String treatment,
    required String prescriptions,
    required String doctorNotes,
    required String aiSummary,
    required String audioPath,
    String? imagePath,
    String? imageAnalysis,
  }) {
    final diagnosisController = TextEditingController(text: diagnosis);
    final symptomsController = TextEditingController(text: symptoms);
    final treatmentController = TextEditingController(text: treatment);
    final prescriptionsController = TextEditingController(text: prescriptions);
    final notesController = TextEditingController(text: doctorNotes);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.preview, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Review & Edit Report',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue[700],
                          child: Text(
                            patientName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            patientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.green[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        aiSummary,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: diagnosisController,
                  decoration: InputDecoration(
                    labelText: 'Diagnosis',
                    prefixIcon: Icon(
                      Icons.medical_information,
                      color: Colors.blue[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: symptomsController,
                  decoration: InputDecoration(
                    labelText: 'Symptoms',
                    prefixIcon: Icon(Icons.sick, color: Colors.blue[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: treatmentController,
                  decoration: InputDecoration(
                    labelText: 'Treatment / Recommendations',
                    prefixIcon: Icon(Icons.healing, color: Colors.blue[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: prescriptionsController,
                  decoration: InputDecoration(
                    labelText: 'Prescriptions',
                    prefixIcon: Icon(Icons.medication, color: Colors.blue[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Doctor Notes / Follow-up',
                    prefixIcon: Icon(Icons.note_alt, color: Colors.blue[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await ApiService.createMedicalReport({
                  'ai_diagnosis': diagnosisController.text.trim(),
                  'ai_recommendations': [treatmentController.text.trim()],
                  'ai_follow_up': notesController.text.trim(),
                  'doctor_notes': notesController.text.trim(),
                  'symptoms': symptomsController.text.trim(),
                  'prescriptions': prescriptionsController.text.trim(),
                });
                await ApiService.updateAppointmentStatus(
                  appointment['id'] as int,
                  'COMPLETED',
                );
                await _loadAppointments();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report saved for $patientName'),
                    backgroundColor: Colors.blue[700],
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save report: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Generate Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PATIENTS PAGE ────────────────────────────────────────────────────────────

  Widget _buildPatients() {
    if (_isLoadingPatients)
      return const Center(child: CircularProgressIndicator());
    final patients = _getFilteredPatients();
    return RefreshIndicator(
      onRefresh: _loadPatients,
      color: Colors.blue[700],
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 60,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patients',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Clinic: ${_clinic.isEmpty ? "N/A" : _clinic}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddPatientDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _patientSearchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or national ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _patientSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            setState(() => _patientSearchController.clear()),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: patients.isEmpty
                  ? const Center(
                      child: Text(
                        'No patients added yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final p = patients[index];
                        final name =
                            '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
                                .trim();
                        final conditions = (p['conditions'] as List? ?? []);
                        final hasChronic = conditions.isNotEmpty;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            onTap: () => _showPatientDetailsDialog(p),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[700],
                              child: Text(
                                name.isEmpty
                                    ? '?'
                                    : name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text('ID: ${p['id']}'),
                                Text('Phone: ${p['phone'] ?? 'N/A'}'),
                                Text('Gender: ${p['gender'] ?? 'N/A'}'),
                                Text(
                                  'Chronic: ${hasChronic ? "Yes" : "No"}',
                                  style: TextStyle(
                                    color: hasChronic
                                        ? Colors.red
                                        : Colors.grey[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.grey),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete (Admin only)',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  _showEditPatientDialog(p);
                                } else if (value == 'delete') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Only admins can delete patients.',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPatientDetailsDialog(Map<String, dynamic> p) {
    final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    final conditions = (p['conditions'] as List? ?? []);
    final hasChronic =
        conditions.isNotEmpty ||
        (p['chronic_disease'] != null &&
            p['chronic_disease'].toString().trim().isNotEmpty);
    final chronicText = conditions.isNotEmpty
        ? conditions.map((c) => c['name'] ?? c.toString()).join(', ')
        : (p['chronic_disease'] ?? '');

    DateTime? birthDate;
    if (p['birth_date'] != null) {
      try {
        birthDate = DateTime.parse(p['birth_date'].toString());
      } catch (_) {}
    }
    String ageText = 'N/A';
    if (birthDate != null) {
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day))
        age--;
      ageText = '$age years';
    }

    _loadReports(patientId: p['id'] as int);
    final patientAppointments = _getAppointments()
        .where(
          (a) => (a['patient_id'] ?? (a['patient'] as Map?)?['id']) == p['id'],
        )
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.blue[700],
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Edit Patient',
                onPressed: () {
                  Navigator.pop(context);
                  _showEditPatientDialog(p);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: Text(
                          name.isEmpty
                              ? '?'
                              : name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient ID: ${p['id']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (hasChronic)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '⚠ Chronic Condition',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Personal Info ──
                _buildPatientDetailSection(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  color: Colors.blue[700]!,
                  rows: [
                    _patientInfoRow(
                      Icons.wc,
                      'Gender',
                      (p['gender'] ?? 'N/A').toString().toUpperCase(),
                    ),
                    _patientInfoRow(
                      Icons.cake_outlined,
                      'Date of Birth',
                      birthDate != null
                          ? DateFormat('dd MMM yyyy').format(birthDate)
                          : 'N/A',
                    ),
                    _patientInfoRow(Icons.access_time, 'Age', ageText),
                    _patientInfoRow(
                      Icons.badge_outlined,
                      'National ID',
                      p['national_id'] ?? 'N/A',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Contact Info ──
                _buildPatientDetailSection(
                  icon: Icons.contact_phone_outlined,
                  title: 'Contact Information',
                  color: Colors.green[700]!,
                  rows: [
                    _patientInfoRow(Icons.phone, 'Phone', p['phone'] ?? 'N/A'),
                    _patientInfoRow(
                      Icons.email_outlined,
                      'Email',
                      p['email'] ?? 'N/A',
                    ),
                    _patientInfoRow(
                      Icons.location_on_outlined,
                      'Address',
                      p['address'] ?? 'N/A',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Medical Info ──
                _buildPatientDetailSection(
                  icon: Icons.local_hospital_outlined,
                  title: 'Medical Information',
                  color: Colors.red[700]!,
                  rows: [
                    _patientInfoRow(
                      Icons.healing,
                      'Chronic Diseases',
                      hasChronic
                          ? (chronicText.isNotEmpty ? chronicText : 'Yes')
                          : 'None',
                      isWarning: hasChronic,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Previous Reports ──
                StatefulBuilder(
                  builder: (context, setS) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: Colors.teal[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Medical Reports',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.teal[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_reports.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  'No medical reports found',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            )
                          else
                            ..._reports.take(3).map((r) {
                              final date = r['created_at'] != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(DateTime.parse(r['created_at']))
                                  : 'N/A';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.teal[50],
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.teal[700],
                                    radius: 18,
                                    child: const Icon(
                                      Icons.description,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(
                                    date,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Diagnosis: ${r['ai_diagnosis'] ?? 'N/A'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── Appointment History ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.purple[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Appointment History',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.purple[700],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${patientAppointments.length} total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (patientAppointments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No appointments yet',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        )
                      else
                        ...patientAppointments.take(5).map((a) {
                          final dt = _parseDate(a['start_time']);
                          final status = (a['status'] ?? '')
                              .toString()
                              .toLowerCase();
                          final statusColor = status == 'completed'
                              ? Colors.green
                              : status == 'cancelled'
                              ? Colors.red
                              : Colors.blue;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    dt != null
                                        ? DateFormat(
                                            'dd MMM yyyy – hh:mm a',
                                          ).format(dt)
                                        : 'N/A',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: statusColor,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Action Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditPatientDialog(p);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Patient'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Only admins can delete patients.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientDetailSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...rows,
        ],
      ),
    );
  }

  Widget _patientInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isWarning ? Colors.red[700] : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isWarning ? Colors.red[700] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPatientDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final nationalIdController = TextEditingController();
    final addressController = TextEditingController();
    String selectedGender = 'male';
    DateTime? selectedBirthDate;
    final List<String> commonDiseases = [
      'Diabetes',
      'Hypertension',
      'Asthma',
      'Heart Disease',
      'Arthritis',
    ];
    final Set<String> selectedDiseases = {};
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Patient'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!v.trim().contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender *',
                          prefixIcon: Icon(Icons.wc),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedGender = v ?? 'male'),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                selectedBirthDate ?? DateTime(2000, 1, 1),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            helpText: 'Select Date of Birth',
                          );
                          if (picked != null)
                            setDialogState(() => selectedBirthDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedBirthDate != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(selectedBirthDate!)
                                    : 'Tap to select',
                                style: TextStyle(
                                  color: selectedBirthDate != null
                                      ? null
                                      : Colors.grey[600],
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nationalIdController,
                        decoration: const InputDecoration(
                          labelText: 'National ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chronic Diseases',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: commonDiseases.map((disease) {
                            return CheckboxListTile(
                              dense: true,
                              title: Text(
                                disease,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: selectedDiseases.contains(disease),
                              activeColor: Colors.red[700],
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selectedDiseases.add(disease);
                                  } else {
                                    selectedDiseases.remove(disease);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    final patientData = <String, dynamic>{
                      'first_name': firstNameController.text.trim(),
                      'last_name': lastNameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'gender': selectedGender,
                      'national_id': nationalIdController.text.trim(),
                      'address': addressController.text.trim(),
                    };
                    if (emailController.text.trim().isNotEmpty) {
                      patientData['email'] = emailController.text.trim();
                    }
                    if (selectedBirthDate != null) {
                      patientData['birth_date'] = DateFormat(
                        'yyyy-MM-dd',
                      ).format(selectedBirthDate!);
                    }
                    if (selectedDiseases.isNotEmpty) {
                      patientData['chronic_disease'] = selectedDiseases.join(
                        ', ',
                      );
                    }
                    await ApiService.createPatient(patientData);
                    await _loadPatients();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Patient added successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditPatientDialog(Map<String, dynamic> patient) {
    final firstNameController = TextEditingController(
      text: patient['first_name'] ?? '',
    );
    final lastNameController = TextEditingController(
      text: patient['last_name'] ?? '',
    );
    final phoneController = TextEditingController(text: patient['phone'] ?? '');
    final emailController = TextEditingController(text: patient['email'] ?? '');
    final nationalIdController = TextEditingController(
      text: patient['national_id'] ?? '',
    );
    final addressController = TextEditingController(
      text: patient['address'] ?? '',
    );
    String selectedGender = patient['gender'] ?? 'male';
    DateTime? selectedBirthDate;
    if (patient['birth_date'] != null) {
      try {
        selectedBirthDate = DateTime.parse(patient['birth_date'].toString());
      } catch (_) {}
    }
    final List<String> commonDiseases = [
      'Diabetes',
      'Hypertension',
      'Asthma',
      'Heart Disease',
      'Arthritis',
    ];
    final existingDiseases = (patient['chronic_disease'] ?? '').toString();
    final Set<String> selectedDiseases = commonDiseases
        .where((d) => existingDiseases.toLowerCase().contains(d.toLowerCase()))
        .toSet();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Patient'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!v.trim().contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender *',
                          prefixIcon: Icon(Icons.wc),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedGender = v ?? 'male'),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                selectedBirthDate ?? DateTime(2000, 1, 1),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            helpText: 'Select Date of Birth',
                          );
                          if (picked != null)
                            setDialogState(() => selectedBirthDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedBirthDate != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(selectedBirthDate!)
                                    : 'Tap to select',
                                style: TextStyle(
                                  color: selectedBirthDate != null
                                      ? null
                                      : Colors.grey[600],
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nationalIdController,
                        decoration: const InputDecoration(
                          labelText: 'National ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chronic Diseases',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: commonDiseases.map((disease) {
                            return CheckboxListTile(
                              dense: true,
                              title: Text(
                                disease,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: selectedDiseases.contains(disease),
                              activeColor: Colors.red[700],
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selectedDiseases.add(disease);
                                  } else {
                                    selectedDiseases.remove(disease);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    final patientData = <String, dynamic>{
                      'first_name': firstNameController.text.trim(),
                      'last_name': lastNameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'gender': selectedGender,
                      'national_id': nationalIdController.text.trim(),
                      'address': addressController.text.trim(),
                    };
                    if (emailController.text.trim().isNotEmpty) {
                      patientData['email'] = emailController.text.trim();
                    }
                    if (selectedBirthDate != null) {
                      patientData['birth_date'] = DateFormat(
                        'yyyy-MM-dd',
                      ).format(selectedBirthDate!);
                    }
                    patientData['chronic_disease'] = selectedDiseases.isNotEmpty
                        ? selectedDiseases.join(', ')
                        : '';
                    await ApiService.updatePatient(
                      patient['id'] as int,
                      patientData,
                    );
                    await _loadPatients();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Patient updated successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── APPOINTMENTS DIALOGS ─────────────────────────────────────────────────────

  void _showCreateAppointmentDialog() async {
    await _loadPatients();

    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No patients available. Please add patients first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final outerContext = context;

    Map<String, dynamic>? selectedPatient;
    String selectedFeeType = 'consultation';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final reasonController = TextEditingController();
    final feeController = TextEditingController(text: '300');
    bool isPaid = false;
    bool isUrgent = false;
    bool submitting = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: outerContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Appointment'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final selected = await _showPatientSearchDialog();
                      if (selected != null)
                        setDialogState(() => selectedPatient = selected);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Select Patient *',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedPatient != null
                                  ? _patientName(selectedPatient!)
                                  : 'Tap to search patient',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(Icons.search, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_appointmentTypes.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedFeeType,
                      decoration: const InputDecoration(
                        labelText: 'Appointment Type',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'consultation',
                          child: Text('Consultation — 300 EGP'),
                        ),
                        DropdownMenuItem(
                          value: 'visit',
                          child: Text('Visit — 100 EGP'),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() {
                        selectedFeeType = v ?? 'consultation';
                        feeController.text = selectedFeeType == 'consultation'
                            ? '300'
                            : '100';
                      }),
                    ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                    ),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null)
                        setDialogState(() => selectedDate = date);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Time'),
                    subtitle: Text(selectedTime.format(context)),
                    leading: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null)
                        setDialogState(() => selectedTime = time);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: feeController,
                    decoration: const InputDecoration(
                      labelText: 'Fee (EGP)',
                      prefixIcon: Icon(Icons.payments_outlined),
                      helperText: 'Auto-filled from appointment type',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (double.tryParse(v.trim()) == null)
                        return 'Invalid fee';
                      return null;
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isPaid,
                    title: const Text('Paid?'),
                    onChanged: (v) => setDialogState(() => isPaid = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isUrgent,
                    title: const Text('Urgent?'),
                    onChanged: (v) => setDialogState(() => isUrgent = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason / Notes',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (selectedPatient == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a patient'),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        final dt = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        final rawReason = reasonController.text.trim();
                        final finalReason = _applyUrgentPrefix(
                          rawReason,
                          isUrgent,
                        );
                        await ApiService.createAppointment({
                          'patient_id': selectedPatient!['id'],
                          'doctor_id': widget.doctorProfile.id,
                          'start_time': _toIso8601WithTz(dt),
                          'reason': finalReason,
                          'is_urgent': isUrgent,
                          'is_paid': isPaid,
                          'fee':
                              double.tryParse(feeController.text.trim()) ?? 0.0,
                        });
                        if (mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(outerContext).showSnackBar(
                          const SnackBar(
                            content: Text('Appointment created successfully'),
                          ),
                        );
                        await _loadAppointments();
                      } catch (e) {
                        if (mounted) setDialogState(() => submitting = false);
                        ScaffoldMessenger.of(outerContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed: ${ApiService.extractError(e)}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  String _appointmentPatientName(Map<String, dynamic> a) {
    if (a['patient_name'] != null && a['patient_name'].toString().isNotEmpty) {
      return a['patient_name'].toString();
    }
    final patient = a['patient'] as Map<String, dynamic>? ?? {};
    final first = patient['first_name'] ?? '';
    final last = patient['last_name'] ?? '';
    return '$first $last'.trim().isEmpty ? 'Unknown' : '$first $last'.trim();
  }

  String _patientName(Map<String, dynamic> p) =>
      '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();

  Future<Map<String, dynamic>?> _showPatientSearchDialog() async {
    await _loadPatients();
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredPatients = _getPatients();

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Search Patient'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, or national ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    final query = value.toLowerCase().trim();
                    setDialogState(() {
                      filteredPatients = query.isEmpty
                          ? _getPatients()
                          : _getPatients().where((p) {
                              final name =
                                  '${p['first_name']} ${p['last_name']}'
                                      .toLowerCase();
                              final phone = (p['phone'] ?? '').toLowerCase();
                              final nid = (p['national_id'] ?? '')
                                  .toLowerCase();
                              return name.contains(query) ||
                                  phone.contains(query) ||
                                  nid.contains(query);
                            }).toList();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '${filteredPatients.length} patient(s) found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filteredPatients.isEmpty
                      ? const Center(
                          child: Text(
                            'No patients found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredPatients.length,
                          itemBuilder: (context, index) {
                            final p = filteredPatients[index];
                            final name = '${p['first_name']} ${p['last_name']}'
                                .trim();
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[700],
                                  child: Text(
                                    name.isEmpty
                                        ? '?'
                                        : name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('Phone: ${p['phone'] ?? 'N/A'}'),
                                onTap: () => Navigator.pop(context, p),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAppointmentDialog(Map<String, dynamic> appointment) {
    final dateTime = DateTime.parse(appointment['start_time']);
    DateTime selectedDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(dateTime);
    final isUrgentNow = _isUrgentAppointment(appointment);
    final cleanReason = _applyUrgentPrefix(appointment['reason'] ?? '', false);
    final reasonController = TextEditingController(text: cleanReason);
    final feeController = TextEditingController(
      text: (appointment['fee'] ?? 0).toString(),
    );
    bool isPaid = appointment['is_paid'] == true;
    bool isUrgent = isUrgentNow;
    final formKey = GlobalKey<FormState>();
    final outerContext = context;

    showDialog(
      context: outerContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Appointment'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                      ),
                      leading: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null)
                          setDialogState(() => selectedDate = date);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Time'),
                      subtitle: Text(selectedTime.format(context)),
                      leading: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null)
                          setDialogState(() => selectedTime = time);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: feeController,
                      decoration: const InputDecoration(
                        labelText: 'Fee (EGP)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isPaid,
                      title: const Text('Paid?'),
                      onChanged: (v) => setDialogState(() => isPaid = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isUrgent,
                      title: const Text('Urgent?'),
                      onChanged: (v) => setDialogState(() => isUrgent = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason / Notes',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                final fee = double.tryParse(feeController.text.trim()) ?? 0.0;
                final finalReason = _applyUrgentPrefix(
                  reasonController.text.trim(),
                  isUrgent,
                );
                try {
                  await ApiService.updateAppointment(appointment['id'] as int, {
                    'start_time': _toIso8601WithTz(updatedDateTime),
                    'reason': finalReason,
                    'is_urgent': isUrgent,
                    'is_paid': isPaid,
                    'fee': fee,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment updated successfully'),
                    ),
                  );
                  await _loadAppointments();
                } catch (e) {
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    final dateTime = DateTime.parse(appointment['start_time']);
    final isPaid = appointment['is_paid'] == true;
    final fee = double.tryParse((appointment['fee'] ?? 0).toString()) ?? 0.0;
    final status = appointment['status'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue),
            SizedBox(width: 8),
            Text('Appointment Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Name',
                      _appointmentPatientName(appointment),
                    ),
                    _buildDetailRow(
                      'Patient ID',
                      '${appointment['patient_id'] ?? (appointment['patient'] as Map?)?['id'] ?? 'N/A'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    _buildDetailRow('Appointment ID', '${appointment['id']}'),
                    _buildDetailRow(
                      'Date & Time',
                      DateFormat('dd/MM/yyyy - hh:mm a').format(dateTime),
                    ),
                    _buildDetailRow('Status', status.toUpperCase()),
                    if ((appointment['reason'] ?? '').isNotEmpty)
                      _buildDetailRow('Reason', appointment['reason']),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPaid ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPaid ? Icons.check_circle : Icons.pending,
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildDetailRow('Fee', '${fee.toStringAsFixed(2)} EGP'),
                    _buildDetailRow(
                      'Payment Status',
                      isPaid ? 'PAID' : 'UNPAID',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─── PAYMENTS PAGE ────────────────────────────────────────────────────────────

  Widget _buildPaymentsPage() {
    final stats = _doctorPaymentStats();
    final total = stats['total']!;
    final paid = stats['paid']!;
    final unpaid = stats['unpaid']!;
    final appointments = _getAppointments();

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: Colors.blue[700],
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 60,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payments',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Clinic: ${_clinic.isEmpty ? "N/A" : _clinic}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: Colors.blue,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${total.toStringAsFixed(2)} EGP',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Paid',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${paid.toStringAsFixed(2)} EGP',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.pending, color: Colors.red, size: 36),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unpaid',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${unpaid.toStringAsFixed(2)} EGP',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: appointments.isEmpty
                  ? Center(
                      child: Text(
                        'No payment history',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: appointments.map((a) {
                        final isPaid = a['is_paid'] == true;
                        final fee =
                            double.tryParse((a['fee'] ?? 0).toString()) ?? 0.0;
                        final dt = DateTime.parse(a['start_time']);
                        return ListTile(
                          leading: Icon(
                            isPaid ? Icons.check_circle : Icons.pending,
                            color: isPaid ? Colors.green : Colors.orange,
                          ),
                          title: Text(_appointmentPatientName(a)),
                          subtitle: Text(
                            '${DateFormat('dd/MM/yyyy - hh:mm a').format(dt)} • Fee: ${fee.toStringAsFixed(2)} EGP',
                          ),
                          trailing: Chip(
                            label: Text(
                              isPaid ? 'PAID' : 'UNPAID',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            backgroundColor: isPaid
                                ? Colors.green
                                : Colors.orange,
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SHARED HELPERS ───────────────────────────────────────────────────────────

  void _confirmDelete(
    String title,
    String message,
    Future<void> Function() onConfirm,
  ) {
    final scaffoldContext = context;

    showDialog(
      context: scaffoldContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // close dialog first
              try {
                await onConfirm();
                if (mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    const SnackBar(content: Text('Deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isWarning ? Colors.red : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isWarning ? Colors.red : null,
                fontWeight: isWarning ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(dynamic v) {
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
}
