// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_appt_details_sheet.dart
//
// Patient & appointment details bottom sheet.
// Opened when the doctor taps "Details" on any appointment card.
// Pure View — zero business logic; all data supplied via constructor.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

// ── Entry-point helper ────────────────────────────────────────────────────────

/// Convenience function called from DoctorAppointmentsPage.
/// [appt]    — appointment map from ViewModel state.
/// [patient] — optional enriched patient map from state.patients.
void showAppointmentDetails({
  required BuildContext context,
  required Map<String, dynamic> appt,
  Map<String, dynamic>? patient,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DoctorApptDetailsSheet(appt: appt, patient: patient),
  );
}

// ── Main sheet widget ─────────────────────────────────────────────────────────

class DoctorApptDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> appt;

  /// Richer patient record from state.patients (may be null; sheet falls back
  /// gracefully to whatever data is embedded inside the appointment map).
  final Map<String, dynamic>? patient;

  const DoctorApptDetailsSheet({required this.appt, this.patient, Key? key})
    : super(key: key);

  // ── Data helpers ──────────────────────────────────────────────────────────

  String get _fullName {
    final fn =
        appt['patient_first_name'] ??
        appt['patient']?['first_name'] ??
        patient?['first_name'] ??
        '';
    final ln =
        appt['patient_last_name'] ??
        appt['patient']?['last_name'] ??
        patient?['last_name'] ??
        '';
    final full = '$fn $ln'.trim();
    return full.isEmpty ? 'Unknown Patient' : full;
  }

  String get _initials {
    final parts = _fullName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?';
  }

  String get _phone =>
      appt['patient_phone'] ??
      appt['patient']?['phone'] ??
      patient?['phone'] ??
      '—';

  String get _nationalId =>
      appt['patient_national_id'] ??
      appt['patient']?['national_id'] ??
      patient?['national_id'] ??
      '—';

  String get _gender {
    final raw =
        appt['patient_gender'] ??
        appt['patient']?['gender'] ??
        patient?['gender'] ??
        '';
    if (raw.toString().isEmpty) return '—';
    return raw.toString()[0].toUpperCase() +
        raw.toString().substring(1).toLowerCase();
  }

  String get _dobFormatted {
    final raw =
        appt['patient_date_of_birth'] ??
        appt['patient']?['date_of_birth'] ??
        patient?['date_of_birth'];
    if (raw == null) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  int? get _age {
    final raw =
        appt['patient_date_of_birth'] ??
        appt['patient']?['date_of_birth'] ??
        patient?['date_of_birth'];
    if (raw == null) return null;
    try {
      final dob = DateTime.parse(raw.toString());
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day))
        age--;
      return age;
    } catch (_) {
      return null;
    }
  }

  String get _bloodType =>
      appt['patient_blood_type'] ??
      appt['patient']?['blood_type'] ??
      patient?['blood_type'] ??
      '—';

  List<String> get _chronicDiseases {
    final raw =
        appt['patient']?['chronic_diseases'] ??
        patient?['chronic_diseases'] ??
        appt['chronic_diseases'];
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  String get _apptType =>
      appt['appointment_type_name'] ??
      appt['type_name'] ??
      appt['appointment_type']?['name'] ??
      'Consultation';

  String get _status =>
      (appt['status'] ?? 'SCHEDULED').toString().toUpperCase();

  bool get _isUrgent => appt['is_urgent'] == true;
  double get _fee => double.tryParse((appt['fee'] ?? 0).toString()) ?? 0;
  bool get _isPaid => appt['is_paid'] == true;
  String get _notes =>
      appt['notes'] ?? appt['doctor_notes'] ?? appt['complaint'] ?? '';

  String get _apptDateFormatted {
    try {
      final dt = DateTime.parse(appt['start_time'].toString()).toLocal();
      return DateFormat('EEE, dd MMM yyyy  •  hh:mm a').format(dt);
    } catch (_) {
      return '—';
    }
  }

  Color get _statusColor {
    switch (_status) {
      case 'COMPLETED':
        return const Color(0xFF22C55E);
      case 'IN_PROGRESS':
        return const Color(0xFF3B82F6);
      case 'CANCELLED':
        return _T.urgent;
      default:
        return _T.navy;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.93,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: dt.bgPage,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dt.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _buildHeader(context),
            Divider(height: 1, color: dt.divider),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _sectionTitle(context, 'Appointment'),
                  _buildApptInfo(),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'Patient Information'),
                  _buildPatientInfo(),
                  if (_chronicDiseases.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle(context, 'Chronic Conditions'),
                    _buildConditionChips(),
                  ],
                  if (_notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle(context, 'Notes / Chief Complaint'),
                    _buildNotesCard(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B3D6B), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: dt.textH,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    _StatusBadge(label: _statusLabel, color: _statusColor),
                    if (_isUrgent) ...[
                      const SizedBox(width: 6),
                      _StatusBadge(label: '⚡ Urgent', color: _T.urgent),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: dt.textS),
          ),
        ],
      ),
    );
  }

  // ── Appointment card ──────────────────────────────────────────────────────

  Widget _buildApptInfo() => _InfoCard(
    children: [
      _InfoRow(
        icon: Icons.calendar_today_rounded,
        label: 'Date & Time',
        value: _apptDateFormatted,
      ),
      _InfoRow(
        icon: Icons.medical_services_outlined,
        label: 'Type',
        value: _apptType,
      ),
      _InfoRow(
        icon: Icons.payments_outlined,
        label: 'Fee',
        value: '${_fee.toStringAsFixed(0)} EGP',
        valueColor: _T.teal,
      ),
      _InfoRow(
        icon: _isPaid
            ? Icons.check_circle_outline_rounded
            : Icons.radio_button_unchecked_rounded,
        label: 'Payment',
        value: _isPaid ? 'Paid' : 'Unpaid',
        valueColor: _isPaid ? const Color(0xFF22C55E) : _T.urgent,
      ),
    ],
  );

  // ── Patient card ──────────────────────────────────────────────────────────

  Widget _buildPatientInfo() {
    final age = _age;
    return _InfoCard(
      children: [
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: _phone,
          copyable: _phone != '—',
        ),
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'National ID',
          value: _nationalId,
          copyable: _nationalId != '—',
        ),
        _InfoRow(icon: Icons.wc_rounded, label: 'Gender', value: _gender),
        _InfoRow(
          icon: Icons.cake_outlined,
          label: 'Date of Birth',
          value: age != null ? '$_dobFormatted  ($age yrs)' : _dobFormatted,
        ),
        _InfoRow(
          icon: Icons.bloodtype_outlined,
          label: 'Blood Type',
          value: _bloodType,
          valueColor: _bloodType != '—' ? _T.urgent : null,
        ),
      ],
    );
  }

  // ── Condition chips ───────────────────────────────────────────────────────

  Widget _buildConditionChips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _chronicDiseases
        .map(
          (d) => Chip(
            label: Text(
              d,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _T.navy,
              ),
            ),
            backgroundColor: _T.navy.withOpacity(0.08),
            side: BorderSide(color: _T.navy.withOpacity(0.18)),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        )
        .toList(),
  );

  // ── Notes ─────────────────────────────────────────────────────────────────

  Widget _buildNotesCard(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dt.divider),
      ),
      child: Text(
        _notes,
        style: TextStyle(fontSize: 13, color: dt.textS, height: 1.55),
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, String text) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: dt.textS,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return Container(
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dt.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(
          children.length,
          (i) => Column(
            children: [
              children[i],
              if (i < children.length - 1)
                Divider(height: 1, indent: 48, color: dt.divider),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool copyable;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _T.navy.withOpacity(0.07),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: _T.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: dt.textS,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? dt.textH,
                  ),
                ),
              ],
            ),
          ),
          if (copyable && value != '—')
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: _T.teal,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: dt.textM.withOpacity(0.75),
              ),
            ),
        ],
      ),
    );
  }
}
