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
  // 'consultation' | 'revisit' — the two fixed business categories
  String _visitCategory = 'consultation';
  // True once category is resolved from name/ID data.
  // When false, _loadAndApplyFeeDefaults() attempts fee-based inference.
  bool _visitCategoryResolved = false;
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _time = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );
  final _feeCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _isPaid = false;
  bool _isUrgent = false;
  bool _saving = false;
  bool _patientError = false;
  bool _dateError = false;
  // Fallback fee defaults — loaded from local prefs, used only when no API fee
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

  // ── Category helpers ─────────────────────────────────────────────────────

  // Returns true if a type name maps to the revisit category
  bool _isRevisitName(String name) {
    final n = name.toLowerCase();
    return n.contains('revisit') || n.contains('follow');
  }

  // Finds the best API/fallback type for a given business category.
  Map<String, dynamic>? _typeForCategory(String category) {
    // Pass 1 — explicit English name match.
    for (final t in _effectiveTypes) {
      final n = (t['name'] ?? '').toString().toLowerCase();
      if (category == 'revisit') {
        if (n.contains('revisit') || n.contains('follow')) return t;
      } else {
        if (n.contains('consult') || n.contains('initial')) return t;
      }
    }
    // Pass 2 (consultation only) — fall back to the first type that is not
    // classified as revisit. This mirrors the logic in saveFees(), which
    // applies consultFee to every non-revisit type, so a type with an Arabic
    // name (e.g. "كشف") is still found and its backend default_fee is used.
    if (category != 'revisit') {
      return _effectiveTypes
          .where((t) => !_isRevisitName((t['name'] ?? '').toString()))
          .firstOrNull;
    }
    return null;
  }

  // Returns the authoritative fee for a category:
  //   1st priority — API type's default_fee (set by doctor in backend)
  //   2nd priority — locally saved doctor prefs
  double _defaultFeeForCategory(String category) {
    final t = _typeForCategory(category);
    if (t != null) {
      final f = double.tryParse((t['default_fee'] ?? '').toString());
      if (f != null && f > 0) return f;
    }
    return category == 'revisit' ? _revisitDefaultFee : _consultDefaultFee;
  }

  @override
  void initState() {
    super.initState();
    _loadAndApplyFeeDefaults();

    final e = widget.existing;

    if (e != null) {
      // ── Editing an existing appointment ───────────────────────────────────
      final pid = (e['patient_id'] ?? e['patient']?['id'] ?? '').toString();
      _selPatient = widget.patients
          .where((p) => p['id'].toString() == pid)
          .firstOrNull;

      // ── 3-layer visit category resolution ────────────────────────────────
      // Guard: use 'is Map' to avoid NoSuchMethodError if appointment_type
      // is returned as a raw integer instead of a nested object.
      final tid = (e['appointment_type_id'] ??
              (e['appointment_type'] is Map
                  ? e['appointment_type']['id']
                  : null) ??
              '')
          .toString();

      // Layer 1 & 2: ID match (most reliable) then stored name
      final byId =
          _effectiveTypes.where((t) => t['id'].toString() == tid).firstOrNull;
      final storedName = (e['appointment_type_name'] ??
              (e['appointment_type'] is Map
                  ? e['appointment_type']['name']
                  : null) ??
              '')
          .toString();
      final resolvedName =
          byId != null ? (byId['name'] ?? '').toString() : storedName;
      _visitCategory = _isRevisitName(resolvedName) ? 'revisit' : 'consultation';

      _selType =
          byId ??
          _typeForCategory(_visitCategory) ??
          (_effectiveTypes.isNotEmpty ? _effectiveTypes.first : null);

      // Layer 3 (fee-based) runs later in _loadAndApplyFeeDefaults when prefs
      // are available. Mark resolved only if we had actual name/ID data.
      _visitCategoryResolved = byId != null || storedName.isNotEmpty;

      try {
        final dt = DateTime.parse(e['start_time'].toString()).toLocal();
        _date = dt;
        _time = TimeOfDay.fromDateTime(dt);
      } catch (_) {}

      _isPaid = e['is_paid'] == true;
      _isUrgent = e['is_urgent'] == true;
      // Always use the appointment's stored fee on edit — never override it
      _feeCtrl.text = (e['fee'] ?? '0').toString();
      _reasonCtrl.text = e['reason'] ?? '';
    } else {
      // ── New appointment ───────────────────────────────────────────────────
      if (widget.preSelectedPatient != null) {
        _selPatient = widget.preSelectedPatient;
      }
      _visitCategory = 'consultation';
      _selType = _typeForCategory('consultation')
          ?? (_effectiveTypes.isNotEmpty ? _effectiveTypes.first : null);
      _visitCategoryResolved = true; // new appointments always start at default
      // Fee is set after _loadAndApplyFeeDefaults() resolves to get prefs
    }
  }

  Future<void> _loadAndApplyFeeDefaults() async {
    final fees = await SettingsService.loadFeeDefaults();
    if (!mounted) return;

    // Derive the best fee values from all available sources.
    // Priority: API appointment-type default_fee > locally saved prefs.
    // When the API provides a value we also write it back to local prefs so
    // the assistant's device stays in sync for future offline/fallback uses.
    double consultFee = fees['consultation']!;
    double revisitFee = fees['revisit']!;

    debugPrint(
      '💵 feeDefaults → localPrefs: consult=$consultFee  revisit=$revisitFee',
    );
    debugPrint(
      '💵 feeDefaults → effectiveTypes count=${_effectiveTypes.length}  '
      '(from API: ${widget.appointmentTypes.length})',
    );
    for (final t in _effectiveTypes) {
      debugPrint(
        '  type="${t["name"]}"  default_fee=${t["default_fee"]}',
      );
    }

    for (final t in _effectiveTypes) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final f = double.tryParse((t['default_fee'] ?? '').toString());
      if (f == null || f <= 0) continue;
      if (name.contains('revisit') || name.contains('follow')) {
        revisitFee = f;
      } else {
        consultFee = f;
      }
    }

    debugPrint(
      '💵 feeDefaults → resolved: consult=$consultFee  revisit=$revisitFee  '
      'category=$_visitCategory',
    );

    if (!mounted) return;
    setState(() {
      _consultDefaultFee = consultFee;
      _revisitDefaultFee = revisitFee;

      if (widget.existing == null) {
        // New appointment: set fee from best available source
        //   1. API type's default_fee  2. locally saved prefs
        _feeCtrl.text =
            _defaultFeeForCategory(_visitCategory).toStringAsFixed(0);
      } else if (!_visitCategoryResolved) {
        // Layer 3 — fee-based inference (last resort).
        // Runs only when name/ID resolution found nothing, meaning the
        // backend stored no usable type data for this appointment.
        final storedFee =
            double.tryParse((widget.existing!['fee'] ?? '0').toString()) ?? 0;
        if (storedFee > 0) {
          // Prefer API type default_fee (doctor-configured, cross-device)
          for (final t in _effectiveTypes) {
            final typeFee =
                double.tryParse((t['default_fee'] ?? '').toString()) ?? 0;
            if (typeFee > 0 && (typeFee - storedFee).abs() < 0.01) {
              _visitCategory =
                  _isRevisitName((t['name'] ?? '').toString())
                  ? 'revisit'
                  : 'consultation';
              _selType = t;
              _visitCategoryResolved = true;
              break;
            }
          }
          // Fall back to locally saved defaults
          if (!_visitCategoryResolved) {
            if ((storedFee - _revisitDefaultFee).abs() < 0.01) {
              _visitCategory = 'revisit';
              _selType ??= _typeForCategory('revisit');
              _visitCategoryResolved = true;
            } else if ((storedFee - _consultDefaultFee).abs() < 0.01) {
              _visitCategory = 'consultation';
              _selType ??= _typeForCategory('consultation');
              _visitCategoryResolved = true;
            }
          }
        }
      }
    });
    debugPrint(
      '💵 feeDefaults → fee field set to "${_feeCtrl.text}"  '
      'category=$_visitCategory',
    );
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  // ── In-sheet SnackBar ────────────────────────────────────────────────────────
  // Uses this form's own context (not widget.snack, which is bound to the
  // parent page's context) so the message renders inside the bottom sheet
  // instead of queuing on the page underneath, where it would stay hidden
  // until the sheet closes.
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
      _snack(loc.selectedTimeInPast, err: true);
      return;
    }

    setState(() {
      _date = picked;
      _time = t;
      _dateChanged = true;
      _dateError = false;
    });
  }

  // ── Save ────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;

    if (_selPatient == null) {
      setState(() => _patientError = true);
      _snack(loc.pleaseSelectPatient, err: true);
      return;
    }

    final isNew = widget.existing == null;
    final dt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (isNew || _dateChanged) {
      if (dt.isBefore(DateTime.now())) {
        setState(() => _dateError = true);
        _snack(loc.appointmentTimeMustBeFuture, err: true);
        return;
      }
    }

    final fee = double.tryParse(_feeCtrl.text.trim()) ?? 0.0;
    if (fee <= 0) {
      _snack(loc.errInvalidFeeAmount, err: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final patientId =
          int.tryParse((_selPatient!['id'] ?? '').toString()) ??
          _selPatient!['id'];
      final typeId = _selType != null
          ? int.tryParse((_selType!['id'] ?? '').toString())
          : null;

      final data = {
        'patient_id': patientId,
        if (widget.activeDoctorId != null) 'doctor_id': widget.activeDoctorId!,
        if (typeId != null && widget.appointmentTypes.isNotEmpty)
          'appointment_type_id': typeId,
        'appointment_type_name':
            _visitCategory == 'revisit' ? 'Revisit' : 'Consultation',
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
      _snack(AssistantViewModel.extractError(e), err: true);
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
              error: _patientError,
              onSelected: (p) => setState(() {
                _selPatient = p;
                _patientError = false;
              }),
            ),
            const SizedBox(height: 14),

            // ── Visit Type — always two fixed categories ─────────────────
            Text(
              loc.visitType,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: at.textS,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _VisitTypeCard(
                    icon: Icons.medical_services_rounded,
                    label: loc.visitTypeConsultation,
                    price: arDigits(
                      '${_defaultFeeForCategory('consultation').toStringAsFixed(0)} ${loc.currencyEgp}',
                      lc,
                    ),
                    selected: _visitCategory == 'consultation',
                    onTap: () {
                      final newFee = _defaultFeeForCategory('consultation');
                      setState(() {
                        _visitCategory = 'consultation';
                        _selType =
                            _typeForCategory('consultation') ?? _selType;
                        _feeCtrl.text = newFee.toStringAsFixed(0);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VisitTypeCard(
                    icon: Icons.refresh_rounded,
                    label: loc.visitTypeRevisit,
                    price: arDigits(
                      '${_defaultFeeForCategory('revisit').toStringAsFixed(0)} ${loc.currencyEgp}',
                      lc,
                    ),
                    selected: _visitCategory == 'revisit',
                    onTap: () {
                      final newFee = _defaultFeeForCategory('revisit');
                      setState(() {
                        _visitCategory = 'revisit';
                        _selType = _typeForCategory('revisit') ?? _selType;
                        _feeCtrl.text = newFee.toStringAsFixed(0);
                      });
                    },
                  ),
                ),
              ],
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
                  error: _dateError,
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

  /// When true, shows a red border (validation failed — no patient selected).
  final bool error;

  const _AssistantPatientSearchField({
    required this.patients,
    required this.patName,
    required this.selectedPatient,
    required this.onSelected,
    this.locked = false,
    this.error = false,
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
            error: widget.error,
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
