import 'package:flutter/material.dart';
import 'package:Hakim/Login%20Page.dart';
import 'package:Hakim/UserProfile.dart';
import 'package:Hakim/api_service.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

class AssistantInterface extends StatefulWidget {
  final UserProfile assistantProfile;

  const AssistantInterface({Key? key, required this.assistantProfile})
    : super(key: key);

  @override
  State<AssistantInterface> createState() => _AssistantInterfaceState();
}

class _AssistantInterfaceState extends State<AssistantInterface> {
  int _selectedIndex = 1;

  // ── Data Lists ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _appointmentTypes = [];
  List<Map<String, dynamic>> _doctors = [];

  // ── Loading / Error ─────────────────────────────────────────────────────────
  bool _loadingPatients = false;
  bool _loadingAppointments = false;
  bool _patientsError = false;
  bool _appointmentsError = false;

  // ── Search ───────────────────────────────────────────────────────────────────
  final TextEditingController _patientSearchController =
      TextEditingController();
  final TextEditingController _appointmentSearchController =
      TextEditingController();

  String get _clinic => widget.assistantProfile.clinicName ?? '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    _appointmentSearchController.dispose();
    super.dispose();
  }

  // ── Data Fetchers ────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    await Future.wait([
      _fetchPatients(),
      _fetchAppointments(),
      _fetchAppointmentTypes(),
      _fetchDoctors(),
    ]);
  }

  Future<void> _fetchPatients({String search = ''}) async {
    if (!mounted) return;
    setState(() {
      _loadingPatients = true;
      _patientsError = false;
    });
    try {
      final data = await ApiService.getPatients(search: search);
      if (mounted) {
        setState(() {
          _patients = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _patientsError = true);
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
        setState(() {
          _appointments = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _appointmentsError = true);
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  Future<void> _fetchAppointmentTypes() async {
    try {
      final data = await ApiService.getAppointmentTypes();
      if (mounted) {
        setState(() {
          _appointmentTypes = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchDoctors() async {
    try {
      final data = await ApiService.getDoctors();
      if (mounted) {
        setState(() {
          _doctors = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  // ── Filtered Lists ───────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredPatients {
    final q = _patientSearchController.text.toLowerCase().trim();
    if (q.isEmpty) return _patients;
    return _patients.where((p) {
      final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
          .toLowerCase();
      final phone = (p['phone'] ?? '').toString().toLowerCase();
      final nid = (p['national_id'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || nid.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    final q = _appointmentSearchController.text.toLowerCase().trim();
    if (q.isEmpty) return _appointments;
    return _appointments.where((a) {
      final patient = a['patient'] as Map<String, dynamic>? ?? {};
      final name =
          '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'
              .toLowerCase();
      final phone = (patient['phone'] ?? '').toString().toLowerCase();
      final nid = (patient['national_id'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || nid.contains(q);
    }).toList();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _patientName(Map<String, dynamic> p) =>
      '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();

  String _appointmentPatientName(Map<String, dynamic> a) {
    final patient = a['patient'] as Map<String, dynamic>? ?? {};
    return _patientName(patient);
  }

  bool _isUrgent(Map<String, dynamic> a) => a['is_urgent'] == true;

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
      case 'NO_SHOW':
        return Colors.red;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  Map<String, double> _getPaymentStats() {
    double total = 0, paid = 0;
    for (final a in _appointments) {
      if ((a['status'] ?? '').toUpperCase() == 'CANCELLED') continue;
      final fee = (a['fee'] ?? 0).toDouble();
      total += fee;
      if (a['is_paid'] == true) paid += fee;
    }
    return {'total': total, 'paid': paid, 'unpaid': total - paid};
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildAssistantProfile();
      case 1:
        return _buildAppointments();
      case 2:
        return _buildPatients();
      case 3:
        return _buildPaymentStatus();
      default:
        return _buildAppointments();
    }
  }

  // ── Shell ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assistant Dashboard',
          style: TextStyle(
            fontSize: 21,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ApiService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.green[700]),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.assistantProfile.fullName.isNotEmpty
                      ? widget.assistantProfile.fullName
                            .substring(0, 1)
                            .toUpperCase()
                      : 'A',
                  style: TextStyle(fontSize: 32, color: Colors.green[700]),
                ),
              ),
              accountName: Text(
                widget.assistantProfile.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(widget.assistantProfile.email),
            ),
            _drawerItem(Icons.person, 'Assistant Profile', 0),
            _drawerItem(Icons.calendar_today, 'Appointments', 1),
            _drawerItem(Icons.people, 'Patients', 2),
            _drawerItem(Icons.payment, 'Payment Status', 3),
          ],
        ),
      ),
      body: _getSelectedPage(),
    );
  }

  ListTile _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PROFILE PAGE
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildAssistantProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assistant Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green[700],
                    child: Text(
                      widget.assistantProfile.fullName.isNotEmpty
                          ? widget.assistantProfile.fullName
                                .substring(0, 1)
                                .toUpperCase()
                          : 'A',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.assistantProfile.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.assistantProfile.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const Divider(height: 32),
                  _profileRow('User Type', widget.assistantProfile.userType),
                  _profileRow('Clinic', _clinic.isEmpty ? 'N/A' : _clinic),
                  _profileRow('Gender', widget.assistantProfile.gender),
                  if (widget.assistantProfile.birthDate != null)
                    _profileRow(
                      'Birth Date',
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(widget.assistantProfile.birthDate!),
                    ),
                  _profileRow(
                    'Joined',
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(widget.assistantProfile.createdAt),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
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

  // ─────────────────────────────────────────────────────────────────────────────
  // APPOINTMENTS PAGE
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildAppointments() {
    if (_loadingAppointments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_appointmentsError) {
      return _errorWidget('Failed to load appointments', _fetchAppointments);
    }

    final all = _filteredAppointments;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    List<Map<String, dynamic>> todayList = [];
    List<Map<String, dynamic>> upcomingList = [];
    List<Map<String, dynamic>> pastList = [];

    for (final a in all) {
      final dt = _parseDate(a['start_time']);
      if (dt == null) continue;
      if (dt.isAfter(today) && dt.isBefore(tomorrow)) {
        todayList.add(a);
      } else if (dt.isAfter(tomorrow)) {
        upcomingList.add(a);
      } else {
        pastList.add(a);
      }
    }

    // Sort: urgent first, then time
    int queueSort(Map<String, dynamic> a, Map<String, dynamic> b) {
      final au = _isUrgent(a);
      final bu = _isUrgent(b);
      if (au != bu) return au ? -1 : 1;
      final da = _parseDate(a['start_time']) ?? DateTime.now();
      final db = _parseDate(b['start_time']) ?? DateTime.now();
      return da.compareTo(db);
    }

    todayList.sort(queueSort);
    upcomingList.sort(queueSort);

    final nextUp = todayList
        .where(
          (a) =>
              (a['status'] ?? '').toUpperCase() == 'SCHEDULED' ||
              (a['status'] ?? '').toUpperCase() == 'CONFIRMED',
        )
        .toList();
    final serving = nextUp.isNotEmpty ? nextUp.first : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointments',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search Bar
            TextField(
              controller: _appointmentSearchController,
              decoration: InputDecoration(
                hintText: 'Search by patient name, phone, or national ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _appointmentSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(
                          () => _appointmentSearchController.clear(),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // List
            Expanded(
              child: all.isEmpty
                  ? const Center(
                      child: Text(
                        'No appointments scheduled',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAppointments,
                      child: ListView(
                        children: [
                          if (serving != null) ...[
                            const Text(
                              'Now Serving',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildAppointmentCard(serving, highlight: true),
                            const SizedBox(height: 16),
                          ],
                          if (todayList.isNotEmpty) ...[
                            const Text(
                              "Today's Appointments",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...todayList.map(_buildAppointmentCard),
                            const SizedBox(height: 16),
                          ],
                          if (upcomingList.isNotEmpty) ...[
                            const Text(
                              'Upcoming Appointments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...upcomingList.map(_buildAppointmentCard),
                          ],
                          if (pastList.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Past Appointments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...pastList.map(_buildAppointmentCard),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment, {
    bool highlight = false,
  }) {
    final status = (appointment['status'] ?? 'SCHEDULED').toString();
    final statusColor = _statusColor(status);
    final isPaid = appointment['is_paid'] == true;
    final urgent = _isUrgent(appointment);
    final paidChipColor = isPaid ? Colors.green : Colors.orange;
    final patientName = _appointmentPatientName(appointment);
    final dt = _parseDate(appointment['start_time']);
    final fee = (appointment['fee'] ?? 0).toDouble();
    final reason = appointment['reason'] ?? '';
    final apptType =
        (appointment['appointment_type'] as Map<String, dynamic>?)?['name'] ??
        '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: highlight ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlight
            ? BorderSide(color: Colors.green.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        isThreeLine: true,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: urgent ? Colors.red : statusColor,
          child: Icon(
            status.toUpperCase() == 'COMPLETED'
                ? Icons.check
                : Icons.calendar_today,
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
            const SizedBox(height: 4),
            if (dt != null) Text(DateFormat('dd/MM/yyyy - hh:mm a').format(dt)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: statusColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(
                    isPaid ? 'PAID' : 'UNPAID',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: paidChipColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                if (apptType.isNotEmpty)
                  Chip(
                    label: Text(
                      apptType,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: Colors.indigo,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
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
        trailing: const Icon(Icons.more_vert),
        onTap: () => _showAppointmentOptions(appointment),
      ),
    );
  }

  void _showAppointmentOptions(Map<String, dynamic> appointment) {
    final status = (appointment['status'] ?? '').toUpperCase();
    final id = appointment['id'] as int;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Appointment'),
              onTap: () {
                Navigator.pop(context);
                _showEditAppointmentDialog(appointment);
              },
            ),
            if (status == 'SCHEDULED' || status == 'CONFIRMED')
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Completed'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateAppointmentStatus(id, 'COMPLETED');
                },
              ),
            if (status == 'SCHEDULED')
              ListTile(
                leading: const Icon(Icons.lock_clock, color: Colors.teal),
                title: const Text('Confirm Appointment'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateAppointmentStatus(id, 'CONFIRMED');
                },
              ),
            if (status != 'CANCELLED' && status != 'COMPLETED')
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.orange),
                title: const Text('Cancel Appointment'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateAppointmentStatus(id, 'CANCELLED');
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAppointmentStatus(int id, String status) async {
    try {
      await ApiService.updateAppointmentStatus(id, status);
      _showSnack('Status updated to $status', Colors.green);
      await _fetchAppointments();
    } catch (e) {
      _showSnack('Failed to update status', Colors.red);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PATIENTS PAGE
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildPatients() {
    if (_loadingPatients) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_patientsError) {
      return _errorWidget('Failed to load patients', _fetchPatients);
    }

    final patients = _filteredPatients;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  const SizedBox(height: 4),
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
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search
          TextField(
            controller: _patientSearchController,
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or national ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _patientSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _patientSearchController.clear());
                        _fetchPatients();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) {
              setState(() {});
              // also hit API for server-side search
              if (v.length >= 2 || v.isEmpty) _fetchPatients(search: v);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: patients.isEmpty
                ? const Center(
                    child: Text(
                      'No patients found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchPatients,
                    child: ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        final name = _patientName(patient);
                        final conditions =
                            (patient['conditions'] as List? ?? [])
                                .map(
                                  (c) =>
                                      (c['condition'] as Map? ?? {})['name']
                                          ?.toString() ??
                                      '',
                                )
                                .where((s) => s.isNotEmpty)
                                .join(', ');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[700],
                              child: Text(
                                name.isNotEmpty
                                    ? name.substring(0, 1).toUpperCase()
                                    : '?',
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
                                const SizedBox(height: 4),
                                Text('ID: ${patient['id']}'),
                                Text(
                                  'Phone: ${patient['phone'] ?? patient['email'] ?? 'N/A'}',
                                ),
                                Text(
                                  'DOB: ${patient['date_of_birth'] ?? 'N/A'} | Gender: ${patient['gender'] ?? 'N/A'}',
                                ),
                                if (conditions.isNotEmpty)
                                  Text(
                                    'Conditions: $conditions',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if ((patient['address'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    'Address: ${patient['address']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.info, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('View'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
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
                              onSelected: (value) {
                                if (value == 'view') {
                                  _showPatientDetails(patient);
                                } else if (value == 'edit') {
                                  _showEditPatientDialog(patient);
                                } else if (value == 'delete') {
                                  _confirmDeletePatient(patient);
                                }
                              },
                            ),
                            onTap: () => _showPatientDetails(patient),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    final name = _patientName(patient);
    final conditions = (patient['conditions'] as List? ?? [])
        .map((c) => (c['condition'] as Map? ?? {})['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${patient['id']}'),
              const SizedBox(height: 6),
              Text('Email: ${patient['email'] ?? 'N/A'}'),
              Text('Phone: ${patient['phone'] ?? 'N/A'}'),
              const Divider(height: 20),
              Text('Date of Birth: ${patient['date_of_birth'] ?? 'N/A'}'),
              Text('Gender: ${patient['gender'] ?? 'N/A'}'),
              Text('National ID: ${patient['national_id'] ?? 'N/A'}'),
              Text(
                'Address: ${(patient['address'] ?? '').isEmpty ? 'N/A' : patient['address']}',
              ),
              const SizedBox(height: 8),
              if (conditions.isNotEmpty) ...[
                const Text(
                  'Chronic Conditions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(conditions, style: const TextStyle(color: Colors.red)),
              ],
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

  // ─────────────────────────────────────────────────────────────────────────────
  // PAYMENT STATUS PAGE
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildPaymentStatus() {
    if (_loadingAppointments) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _getPaymentStats();
    final total = stats['total']!;
    final paid = stats['paid']!;
    final unpaid = stats['unpaid']!;
    final all = _appointments
        .where((a) => (a['status'] ?? '').toUpperCase() != 'CANCELLED')
        .toList();

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
                    'Payment Status',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Clinic: ${_clinic.isEmpty ? "N/A" : _clinic}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchAppointments,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total',
                  '${total.toStringAsFixed(2)} EGP',
                  Icons.receipt_long,
                  Colors.blue,
                  Colors.blue[50]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Paid',
                  '${paid.toStringAsFixed(2)} EGP',
                  Icons.check_circle,
                  Colors.green,
                  Colors.green[50]!,
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
                  Expanded(
                    child: Column(
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
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: all.isEmpty
                ? Center(
                    child: Text(
                      'No payment history',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchAppointments,
                    child: ListView.builder(
                      itemCount: all.length,
                      itemBuilder: (context, index) {
                        final a = all[index];
                        final isPaid = a['is_paid'] == true;
                        final fee = (a['fee'] ?? 0).toDouble();
                        final dt = _parseDate(a['start_time']);
                        final patName = _appointmentPatientName(a);
                        return ListTile(
                          leading: Icon(
                            isPaid ? Icons.check_circle : Icons.pending,
                            color: isPaid ? Colors.green : Colors.orange,
                          ),
                          title: Text(patName),
                          subtitle: Text(
                            '${dt != null ? DateFormat('dd/MM/yyyy - hh:mm a').format(dt) : 'N/A'} • Fee: ${fee.toStringAsFixed(2)} EGP',
                          ),
                          trailing: GestureDetector(
                            onTap: () =>
                                _togglePayment(a['id'] as int, a, isPaid),
                            child: Chip(
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
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePayment(
    int id,
    Map<String, dynamic> appointment,
    bool currentlyPaid,
  ) async {
    try {
      await ApiService.updateAppointment(id, {'is_paid': !currentlyPaid});
      _showSnack(
        currentlyPaid ? 'Marked as unpaid' : 'Marked as paid',
        Colors.green,
      );
      await _fetchAppointments();
    } catch (e) {
      _showSnack('Failed to update payment', Colors.red);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ADD PATIENT DIALOG
  // ─────────────────────────────────────────────────────────────────────────────

  void _showAddPatientDialog() {
    final nameFirstController = TextEditingController();
    final nameLastController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final nationalIdController = TextEditingController();
    final addressController = TextEditingController();
    String selectedGender = 'male';
    DateTime? selectedDob;
    bool _submitting = false;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Patient'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameFirstController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameLastController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      prefixIcon: Icon(Icons.person_outline),
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
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
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
                    onChanged: (v) => setState(() => selectedGender = v!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cake),
                    title: const Text('Date of Birth'),
                    subtitle: Text(
                      selectedDob != null
                          ? DateFormat('dd/MM/yyyy').format(selectedDob!)
                          : 'Tap to select',
                    ),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(
                          const Duration(days: 365 * 20),
                        ),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => selectedDob = d);
                    },
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
              onPressed: _submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => _submitting = true);
                      try {
                        final data = {
                          'first_name': nameFirstController.text.trim(),
                          'last_name': nameLastController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'gender': selectedGender,
                          if (emailController.text.trim().isNotEmpty)
                            'email': emailController.text.trim(),
                          if (selectedDob != null)
                            'date_of_birth': DateFormat(
                              'yyyy-MM-dd',
                            ).format(selectedDob!),
                          if (nationalIdController.text.trim().isNotEmpty)
                            'national_id': nationalIdController.text.trim(),
                          if (addressController.text.trim().isNotEmpty)
                            'address': addressController.text.trim(),
                        };
                        await ApiService.createPatient(data);
                        if (mounted) Navigator.pop(context);
                        _showSnack('Patient added successfully', Colors.green);
                        await _fetchPatients();
                      } on DioException catch (e) {
                        _showSnack(
                          e.response?.data?['detail'] ??
                              'Failed to add patient',
                          Colors.red,
                        );
                      } catch (e) {
                        _showSnack('Failed to add patient', Colors.red);
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EDIT PATIENT DIALOG
  // ─────────────────────────────────────────────────────────────────────────────

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
    DateTime? selectedDob = _parseDate(patient['date_of_birth']);
    bool _submitting = false;

    final formKey = GlobalKey<FormState>();
    final id = patient['id'] as int;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                        prefixIcon: Icon(Icons.person_outline),
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
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
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
                      onChanged: (v) => setState(() => selectedGender = v!),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cake),
                      title: const Text('Date of Birth'),
                      subtitle: Text(
                        selectedDob != null
                            ? DateFormat('dd/MM/yyyy').format(selectedDob!)
                            : 'Tap to select',
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedDob ??
                              DateTime.now().subtract(
                                const Duration(days: 365 * 20),
                              ),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => selectedDob = d);
                      },
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
              onPressed: _submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => _submitting = true);
                      try {
                        final data = <String, dynamic>{
                          'first_name': firstNameController.text.trim(),
                          'last_name': lastNameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'gender': selectedGender,
                          if (emailController.text.trim().isNotEmpty)
                            'email': emailController.text.trim(),
                          if (selectedDob != null)
                            'date_of_birth': DateFormat(
                              'yyyy-MM-dd',
                            ).format(selectedDob!),
                          if (nationalIdController.text.trim().isNotEmpty)
                            'national_id': nationalIdController.text.trim(),
                          if (addressController.text.trim().isNotEmpty)
                            'address': addressController.text.trim(),
                        };
                        await ApiService.updatePatient(id, data);
                        if (mounted) Navigator.pop(context);
                        _showSnack(
                          'Patient updated successfully',
                          Colors.green,
                        );
                        await _fetchPatients();
                      } on DioException catch (e) {
                        _showSnack(
                          e.response?.data?['detail'] ??
                              'Failed to update patient',
                          Colors.red,
                        );
                      } catch (e) {
                        _showSnack('Failed to update patient', Colors.red);
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
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

  // ─────────────────────────────────────────────────────────────────────────────
  // CREATE APPOINTMENT DIALOG
  // ─────────────────────────────────────────────────────────────────────────────

  void _showCreateAppointmentDialog() {
    if (_patients.isEmpty) {
      _showSnack(
        'No patients available. Please add patients first.',
        Colors.orange,
      );
      return;
    }

    Map<String, dynamic>? selectedPatient;
    Map<String, dynamic>? selectedDoctor = _doctors.isNotEmpty
        ? _doctors.first
        : null;
    Map<String, dynamic>? selectedApptType = _appointmentTypes.isNotEmpty
        ? _appointmentTypes.first
        : null;

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final reasonController = TextEditingController();
    final feeController = TextEditingController(
      text: selectedApptType != null
          ? (selectedApptType['default_fee'] ?? '').toString()
          : '0',
    );
    bool isPaid = false;
    bool isUrgent = false;
    bool _submitting = false;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Appointment'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Patient picker
                  InkWell(
                    onTap: () async {
                      final selected = await _showPatientSearchDialog();
                      if (selected != null) {
                        setState(() => selectedPatient = selected);
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

                  // Doctor picker
                  if (_doctors.isNotEmpty)
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedDoctor,
                      decoration: const InputDecoration(
                        labelText: 'Doctor *',
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                      items: _doctors
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'
                                    .trim(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedDoctor = v),
                    ),
                  const SizedBox(height: 12),

                  // Appointment Type picker
                  if (_appointmentTypes.isNotEmpty)
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedApptType,
                      decoration: const InputDecoration(
                        labelText: 'Appointment Type',
                        prefixIcon: Icon(Icons.medical_information_outlined),
                      ),
                      items: _appointmentTypes
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t['name'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedApptType = v;
                          if (v != null && v['default_fee'] != null) {
                            feeController.text = v['default_fee'].toString();
                          }
                        });
                      },
                    ),
                  const SizedBox(height: 12),

                  // Date
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
                      if (date != null) setState(() => selectedDate = date);
                    },
                  ),

                  // Time
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
                      if (time != null) setState(() => selectedTime = time);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Fee
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
                    onChanged: (v) => setState(() => isPaid = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isUrgent,
                    title: const Text('Urgent?'),
                    onChanged: (v) => setState(() => isUrgent = v),
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
              onPressed: _submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (selectedPatient == null) {
                        _showSnack('Please select a patient', Colors.orange);
                        return;
                      }
                      if (selectedDoctor == null) {
                        _showSnack('Please select a doctor', Colors.orange);
                        return;
                      }
                      setState(() => _submitting = true);
                      try {
                        final dt = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        final tzOffset = dt.timeZoneOffset;
                        final sign = tzOffset.isNegative ? '-' : '+';
                        final h = tzOffset.inHours.abs().toString().padLeft(
                          2,
                          '0',
                        );
                        final m = (tzOffset.inMinutes.abs() % 60)
                            .toString()
                            .padLeft(2, '0');
                        final startTime =
                            '${DateFormat("yyyy-MM-ddTHH:mm:ss").format(dt)}$sign$h:$m';

                        final data = {
                          'patient_id': selectedPatient!['id'],
                          'doctor_id': selectedDoctor!['id'],
                          if (selectedApptType != null)
                            'appointment_type_id': selectedApptType!['id'],
                          'start_time': startTime,
                          'reason': reasonController.text.trim(),
                          'is_urgent': isUrgent,
                          'is_paid': isPaid,
                          'fee':
                              double.tryParse(feeController.text.trim()) ?? 0.0,
                        };
                        await ApiService.createAppointment(data);
                        if (mounted) Navigator.pop(context);
                        _showSnack(
                          'Appointment created successfully',
                          Colors.green,
                        );
                        await _fetchAppointments();
                      } on DioException catch (e) {
                        _showSnack(
                          e.response?.data?['detail'] ??
                              'Failed to create appointment',
                          Colors.red,
                        );
                      } catch (e) {
                        _showSnack('Failed to create appointment', Colors.red);
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: _submitting
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

  // ─────────────────────────────────────────────────────────────────────────────
  // EDIT APPOINTMENT DIALOG
  // ─────────────────────────────────────────────────────────────────────────────

  void _showEditAppointmentDialog(Map<String, dynamic> appointment) {
    final id = appointment['id'] as int;
    final existingDt = _parseDate(appointment['start_time']) ?? DateTime.now();

    DateTime selectedDate = DateTime(
      existingDt.year,
      existingDt.month,
      existingDt.day,
    );
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(existingDt);

    final reasonController = TextEditingController(
      text: appointment['reason'] ?? '',
    );
    final feeController = TextEditingController(
      text: (appointment['fee'] ?? 0).toString(),
    );
    bool isPaid = appointment['is_paid'] == true;
    bool isUrgent = appointment['is_urgent'] == true;
    bool _submitting = false;

    // Current patient
    final patientData = appointment['patient'] as Map<String, dynamic>? ?? {};
    Map<String, dynamic>? selectedPatient = patientData.isNotEmpty
        ? patientData
        : null;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Appointment'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Patient picker
                    InkWell(
                      onTap: () async {
                        final selected = await _showPatientSearchDialog();
                        if (selected != null) {
                          setState(() => selectedPatient = selected);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Patient',
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
                        if (date != null) setState(() => selectedDate = date);
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
                        if (time != null) setState(() => selectedTime = time);
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
                      onChanged: (v) => setState(() => isPaid = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isUrgent,
                      title: const Text('Urgent?'),
                      onChanged: (v) => setState(() => isUrgent = v),
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
              onPressed: _submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => _submitting = true);
                      try {
                        final dt = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        final tzOffset = dt.timeZoneOffset;
                        final sign = tzOffset.isNegative ? '-' : '+';
                        final h = tzOffset.inHours.abs().toString().padLeft(
                          2,
                          '0',
                        );
                        final m = (tzOffset.inMinutes.abs() % 60)
                            .toString()
                            .padLeft(2, '0');
                        final startTime =
                            '${DateFormat("yyyy-MM-ddTHH:mm:ss").format(dt)}$sign$h:$m';

                        final data = <String, dynamic>{
                          'start_time': startTime,
                          'reason': reasonController.text.trim(),
                          'is_paid': isPaid,
                          'is_urgent': isUrgent,
                          'fee':
                              double.tryParse(feeController.text.trim()) ?? 0.0,
                          if (selectedPatient != null)
                            'patient_id': selectedPatient!['id'],
                        };
                        await ApiService.updateAppointment(id, data);
                        if (mounted) Navigator.pop(context);
                        _showSnack(
                          'Appointment updated successfully',
                          Colors.green,
                        );
                        await _fetchAppointments();
                      } on DioException catch (e) {
                        _showSnack(
                          e.response?.data?['detail'] ??
                              'Failed to update appointment',
                          Colors.red,
                        );
                      } catch (e) {
                        _showSnack('Failed to update appointment', Colors.red);
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
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

  // ─────────────────────────────────────────────────────────────────────────────
  // PATIENT SEARCH DIALOG (reused by both appointment dialogs)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _showPatientSearchDialog() async {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredPatients = List.from(_patients);

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                searchController.clear();
                                filteredPatients = List.from(_patients);
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    final q = value.toLowerCase().trim();
                    setState(() {
                      filteredPatients = q.isEmpty
                          ? List.from(_patients)
                          : _patients.where((p) {
                              final name = _patientName(p).toLowerCase();
                              final phone = (p['phone'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final nid = (p['national_id'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              return name.contains(q) ||
                                  phone.contains(q) ||
                                  nid.contains(q);
                            }).toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
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
                            final name = _patientName(p);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[700],
                                  child: Text(
                                    name.isNotEmpty
                                        ? name.substring(0, 1).toUpperCase()
                                        : '?',
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
                                    const SizedBox(height: 4),
                                    Text('Phone: ${p['phone'] ?? 'N/A'}'),
                                    Text(
                                      'DOB: ${p['date_of_birth'] ?? 'N/A'} | ${p['gender'] ?? ''}',
                                    ),
                                  ],
                                ),
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

  // ─────────────────────────────────────────────────────────────────────────────
  // DELETE PATIENT
  // ─────────────────────────────────────────────────────────────────────────────

  void _confirmDeletePatient(Map<String, dynamic> patient) {
    final id = patient['id'] as int;
    final name = _patientName(patient);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deletePatient(id);
                _showSnack('Patient deleted successfully', Colors.green);
                await _fetchPatients();
              } catch (e) {
                _showSnack('Failed to delete patient', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _errorWidget(String msg, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}
