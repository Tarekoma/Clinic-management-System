import 'package:flutter/material.dart';
import 'package:Hakim/Login%20Page.dart';
import 'package:Hakim/UserProfile.dart';
import 'package:Hakim/api_service.dart';
import 'package:intl/intl.dart';

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
      // ApiService.getPatients now only accepts search/skip/limit (limit ≤ 100)
      final data = await ApiService.getPatients(search: search);
      if (mounted) {
        setState(() => _patients = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _patientsError = true);
        _showSnack(
          'Failed to load patients: ${ApiService.extractError(e)}',
          Colors.red,
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
      // limit is now 100 inside ApiService — 422 is gone
      final data = await ApiService.getAppointments();
      if (mounted) {
        setState(() => _appointments = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _appointmentsError = true);
        _showSnack(
          'Failed to load appointments: ${ApiService.extractError(e)}',
          Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  Future<void> _fetchAppointmentTypes() async {
    // Hardcoded — API endpoint not available for doctor/assistant role
    if (mounted) {
      setState(() {
        _appointmentTypes = [
          {'key': 'consultation', 'label': 'Consultation', 'fee': 300},
          {'key': 'revisit', 'label': 'Revisit', 'fee': 150},
        ];
      });
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      final data = await ApiService.getDoctors();
      if (mounted) {
        setState(() => _doctors = List<Map<String, dynamic>>.from(data));
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
      // The API response may have patient_name as a flat field (Doctor dashboard
      // format) OR as a nested patient object (full list response). Handle both.
      final patientName = _appointmentPatientName(a).toLowerCase();
      final phone = _appointmentPatientField(a, 'phone').toLowerCase();
      final nid = _appointmentPatientField(a, 'national_id').toLowerCase();
      return patientName.contains(q) || phone.contains(q) || nid.contains(q);
    }).toList();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Returns "First Last" from a patient map.
  String _patientName(Map<String, dynamic> p) =>
      '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();

  /// Returns the patient name from an appointment map.
  /// Handles both flat `patient_name` and nested `patient` object.
  String _appointmentPatientName(Map<String, dynamic> a) {
    if (a['patient_name'] != null) return a['patient_name'].toString();
    final patient = a['patient'] as Map<String, dynamic>? ?? {};
    return _patientName(patient);
  }

  /// Reads a patient field from a nested appointment response.
  String _appointmentPatientField(Map<String, dynamic> a, String field) {
    final patient = a['patient'] as Map<String, dynamic>? ?? {};
    return (patient[field] ?? '').toString();
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
        return Colors.blue; // SCHEDULED
    }
  }

  Map<String, double> _getPaymentStats() {
    double total = 0, paid = 0;
    for (final a in _appointments) {
      if ((a['status'] ?? '').toUpperCase() == 'CANCELLED') continue;
      final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0.0;
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
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: Colors.green[700],
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
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
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
      ), // SingleChildScrollView
    ); // RefreshIndicator
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

    final List<Map<String, dynamic>> todayList = [];
    final List<Map<String, dynamic>> upcomingList = [];
    final List<Map<String, dynamic>> pastList = [];

    for (final a in all) {
      final dt = _parseDate(a['start_time']);
      if (dt == null) continue;
      if (!dt.isBefore(today) && dt.isBefore(tomorrow)) {
        todayList.add(a);
      } else if (!dt.isBefore(tomorrow)) {
        upcomingList.add(a);
      } else {
        pastList.add(a);
      }
    }

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

    final nextUp = todayList.where((a) {
      final s = (a['status'] ?? '').toUpperCase();
      return s == 'SCHEDULED' || s == 'CONFIRMED';
    }).toList();
    final serving = nextUp.isNotEmpty ? nextUp.first : null;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchAppointments,
        color: Colors.green[700],
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        displacement: 60,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ── Header ──
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
            // ── Search ──
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
            if (all.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(
                    'No appointments scheduled',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              if (serving != null) ...[
                const Text(
                  'Now Serving',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildAppointmentCard(serving, highlight: true),
                const SizedBox(height: 16),
              ],
              if (todayList.isNotEmpty) ...[
                const Text(
                  "Today's Appointments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...todayList.map(_buildAppointmentCard),
                const SizedBox(height: 16),
              ],
              if (upcomingList.isNotEmpty) ...[
                const Text(
                  'Upcoming Appointments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...upcomingList.map(_buildAppointmentCard),
              ],
              if (pastList.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Past Appointments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...pastList.map(_buildAppointmentCard),
              ],
            ],
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
    final patientName = _appointmentPatientName(appointment);
    final dt = _parseDate(appointment['start_time']);
    final fee = double.tryParse((appointment['fee'] ?? 0).toString()) ?? 0.0;
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
                  backgroundColor: isPaid ? Colors.green : Colors.orange,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
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
      _showSnack(
        'Failed to update status: ${ApiService.extractError(e)}',
        Colors.red,
      );
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

    return RefreshIndicator(
      onRefresh: _fetchPatients,
      color: Colors.green[700],
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 60,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── Header ──
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
          // ── Search ──
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
              if (v.length >= 2 || v.isEmpty) _fetchPatients(search: v);
            },
          ),
          const SizedBox(height: 16),
          if (patients.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  'No patients found',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...patients.map((patient) {
              final name = _patientName(patient);
              final conditions = (patient['conditions'] as List? ?? [])
                  .map(
                    (c) =>
                        (c['condition'] as Map? ?? {})['name']?.toString() ??
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                      if ((patient['address'] ?? '').toString().isNotEmpty)
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
            }),
        ],
      ),
    );
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    final name = _patientName(patient);
    final conditionsList = (patient['conditions'] as List? ?? [])
        .map((c) => (c['condition'] as Map? ?? {})['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
    final hasChronic =
        conditionsList.isNotEmpty ||
        (patient['chronic_disease'] != null &&
            patient['chronic_disease'].toString().trim().isNotEmpty);
    final chronicText = conditionsList.isNotEmpty
        ? conditionsList
        : (patient['chronic_disease'] ?? '');

    DateTime? birthDate = _parseDate(
      patient['birth_date'] ?? patient['date_of_birth'],
    );
    String ageText = 'N/A';
    if (birthDate != null) {
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day))
        age--;
      ageText = '$age years';
    }

    final patientAppointments = _appointments
        .where(
          (a) =>
              (a['patient_id'] ?? (a['patient'] as Map?)?['id']) ==
              patient['id'],
        )
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.green[700],
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
                  _showEditPatientDialog(patient);
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
                      colors: [Colors.green[700]!, Colors.green[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
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
                            color: Colors.green[700],
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
                              'Patient ID: ${patient['id']}',
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
                  color: Colors.green[700]!,
                  rows: [
                    _patientInfoRow(
                      Icons.wc,
                      'Gender',
                      (patient['gender'] ?? 'N/A').toString().toUpperCase(),
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
                      patient['national_id'] ?? 'N/A',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Contact Info ──
                _buildPatientDetailSection(
                  icon: Icons.contact_phone_outlined,
                  title: 'Contact Information',
                  color: Colors.teal[700]!,
                  rows: [
                    _patientInfoRow(
                      Icons.phone,
                      'Phone',
                      patient['phone'] ?? 'N/A',
                    ),
                    _patientInfoRow(
                      Icons.email_outlined,
                      'Email',
                      patient['email'] ?? 'N/A',
                    ),
                    _patientInfoRow(
                      Icons.location_on_outlined,
                      'Address',
                      patient['address'] ?? 'N/A',
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
                              .toUpperCase();
                          final statusColor = _statusColor(status);
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
                                    status,
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
                const SizedBox(height: 24),

                // ── Action Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditPatientDialog(patient);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Patient'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
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
                          _confirmDeletePatient(patient);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
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

    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      color: Colors.green[700],
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
          if (all.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: Text(
                  'No payment history',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...all.map((a) {
              final isPaid = a['is_paid'] == true;
              final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0.0;
              final dt = _parseDate(a['start_time']);
              final patName = _appointmentPatientName(a);
              return ListTile(
                leading: Icon(
                  isPaid ? Icons.check_circle : Icons.pending,
                  color: isPaid ? Colors.green : Colors.orange,
                ),
                title: Text(patName),
                subtitle: Text(
                  '${dt != null ? DateFormat('dd/MM/yyyy - hh:mm a').format(dt) : 'N/A'}'
                  ' • Fee: ${fee.toStringAsFixed(2)} EGP',
                ),
                trailing: GestureDetector(
                  onTap: () => _togglePayment(a['id'] as int, isPaid),
                  child: Chip(
                    label: Text(
                      isPaid ? 'PAID' : 'UNPAID',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    backgroundColor: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
              );
            }),
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

  Future<void> _togglePayment(int id, bool currentlyPaid) async {
    try {
      await ApiService.updateAppointment(id, {'is_paid': !currentlyPaid});
      _showSnack(
        currentlyPaid ? 'Marked as unpaid' : 'Marked as paid',
        Colors.green,
      );
      await _fetchAppointments();
    } catch (e) {
      _showSnack(
        'Failed to update payment: ${ApiService.extractError(e)}',
        Colors.red,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ADD PATIENT DIALOG
  // ─────────────────────────────────────────────────────────────────────────────

  void _showAddPatientDialog() {
    final firstController = TextEditingController();
    final lastController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final nationalIdController = TextEditingController();
    final addressController = TextEditingController();
    String selectedGender = 'male';
    DateTime? selectedDob;
    final List<String> commonDiseases = [
      'Diabetes',
      'Hypertension',
      'Asthma',
      'Heart Disease',
      'Arthritis',
    ];
    final Set<String> selectedDiseases = {};
    bool submitting = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
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
                      controller: firstController,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lastController,
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
                          setDlgState(() => selectedGender = v ?? 'male'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(
                            const Duration(days: 365 * 20),
                          ),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          helpText: 'Select Date of Birth',
                        );
                        if (d != null) setDlgState(() => selectedDob = d);
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
                              selectedDob != null
                                  ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(selectedDob!)
                                  : 'Tap to select',
                              style: TextStyle(
                                color: selectedDob != null
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
                    // ── Chronic Diseases ──
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
                              setDlgState(() {
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
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => submitting = true);
                      try {
                        await ApiService.createPatient({
                          'first_name': firstController.text.trim(),
                          'last_name': lastController.text.trim(),
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
                          if (selectedDiseases.isNotEmpty)
                            'chronic_disease': selectedDiseases.join(', '),
                        });
                        if (mounted) Navigator.pop(context);
                        _showSnack('Patient added successfully', Colors.green);
                        await _fetchPatients();
                      } catch (e) {
                        _showSnack(
                          'Failed to add patient: ${ApiService.extractError(e)}',
                          Colors.red,
                        );
                      } finally {
                        if (mounted) setDlgState(() => submitting = false);
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
    final firstController = TextEditingController(
      text: patient['first_name'] ?? '',
    );
    final lastController = TextEditingController(
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
    DateTime? selectedDob = _parseDate(
      patient['birth_date'] ?? patient['date_of_birth'],
    );
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
    bool submitting = false;
    final formKey = GlobalKey<FormState>();
    final id = patient['id'] as int;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
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
                      controller: firstController,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lastController,
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
                          setDlgState(() => selectedGender = v ?? 'male'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
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
                          helpText: 'Select Date of Birth',
                        );
                        if (d != null) setDlgState(() => selectedDob = d);
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
                              selectedDob != null
                                  ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(selectedDob!)
                                  : 'Tap to select',
                              style: TextStyle(
                                color: selectedDob != null
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
                    // ── Chronic Diseases ──
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
                              setDlgState(() {
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
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => submitting = true);
                      try {
                        await ApiService.updatePatient(id, {
                          'first_name': firstController.text.trim(),
                          'last_name': lastController.text.trim(),
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
                          'chronic_disease': selectedDiseases.isNotEmpty
                              ? selectedDiseases.join(', ')
                              : '',
                        });
                        if (mounted) Navigator.pop(context);
                        _showSnack(
                          'Patient updated successfully',
                          Colors.green,
                        );
                        await _fetchPatients();
                      } catch (e) {
                        _showSnack(
                          'Failed to update patient: ${ApiService.extractError(e)}',
                          Colors.red,
                        );
                      } finally {
                        if (mounted) setDlgState(() => submitting = false);
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
      _showSnack('No patients available. Add patients first.', Colors.orange);
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
    String selectedFeeType = 'consultation';
    final feeController = TextEditingController(text: '300');
    bool isPaid = false;
    bool isUrgent = false;
    bool submitting = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
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
                        setDlgState(() => selectedPatient = selected);
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
                      onChanged: (v) => setDlgState(() => selectedDoctor = v),
                    ),
                  const SizedBox(height: 12),

                  // Appointment Type picker
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
                        value: 'revisit',
                        child: Text('Revisit — 150 EGP'),
                      ),
                    ],
                    onChanged: (v) => setDlgState(() {
                      selectedFeeType = v ?? 'consultation';
                      feeController.text = selectedFeeType == 'consultation'
                          ? '300'
                          : '150';
                    }),
                  ),
                  const SizedBox(height: 12),
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
                      if (date != null) setDlgState(() => selectedDate = date);
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
                      if (time != null) setDlgState(() => selectedTime = time);
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
                      if (double.tryParse(v.trim()) == null) {
                        return 'Invalid fee';
                      }
                      return null;
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isPaid,
                    title: const Text('Paid?'),
                    onChanged: (v) => setDlgState(() => isPaid = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isUrgent,
                    title: const Text('Urgent?'),
                    onChanged: (v) => setDlgState(() => isUrgent = v),
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
                        _showSnack('Please select a patient', Colors.orange);
                        return;
                      }
                      if (selectedDoctor == null) {
                        _showSnack('Please select a doctor', Colors.orange);
                        return;
                      }
                      setDlgState(() => submitting = true);
                      try {
                        final dt = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        final startTime = _toIso8601WithTz(dt);
                        await ApiService.createAppointment({
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
                        });
                        if (mounted) Navigator.pop(context);
                        _showSnack('Appointment created', Colors.green);
                        await _fetchAppointments();
                      } catch (e) {
                        _showSnack(
                          'Failed to create appointment: ${ApiService.extractError(e)}',
                          Colors.red,
                        );
                      } finally {
                        if (mounted) setDlgState(() => submitting = false);
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
    bool submitting = false;

    // Pre-fill current patient from nested object
    final patientData = appointment['patient'] as Map<String, dynamic>? ?? {};
    Map<String, dynamic>? selectedPatient = patientData.isNotEmpty
        ? patientData
        : null;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
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
                          setDlgState(() => selectedPatient = selected);
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
                        if (date != null)
                          setDlgState(() => selectedDate = date);
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
                          setDlgState(() => selectedTime = time);
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
                        if (double.tryParse(v.trim()) == null) {
                          return 'Invalid fee';
                        }
                        return null;
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isPaid,
                      title: const Text('Paid?'),
                      onChanged: (v) => setDlgState(() => isPaid = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isUrgent,
                      title: const Text('Urgent?'),
                      onChanged: (v) => setDlgState(() => isUrgent = v),
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
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => submitting = true);
                      try {
                        final dt = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        await ApiService.updateAppointment(id, {
                          'start_time': _toIso8601WithTz(dt),
                          'reason': reasonController.text.trim(),
                          'is_paid': isPaid,
                          'is_urgent': isUrgent,
                          'fee':
                              double.tryParse(feeController.text.trim()) ?? 0.0,
                          if (selectedPatient != null)
                            'patient_id': selectedPatient!['id'],
                        });
                        if (mounted) Navigator.pop(context);
                        _showSnack(
                          'Appointment updated successfully',
                          Colors.green,
                        );
                        await _fetchAppointments();
                      } catch (e) {
                        _showSnack(
                          'Failed to update: ${ApiService.extractError(e)}',
                          Colors.red,
                        );
                      } finally {
                        if (mounted) setDlgState(() => submitting = false);
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
    List<Map<String, dynamic>> filtered = List.from(_patients);

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
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
                    hintText: 'Name, phone, or national ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setDlgState(() {
                              searchController.clear();
                              filtered = List.from(_patients);
                            }),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) {
                    final q = v.toLowerCase().trim();
                    setDlgState(() {
                      filtered = q.isEmpty
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
                  '${filtered.length} patient(s) found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No patients found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final p = filtered[index];
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
                _showSnack(
                  'Failed to delete patient: ${ApiService.extractError(e)}',
                  Colors.red,
                );
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

  /// Formats a DateTime to ISO-8601 with the device's timezone offset.
  /// e.g. "2026-03-01T10:00:00+02:00"  — required by the backend.
  String _toIso8601WithTz(DateTime dt) {
    final tz = dt.timeZoneOffset;
    final sign = tz.isNegative ? '-' : '+';
    final hh = tz.inHours.abs().toString().padLeft(2, '0');
    final mm = (tz.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${DateFormat("yyyy-MM-ddTHH:mm:ss").format(dt)}$sign$hh:$mm';
  }

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
