// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_appt_form.dart
// Localized via AppLocalizations.
//
// CHANGES IN THIS VERSION:
//   • Visit-type card fee labels ('100 EGP' / '300 EGP') now use
//     loc.currencyEgp + arNumber() for Arabic-Indic digits + localized
//     currency word.
//   • Date & Time display row now passes locale to DateFormat and wraps
//     the result in arDigits() so day/time digits localize too.
//   • The editable Fee TextField itself is left untouched on purpose —
//     converting typed input to Arabic-Indic digits would break
//     double.tryParse() when reading the value back.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';

typedef _T = DoctorTheme;

// ── Appointment Form ──────────────────────────────────────────────────────────

class DoctorApptForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> types;
  final int doctorId;

  /// Called with the validated form data.
  final Future<void> Function(Map<String, dynamic> data, {int? existingId})
  onSubmit;

  final void Function(String, {bool err}) snack;

  // ── pre-select a patient when opening from the patients page ───────────
  final Map<String, dynamic>? preSelectedPatient;

  /// All existing appointments — used for client-side overlap detection.
  final List<Map<String, dynamic>> existingAppointments;

  const DoctorApptForm({
    this.existing,
    this.preSelectedPatient,
    required this.patients,
    required this.types,
    required this.doctorId,
    required this.onSubmit,
    required this.snack,
    this.existingAppointments = const [],
    Key? key,
  }) : super(key: key);

  @override
  State<DoctorApptForm> createState() => _DoctorApptFormState();
}

class _DoctorApptFormState extends State<DoctorApptForm> {
  int? _patId, _typeId;
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  bool _urgent = false;
  bool _isPaid = false;
  final _feeCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;
  String _visitType = 'consultation';

  bool _dateChanged = false;
  String? _originalStartTime;

  double _consultDefaultFee = 200.0;
  double _revisitDefaultFee = 100.0;

  @override
  void initState() {
    super.initState();
    _loadAndApplyFeeDefaults();

    final e = widget.existing;
    if (e != null) {
      // ── Editing an existing appointment ─────────────────────────────────────
      _patId = int.tryParse(
        (e['patient_id'] ?? e['patient']?['id'] ?? '').toString(),
      );
      _typeId = int.tryParse(
        (e['appointment_type_id'] ?? e['appointment_type']?['id'] ?? '')
            .toString(),
      );
      _originalStartTime = e['start_time']?.toString();
      try {
        _date = DateTime.parse(e['start_time'].toString()).toLocal();
      } catch (_) {}
      _urgent = e['is_urgent'] == true;
      _isPaid = e['is_paid'] == true;
      _feeCtrl.text = (e['fee'] ?? '').toString();
      final existingType = (e['appointment_type_name'] ?? '')
          .toString()
          .toLowerCase();
      _visitType =
          (existingType.contains('revisit') || existingType.contains('follow'))
          ? 'revisit'
          : 'consultation';
      _reasonCtrl.text = e['reason'] ?? '';
    } else {
      // ── New appointment — pre-select patient if provided ────────────────────
      // The correct state field is _patId (int?), not _selectedPatientId.
      if (widget.preSelectedPatient != null) {
        _patId = int.tryParse(
          (widget.preSelectedPatient!['id'] ?? '').toString(),
        );
      }
    }
  }

  Future<void> _loadAndApplyFeeDefaults() async {
    final fees = await SettingsService.loadFeeDefaults();
    if (!mounted) return;
    setState(() {
      _consultDefaultFee = fees['consultation']!;
      _revisitDefaultFee = fees['revisit']!;
      if (widget.existing == null) {
        _feeCtrl.text = _visitType == 'revisit'
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

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    if (_patId == null) {
      _snack(loc.pleaseSelectPatient, err: true);
      return;
    }

    final isNew = widget.existing == null;
    if (isNew || _dateChanged) {
      if (_date.isBefore(DateTime.now())) {
        _snack(loc.appointmentTimeMustBeFuture, err: true);
        return;
      }
      if (_hasConflict(_date)) {
        _snack(loc.appointmentSlotConflict, err: true);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final fee = double.tryParse(_feeCtrl.text) ?? 0;

      if (_visitType == 'consultation') {
        await SettingsService.setConsultationFee(fee);
      } else {
        await SettingsService.setRevisitFee(fee);
      }

      String? startTime;
      if (isNew || _dateChanged) {
        startTime = _toLocalIso8601(_date);
      }

      final data = {
        if (widget.doctorId > 0) 'doctor_id': widget.doctorId,
        'patient_id': _patId,
        if (_typeId != null) 'appointment_type_id': _typeId,
        if (startTime != null) 'start_time': startTime,
        'is_urgent': _urgent,
        'is_paid': _isPaid,
        if (_feeCtrl.text.isNotEmpty) 'fee': fee,
        'appointment_type_name': _visitType == 'consultation'
            ? 'Consultation'
            : 'Revisit',
        if (_reasonCtrl.text.isNotEmpty) 'reason': _reasonCtrl.text.trim(),
      };

      await widget.onSubmit(
        data,
        existingId: widget.existing != null
            ? int.tryParse(widget.existing!['id'].toString())
            : null,
      );
      // Pop with `true` so _showForm knows the save succeeded and can
      // switch the appointments filter to Upcoming automatically.
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      // ── FIX: route API errors through the parent page's snack callback ────
      widget.snack(e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _toLocalIso8601(DateTime dt) {
    final local = dt.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hh = offset.inHours.abs().toString().padLeft(2, '0');
    final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final y = local.year.toString().padLeft(4, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$y-$mo-${d}T$h:$mi:$s$sign$hh:$mm';
  }

  Future<void> _pickDate() async {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now)
          ? _date
          : now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
      initialTime: TimeOfDay.fromDateTime(
        _date.isAfter(now) ? _date : now.add(const Duration(hours: 1)),
      ),
    );
    if (t == null || !mounted) return;
    final picked = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    if (picked.isBefore(now)) {
      _snack(loc.selectedTimeInPast, err: true);
      return;
    }
    setState(() {
      _date = picked;
      _dateChanged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    return Container(
      decoration: BoxDecoration(
        color: dt.bgCard,
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
            // ── Drag handle ──────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dt.divider,
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
                color: dt.textH,
              ),
            ),
            const SizedBox(height: 20),

            // ── Patient search ───────────────────────────────────────────────
            DoctorPatientSearchField(
              patients: widget.patients,
              selectedId: _patId,
              // Lock the field when patient was pre-selected from patients page
              locked:
                  widget.preSelectedPatient != null && widget.existing == null,
              onSelected: (id) => setState(() => _patId = id),
            ),
            const SizedBox(height: 14),

            // ── Visit Type Selector ──────────────────────────────────────────
            Text(
              loc.visitType,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dt.textS,
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
                            : dt.bgInput,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _visitType == 'consultation'
                              ? _T.navy
                              : dt.divider,
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
                                : dt.textM,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc.visitTypeConsultation,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _visitType == 'consultation'
                                  ? Colors.white
                                  : dt.textS,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            // FIXED: was '${_consultDefaultFee.toStringAsFixed(0)} EGP'
                            '${arNumber(_consultDefaultFee, localeCode)} ${loc.currencyEgp}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _visitType == 'consultation'
                                  ? Colors.white.withOpacity(0.75)
                                  : dt.textM,
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
                        color: _visitType == 'revisit' ? _T.teal : dt.bgInput,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _visitType == 'revisit' ? _T.teal : dt.divider,
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
                                : dt.textM,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc.visitTypeRevisit,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _visitType == 'revisit'
                                  ? Colors.white
                                  : dt.textS,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            // FIXED: was '${_revisitDefaultFee.toStringAsFixed(0)} EGP'
                            '${arNumber(_revisitDefaultFee, localeCode)} ${loc.currencyEgp}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _visitType == 'revisit'
                                  ? Colors.white.withOpacity(0.75)
                                  : dt.textM,
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

            // ── Fee ──────────────────────────────────────────────────────────
            // NOTE: this TextField is intentionally left with plain Western
            // digits — it's an editable numeric input parsed via
            // double.tryParse(), which doesn't understand Arabic-Indic
            // digits. Converting it would break saving the fee.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _T.inpOf(
                      context,
                      loc.feeEgpLabel,
                      pre: Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: dt.textM,
                      ),
                      hint: _visitType == 'consultation'
                          ? _consultDefaultFee.toStringAsFixed(0)
                          : _revisitDefaultFee.toStringAsFixed(0),
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
                      color: dt.bgInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dt.divider),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: dt.textS,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Date & Time ──────────────────────────────────────────────────
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: _T.inpOf(
                  context,
                  loc.dateTimeLabel,
                  pre: Icon(Icons.event_rounded, size: 18, color: dt.textM),
                ),
                child: Text(
                  // FIXED: was DateFormat('dd MMM yyyy  •  hh:mm a').format(_date)
                  // with no locale arg — always English month name + Western
                  // digits regardless of app language.
                  arDigits(
                    DateFormat(
                      'dd MMM yyyy  •  hh:mm a',
                      localeCode,
                    ).format(_date),
                    localeCode,
                  ),
                  style: TextStyle(fontSize: 13, color: dt.textH),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Reason ───────────────────────────────────────────────────────
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: _T.inpOf(context, loc.reasonNotesOptional),
            ),
            const SizedBox(height: 14),

            // ── Urgent toggle ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _urgent = !_urgent),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _urgent ? _T.urgentBg : dt.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _urgent ? _T.urgent.withOpacity(0.4) : dt.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: _urgent ? _T.urgent : dt.textM,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      loc.markAsUrgent,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _urgent ? _T.urgent : dt.textS,
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

            // ── Paid toggle ──────────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _isPaid = !_isPaid),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isPaid ? _T.successBg : dt.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPaid ? _T.success.withOpacity(0.4) : dt.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_rounded,
                      color: _isPaid ? _T.success : dt.textM,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      loc.markAsPaid,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isPaid ? _T.success : dt.textS,
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

            // ── Save button ──────────────────────────────────────────────────
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
                            ? loc.saveChanges
                            : loc.bookAppointment,
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

// ── Patient Search Field ──────────────────────────────────────────────────────

class DoctorPatientSearchField extends StatefulWidget {
  final List<Map<String, dynamic>> patients;
  final int? selectedId;
  final void Function(int?) onSelected;
  // ── lock field when patient is pre-selected ─────────────────────────────
  final bool locked;

  const DoctorPatientSearchField({
    required this.patients,
    required this.selectedId,
    required this.onSelected,
    this.locked = false,
    Key? key,
  }) : super(key: key);

  @override
  State<DoctorPatientSearchField> createState() =>
      _DoctorPatientSearchFieldState();
}

class _DoctorPatientSearchFieldState extends State<DoctorPatientSearchField> {
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
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          // Read-only when a patient was pre-selected
          readOnly: widget.locked,
          decoration: _T.inpOf(
            context,
            loc.searchPatientNameFull,
            pre: Icon(Icons.person_search_rounded, size: 18, color: dt.textM),
            suf: (!widget.locked && _ctrl.text.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: _clear,
                  )
                : null,
          ),
          onChanged: widget.locked ? null : _search,
        ),

        // ── Selected chip ────────────────────────────────────────────────────
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
                    style: TextStyle(fontSize: 11, color: dt.textS),
                  ),
              ],
            ),
          ),

        // ── Dropdown results ─────────────────────────────────────────────────
        if (_showResults)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: dt.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dt.divider),
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
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      loc.noPatientsFoundShort,
                      style: TextStyle(fontSize: 13, color: dt.textS),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: dt.divider),
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
                              DoctorAvatar(name: name, size: 34),
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
                                        color: dt.textH,
                                      ),
                                    ),
                                    if (phone.isNotEmpty || nid.isNotEmpty)
                                      Text(
                                        [phone, nid]
                                            .where((s) => s.isNotEmpty)
                                            .join('  •  '),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: dt.textS,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: dt.textM,
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
