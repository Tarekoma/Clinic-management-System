// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/assistant/assistant_appt_form.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/services/settings_service.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/viewmodels/assistant_viewmodel.dart';
import 'assistant_shared_widgets.dart';

typedef _T = AssistantTheme;
typedef _Empty = AssistantEmpty;
typedef _Avatar = AssistantAvatar;
typedef _ToggleRow = AssistantToggleRow;

// ══════════════════════════════════════════════════════════════════════════════
// AssistantApptForm
// ══════════════════════════════════════════════════════════════════════════════

class AssistantApptForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> patients;
  final int? activeDoctorId;
  final List<Map<String, dynamic>> appointmentTypes;
  final Future<void> Function() onSaved;
  final void Function(String, {bool err}) snack;
  final Future<void> Function(Map<String, dynamic> data, {int? existingId})
  onSubmit;
  final String Function(Map<String, dynamic>) patName;

  /// When set (new appointment opened from the patients page), the patient
  /// field is pre-filled and locked — no search required.
  final Map<String, dynamic>? preSelectedPatient;

  /// All existing appointments — used for client-side overlap detection.
  final List<Map<String, dynamic>> existingAppointments;

  const AssistantApptForm({
    this.existing,
    this.preSelectedPatient,
    required this.patients,
    this.activeDoctorId,
    required this.appointmentTypes,
    required this.onSaved,
    required this.snack,
    required this.onSubmit,
    required this.patName,
    this.existingAppointments = const [],
    Key? key,
  }) : super(key: key);

  @override
  State<AssistantApptForm> createState() => _AssistantApptFormState();
}

// ══════════════════════════════════════════════════════════════════════════════
// _AssistantApptFormState
// ══════════════════════════════════════════════════════════════════════════════

class _AssistantApptFormState extends State<AssistantApptForm> {
  Map<String, dynamic>? _selPatient;
  Map<String, dynamic>? _selType;
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _time = TimeOfDay.now();
  final _feeCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _isPaid = false;
  bool _isUrgent = false;
  bool _saving = false;
  double _consultDefaultFee = 200.0;
  double _revisitDefaultFee = 100.0;

  bool _dateChanged = false;

  // ── Fallback types when API returns empty ─────────────────────────────────
  static const _fallbackTypes = [
    {'id': 1, 'name': 'Consultation'},
    {'id': 2, 'name': 'Revisit'},
  ];

  List<Map<String, dynamic>> get _effectiveTypes =>
      widget.appointmentTypes.isNotEmpty
      ? widget.appointmentTypes
      : List<Map<String, dynamic>>.from(_fallbackTypes);

  // ── Helpers ──────────────────────────────────────────────────────────────────
  IconData _iconForType(String name) {
    final n = name.toLowerCase();
    if (n.contains('revisit') || n.contains('follow')) {
      return Icons.refresh_rounded;
    }
    return Icons.medical_services_rounded;
  }

  bool _isRevisitType(Map<String, dynamic> type) {
    final name = (type['name'] ?? '').toString().toLowerCase();
    return name.contains('revisit') || name.contains('follow');
  }

  String _localizeTypeName(String name, AppLocalizations loc) {
    final n = name.toLowerCase();
    if (n.contains('revisit') || n.contains('follow')) return loc.visitTypeRevisit;
    if (n.contains('consult')) return loc.visitTypeConsultation;
    return name;
  }

  @override
  void initState() {
    super.initState();
    _loadAndApplyFeeDefaults();

    // Default to first effective type
    final types = _effectiveTypes;
    if (types.isNotEmpty) {
      _selType = types.first;
      _feeCtrl.text = (_selType!['default_fee'] ?? 0).toString();
    }

    final e = widget.existing;
    // Pre-select patient when launched from the patients page (new appt flow).
    if (widget.preSelectedPatient != null && e == null) {
      _selPatient = widget.preSelectedPatient;
    }
    if (e != null) {
      final pid = (e['patient_id'] ?? e['patient']?['id'] ?? '').toString();
      _selPatient = widget.patients
          .where((p) => p['id'].toString() == pid)
          .firstOrNull;

      final tid =
          (e['appointment_type_id'] ?? e['appointment_type']?['id'] ?? '')
              .toString();
      _selType =
          _effectiveTypes.where((t) => t['id'].toString() == tid).firstOrNull ??
          (_effectiveTypes.isNotEmpty ? _effectiveTypes.first : null);

      try {
        final dt = DateTime.parse(e['start_time'].toString()).toLocal();
        _date = dt;
        _time = TimeOfDay.fromDateTime(dt);
      } catch (_) {}

      _isPaid = e['is_paid'] == true;
      _isUrgent = e['is_urgent'] == true;
      _feeCtrl.text = (e['fee'] ?? _selType?['default_fee'] ?? '0').toString();
      _reasonCtrl.text = e['reason'] ?? '';
    }
  }

  Future<void> _loadAndApplyFeeDefaults() async {
    final fees = await SettingsService.loadFeeDefaults();
    if (!mounted) return;
    setState(() {
      _consultDefaultFee = fees['consultation']!;
      _revisitDefaultFee = fees['revisit']!;
      // Only update fee for new appointments, not edits
      if (widget.existing == null && _selType != null) {
        _feeCtrl.text = _isRevisitType(_selType!)
            ? _revisitDefaultFee.toStringAsFixed(0)
            : _consultDefaultFee.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  // ── Date / time picker ──────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    // Capture before async gaps to avoid use-after-deactivation.
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now)
          ? _date
          : now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: locale,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _T.green),
        ),
        child: child!,
      ),
    );
    if (d == null || !mounted) return;

    final t = await showTimePicker(
      context: context,
      initialTime: _date.isAfter(now)
          ? TimeOfDay.fromDateTime(_date)
          : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _T.green),
        ),
        child: child!,
      ),
    );
    if (t == null || !mounted) return;

    final picked = DateTime(d.year, d.month, d.day, t.hour, t.minute);

    if (picked.isBefore(now)) {
      widget.snack(loc.selectedTimeInPast, err: true);
      return;
    }

    setState(() {
      _date = picked;
      _time = t;
      _dateChanged = true;
    });
  }

  bool _hasConflict(DateTime proposed) {
    const window = Duration(minutes: 45);
    final existingId = widget.existing != null
        ? int.tryParse(widget.existing!['id'].toString())
        : null;
    for (final a in widget.existingAppointments) {
      final status = (a['status'] ?? '').toString().toUpperCase();
      if (status == 'CANCELLED' || status == 'NO_SHOW') continue;
      final id = int.tryParse(a['id'].toString());
      if (id != null && id == existingId) continue;
      DateTime? start;
      try {
        start = DateTime.parse(a['start_time'].toString()).toLocal();
      } catch (_) {
        continue;
      }
      final diff = proposed.difference(start).abs();
      if (diff < window) return true;
    }
    return false;
  }

  // ── Save ────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;

    if (_selPatient == null) {
      widget.snack(loc.pleaseSelectPatient, err: true);
      return;
    }

    final isNew = widget.existing == null;
    if (isNew || _dateChanged) {
      final dt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dtDateOnly = DateTime(dt.year, dt.month, dt.day);
      if (dtDateOnly.isBefore(today)) {
        widget.snack(loc.appointmentTimeMustBeFuture, err: true);
        return;
      }
      if (_hasConflict(dt)) {
        widget.snack(loc.appointmentSlotConflict, err: true);
        return;
      }
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
      final fee = double.tryParse(_feeCtrl.text.trim()) ?? 0.0;

      // Persist fee as new default for this visit type
      if (_selType != null) {
        if (_isRevisitType(_selType!)) {
          await SettingsService.setRevisitFee(fee);
        } else {
          await SettingsService.setConsultationFee(fee);
        }
      }

      final data = {
        'patient_id': _selPatient!['id'],
        if (widget.activeDoctorId != null) 'doctor_id': widget.activeDoctorId!,
        // Only send the ID if it came from the real backend list, not the fallback
        if (_selType != null && widget.appointmentTypes.isNotEmpty)
          'appointment_type_id': _selType!['id'],
        if (_selType != null) 'appointment_type_name': _selType!['name'] ?? '',
        if (isNew || _dateChanged)
          'start_time': AssistantViewModel.toIso8601WithTz(dt),
        'is_paid': _isPaid,
        'is_urgent': _isUrgent,
        'fee': fee,
        if (_reasonCtrl.text.trim().isNotEmpty)
          'reason': _reasonCtrl.text.trim(),
      };

      await widget.onSubmit(
        data,
        existingId: widget.existing != null
            ? int.tryParse(widget.existing!['id'].toString())
            : null,
      );
      await widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      widget.snack(AssistantViewModel.extractError(e), err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;

    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final types = _effectiveTypes;

    return Container(
      decoration: BoxDecoration(
        color: at.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: at.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.existing != null
                  ? loc.editAppointmentTitle
                  : loc.newAppointment,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: at.textH,
              ),
            ),
            const SizedBox(height: 20),

            // ── Patient inline search ────────────────────────────────────
            _AssistantPatientSearchField(
              patients: widget.patients,
              patName: widget.patName,
              selectedPatient: _selPatient,
              locked:
                  widget.preSelectedPatient != null && widget.existing == null,
              onSelected: (p) => setState(() => _selPatient = p),
            ),
            const SizedBox(height: 14),

            // ── Visit Type ───────────────────────────────────────────────
            Text(
              loc.visitType,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: at.textS,
              ),
            ),
            const SizedBox(height: 8),

            // Always renders — uses API types or fallback
            Row(
              children: types.asMap().entries.map((entry) {
                final idx = entry.key;
                final type = entry.value;
                final isSelected = _selType?['id'] == type['id'];
                final isRevisit = _isRevisitType(type);
                final fee = isRevisit
                    ? _revisitDefaultFee.toStringAsFixed(0)
                    : _consultDefaultFee.toStringAsFixed(0);

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: idx == 0 ? 0 : 5,
                      right: idx == types.length - 1 ? 0 : 5,
                    ),
                    child: _VisitTypeCard(
                      icon: _iconForType(type['name'] ?? ''),
                      label: _localizeTypeName(type['name'] ?? '', loc),
                      price: arDigits('$fee ${loc.currencyEgp}', lc),
                      selected: isSelected,
                      onTap: () {
                        // Save whatever user typed into the current type
                        final edited = double.tryParse(_feeCtrl.text.trim());
                        if (edited != null && _selType != null) {
                          if (_isRevisitType(_selType!)) {
                            _revisitDefaultFee = edited;
                          } else {
                            _consultDefaultFee = edited;
                          }
                        }
                        // Switch to new type and load its fee
                        setState(() {
                          _selType = type;
                          _feeCtrl.text = _isRevisitType(type)
                              ? _revisitDefaultFee.toStringAsFixed(0)
                              : _consultDefaultFee.toStringAsFixed(0);
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // ── Date & Time ──────────────────────────────────────────────
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: _T.inpOf(
                  context,
                  loc.dateTimeLabel,
                  pre: Icon(Icons.event_rounded, size: 18, color: at.textM),
                ),
                child: Text(
                  arDigits(
                    DateFormat('dd MMM yyyy  •  hh:mm a', lc).format(dateTime),
                    lc,
                  ),
                  style: TextStyle(fontSize: 13, color: at.textH),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Fee ──────────────────────────────────────────────────────
            TextField(
              controller: _feeCtrl,
              keyboardType: TextInputType.number,
              decoration: _T.inpOf(
                context,
                loc.feeEgpLabel,
                pre: Icon(Icons.payments_outlined, size: 18, color: at.textM),
              ),
            ),
            const SizedBox(height: 14),

            // ── Reason ───────────────────────────────────────────────────
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: _T.inpOf(context, loc.reasonNotesOptional),
            ),
            const SizedBox(height: 14),

            // ── Toggles ──────────────────────────────────────────────────
            _ToggleRow(
              label: loc.markAsPaid,
              icon: Icons.payments_rounded,
              value: _isPaid,
              color: _T.success,
              bg: _T.successBg,
              onChanged: (v) => setState(() => _isPaid = v),
            ),
            const SizedBox(height: 10),
            _ToggleRow(
              label: loc.markAsUrgent,
              icon: Icons.warning_amber_rounded,
              value: _isUrgent,
              color: _T.urgent,
              bg: _T.urgentBg,
              onChanged: (v) => setState(() => _isUrgent = v),
            ),
            const SizedBox(height: 24),

            // ── Save button ──────────────────────────────────────────────
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
                            ? loc.saveChanges
                            : loc.bookAppointment,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            SizedBox(
              height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 12,
            ),
          ],
        ),
      ),
    );
  }
} // ← closes _AssistantApptFormState

// ══════════════════════════════════════════════════════════════════════════════
// _VisitTypeCard
// ══════════════════════════════════════════════════════════════════════════════

class _VisitTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  const _VisitTypeCard({
    required this.icon,
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? _T.green.withOpacity(0.10) : at.bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _T.green : at.divider,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? _T.green.withOpacity(0.15)
                    : at.divider.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 17,
                color: selected ? _T.green : at.textM,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? _T.green : at.textS,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: selected ? _T.green.withOpacity(0.8) : at.textM,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 16, color: _T.green),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _AssistantPatientSearchField
// ══════════════════════════════════════════════════════════════════════════════

class _AssistantPatientSearchField extends StatefulWidget {
  final List<Map<String, dynamic>> patients;
  final String Function(Map<String, dynamic>) patName;
  final Map<String, dynamic>? selectedPatient;
  final void Function(Map<String, dynamic>?) onSelected;

  /// When true the field is read-only (patient was pre-selected).
  final bool locked;

  const _AssistantPatientSearchField({
    required this.patients,
    required this.patName,
    required this.selectedPatient,
    required this.onSelected,
    this.locked = false,
    Key? key,
  }) : super(key: key);

  @override
  State<_AssistantPatientSearchField> createState() =>
      _AssistantPatientSearchFieldState();
}

class _AssistantPatientSearchFieldState
    extends State<_AssistantPatientSearchField> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedPatient != null) {
      _ctrl.text = widget.patName(widget.selectedPatient!);
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
        final name = widget.patName(p).toLowerCase();
        final phone = (p['phone'] ?? '').toString().toLowerCase();
        final nid = (p['national_id'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            nid.contains(query);
      }).toList();
      _showResults = true;
    });
  }

  void _pick(Map<String, dynamic> p) {
    _ctrl.text = widget.patName(p);
    setState(() {
      _showResults = false;
      _results = [];
    });
    widget.onSelected(p);
    FocusScope.of(context).unfocus();
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _results = [];
      _showResults = false;
    });
    widget.onSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final selected = widget.selectedPatient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          readOnly: widget.locked,
          decoration: _T.inpOf(
            context,
            loc.searchPatientNameFull,
            pre: Icon(Icons.person_search_rounded, size: 18, color: at.textM),
            suf: (!widget.locked && _ctrl.text.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: _clear,
                  )
                : null,
          ),
          onChanged: widget.locked ? null : _search,
        ),

        // ── Selected chip ──────────────────────────────────────────────
        if (selected != null && !_showResults) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _T.successBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _T.success.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: _T.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.patName(selected),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _T.success,
                    ),
                  ),
                ),
                if ((selected['phone'] ?? '').toString().isNotEmpty)
                  Text(
                    selected['phone'].toString(),
                    style: TextStyle(fontSize: 11, color: at.textS),
                  ),
              ],
            ),
          ),
        ],

        // ── Dropdown results ───────────────────────────────────────────
        if (_showResults) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: at.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: at.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: _results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      loc.noPatientsFoundShort,
                      style: TextStyle(fontSize: 13, color: at.textS),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: at.divider),
                    itemBuilder: (_, i) {
                      final p = _results[i];
                      final name = widget.patName(p);
                      final phone = (p['phone'] ?? '').toString();
                      final nid = (p['national_id'] ?? '').toString();
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
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: at.textH,
                                      ),
                                    ),
                                    if (phone.isNotEmpty || nid.isNotEmpty)
                                      Text(
                                        [phone, nid]
                                            .where((s) => s.isNotEmpty)
                                            .join('  •  '),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: at.textS,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: at.textM,
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
      ],
    );
  }
} // ← closes _AssistantPatientSearchFieldState
