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
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _reports = [];
  bool _isLoadingPatients = false;
  bool _isLoadingAppointments = false;

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
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoadingPatients = true);
    try {
      final doctorId = int.tryParse(widget.doctorProfile.id);
      final data = await ApiService.getPatients(doctorId: doctorId);
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
    setState(() => _isLoadingAppointments = true);
    try {
      final doctorId = int.tryParse(widget.doctorProfile.id);
      final data = await ApiService.getAppointments(doctorId: doctorId);
      setState(() => _appointments = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      setState(() => _isLoadingAppointments = false);
    }
  }

  Future<void> _loadReports({required int patientId}) async {
    try {
      final data = await ApiService.getMedicalReports(patientId: patientId);
      setState(() => _reports = List<Map<String, dynamic>>.from(data));
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
    list.sort(
      (a, b) => DateTime.parse(
        a['start_time'],
      ).compareTo(DateTime.parse(b['start_time'])),
    );
    return list;
  }

  List<Map<String, dynamic>> _getFilteredAppointments() {
    final query = _appointmentSearchController.text.toLowerCase().trim();
    if (query.isEmpty) return _getAppointments();
    return _getAppointments().where((a) {
      final name = (a['patient_name'] ?? '').toLowerCase();
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
    return DateTime.parse(
      a['start_time'],
    ).compareTo(DateTime.parse(b['start_time']));
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
      final fee = (a['fee'] ?? 0).toDouble();
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadPatients();
              _loadAppointments();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Notifications'))),
          ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doctor Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Clinic: ${_clinic.isEmpty ? "N/A" : _clinic}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[700],
                    child: Text(
                      widget.doctorProfile.fullName
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.doctorProfile.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.doctorProfile.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const Divider(height: 32),
                  _buildProfileRow('Username', widget.doctorProfile.username),
                  _buildProfileRow('Gender', widget.doctorProfile.gender),
                  _buildProfileRow(
                    'Clinic',
                    widget.doctorProfile.clinicName ?? 'N/A',
                  ),
                  _buildProfileRow(
                    'License',
                    widget.doctorProfile.licenseNumber ?? 'N/A',
                  ),
                  if (widget.doctorProfile.birthDate != null)
                    _buildProfileRow(
                      'Birth Date',
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(widget.doctorProfile.birthDate!),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
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
      final dt = DateTime.parse(a['start_time']);
      return dt.isAfter(today) && dt.isBefore(tomorrow);
    }).toList()..sort(_queueSort);

    final upcomingAppointments = appointments.where((a) {
      return DateTime.parse(a['start_time']).isAfter(tomorrow);
    }).toList()..sort(_queueSort);

    final nextUp = todayAppointments
        .where((a) => (a['status'] ?? '').toLowerCase() == 'scheduled')
        .toList();
    final firstUp = nextUp.isNotEmpty ? nextUp.first : null;

    return ListView(
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        if (todayAppointments.isEmpty && upcomingAppointments.isEmpty)
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
    final patientName = appointment['patient_name'] ?? 'Unknown';
    final dateTime = DateTime.parse(appointment['start_time']);
    final reason = appointment['reason'] ?? '';
    final fee = (appointment['fee'] ?? 0).toDouble();

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
    final patientId = appointment['patient_id'] as int;
    final patientName = appointment['patient_name'] ?? 'Unknown';
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
    final name = appointment['patient_name'] ?? 'Unknown';
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
    final patientName = appointment['patient_name'] ?? 'Unknown';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mic, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Record Medical Report',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
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
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
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
                                          // Upload to backend
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
                                            setDialogState(() {
                                              imageAnalysis =
                                                  result['ai_analysis'] ??
                                                  'Analysis complete';
                                            });
                                          } catch (e) {
                                            setDialogState(() {
                                              imageAnalysis =
                                                  'Analysis failed: $e';
                                            });
                                          } finally {
                                            setDialogState(
                                              () => isScanning = false,
                                            );
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Gallery'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[700],
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 48),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
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
                                            setDialogState(() {
                                              imageAnalysis =
                                                  result['ai_analysis'] ??
                                                  'Analysis complete';
                                            });
                                          } catch (e) {
                                            setDialogState(() {
                                              imageAnalysis =
                                                  'Analysis failed: $e';
                                            });
                                          } finally {
                                            setDialogState(
                                              () => isScanning = false,
                                            );
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Camera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[700],
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 48),
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
          ),
          actions: [
            TextButton(
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
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isProcessing || isScanning
                  ? null
                  : () async {
                      if (audioPath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please record audio before saving'),
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
                        if (result.isEmpty) throw Exception('No data from AI');

                        final diagnosis = result['diagnosis'] ?? 'غير مذكور';
                        final followUp = result['follow_up'] ?? 'غير مذكور';

                        String medications = '';
                        if (result['medications'] is List &&
                            (result['medications'] as List).isNotEmpty) {
                          for (var med in result['medications']) {
                            medications += '${med['name'] ?? 'غير مذكور'}: ';
                            medications += '${med['dose'] ?? 'غير مذكور'}, ';
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
                            (result['recommendations'] as List).isNotEmpty) {
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
                        if (mounted) setDialogState(() => isProcessing = false);
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
              label: Text(isProcessing ? 'Processing...' : 'Save Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
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
          // ── Save only (no WhatsApp) ──
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
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
          // ── Save + Send WhatsApp ──
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

                // Get patient phone from _patients list
                final patientData = _patients.firstWhere(
                  (p) => p['id'] == appointment['patient_id'],
                  orElse: () => {},
                );
                final phone = patientData['phone'] ?? '';

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report saved for $patientName ✅'),
                    backgroundColor: Colors.green[700],
                  ),
                );

                await _loadAppointments();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      phone.isNotEmpty
                          ? 'Report saved & sent to $patientName via WhatsApp ✅'
                          : 'Report saved (no phone number found)',
                    ),
                    backgroundColor: Colors.green[700],
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
            icon: const Icon(Icons.send),
            label: const Text('Save & Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
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
    return Padding(
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showEditPatientDialog(p);
                              } else if (value == 'delete') {
                                _confirmDelete(
                                  'Delete Patient',
                                  'Delete $name?',
                                  () async {
                                    await ApiService.deletePatient(
                                      p['id'] as int,
                                    );
                                    await _loadPatients();
                                  },
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
    );
  }

  void _showAddPatientDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final nationalIdController = TextEditingController();
    final addressController = TextEditingController();
    String selectedGender = 'male';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Patient'),
          content: SingleChildScrollView(
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
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender *',
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedGender = v ?? 'male'),
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ApiService.createPatient({
                    'first_name': firstNameController.text.trim(),
                    'last_name': lastNameController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'gender': selectedGender,
                    'national_id': nationalIdController.text.trim(),
                    'address': addressController.text.trim(),
                  });
                  await _loadPatients();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Patient added successfully')),
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
        ),
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
    final nationalIdController = TextEditingController(
      text: patient['national_id'] ?? '',
    );
    final addressController = TextEditingController(
      text: patient['address'] ?? '',
    );
    String selectedGender = patient['gender'] ?? 'male';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  await ApiService.updatePatient(patient['id'] as int, {
                    'first_name': firstNameController.text.trim(),
                    'last_name': lastNameController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'gender': selectedGender,
                    'national_id': nationalIdController.text.trim(),
                    'address': addressController.text.trim(),
                  });
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
        ),
      ),
    );
  }

  // ─── APPOINTMENTS DIALOGS ─────────────────────────────────────────────────────

  void _showCreateAppointmentDialog() {
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No patients available. Please add patients first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Map<String, dynamic>? selectedPatient;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final reasonController = TextEditingController();
    final feeController = TextEditingController(text: '200');
    bool isPaid = false;
    bool isUrgent = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
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
                      if (selected != null) {
                        setDialogState(() => selectedPatient = selected);
                      }
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
                                  ? '${selectedPatient!['first_name']} ${selectedPatient!['last_name']}'
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
                  ListTile(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedPatient == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a patient')),
                  );
                  return;
                }
                final dateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                final fee = double.tryParse(feeController.text.trim()) ?? 0.0;
                final rawReason = reasonController.text.trim();
                final finalReason = _applyUrgentPrefix(rawReason, isUrgent);
                try {
                  await ApiService.createAppointment({
                    'patient_id': selectedPatient!['id'],
                    'doctor_id': int.tryParse(widget.doctorProfile.id),
                    'start_time': dateTime.toIso8601String(),
                    'reason': finalReason,
                    'is_urgent': isUrgent,
                    'is_paid': isPaid,
                    'fee': fee,
                  });
                  await _loadAppointments();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment created successfully'),
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showPatientSearchDialog() async {
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

    showDialog(
      context: context,
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
                    'start_time': updatedDateTime.toIso8601String(),
                    'reason': finalReason,
                    'is_urgent': isUrgent,
                    'is_paid': isPaid,
                    'fee': fee,
                  });
                  await _loadAppointments();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment updated successfully'),
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
        ),
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    final dateTime = DateTime.parse(appointment['start_time']);
    final isPaid = appointment['is_paid'] == true;
    final fee = (appointment['fee'] ?? 0).toDouble();
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
                      appointment['patient_name'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Patient ID',
                      '${appointment['patient_id']}',
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

    return Padding(
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
                    children: appointments.map((a) {
                      final isPaid = a['is_paid'] == true;
                      final fee = (a['fee'] ?? 0).toDouble();
                      final dt = DateTime.parse(a['start_time']);
                      return ListTile(
                        leading: Icon(
                          isPaid ? Icons.check_circle : Icons.pending,
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                        title: Text(a['patient_name'] ?? 'Unknown'),
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
    );
  }

  // ─── SHARED HELPERS ───────────────────────────────────────────────────────────

  void _confirmDelete(
    String title,
    String message,
    Future<void> Function() onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await onConfirm();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
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
}
