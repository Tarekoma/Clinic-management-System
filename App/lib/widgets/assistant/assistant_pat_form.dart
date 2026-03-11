// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/assistant/assistant_pat_form.dart
//
// Extracted from the original _PatForm / _PatFormState.
//
// Architecture change (only):
//   BEFORE  →  _save() called ApiService.createPatient / updatePatient directly
//   AFTER   →  _save() calls widget.onSubmit(data, existingId: id)
//              The caller (AssistantPatientsPage) passes
//              vm.createOrUpdatePatient as the callback.
//
// Every line of build() and visual structure is unchanged.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/viewmodels/assistant_viewmodel.dart';

typedef _T = AssistantTheme;

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class AssistantPatForm extends StatefulWidget {
  final Map<String, dynamic>? existing;

  /// Called after a successful save so the list refreshes.
  final Future<void> Function() onSaved;

  /// Show a SnackBar from the parent view.
  final void Function(String, {bool err}) snack;

  /// Maps to AssistantViewModel.createOrUpdatePatient.
  final Future<void> Function(Map<String, dynamic> data, {int? existingId})
  onSubmit;

  const AssistantPatForm({
    this.existing,
    required this.onSaved,
    required this.snack,
    required this.onSubmit,
    Key? key,
  }) : super(key: key);

  @override
  State<AssistantPatForm> createState() => _AssistantPatFormState();
}

class _AssistantPatFormState extends State<AssistantPatForm> {
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

  // ── Save (delegates to ViewModel via onSubmit callback) ─────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'first_name': _fn.text.trim(),
      'last_name': _ln.text.trim(),
      'phone': _ph.text.trim(),
      'gender': _gender.toUpperCase(),
      if (_em.text.trim().isNotEmpty) 'email': _em.text.trim(),
      if (_nid.text.trim().isNotEmpty) 'national_id': _nid.text.trim(),
      if (_adr.text.trim().isNotEmpty) 'address': _adr.text.trim(),
      if (_dob != null) 'date_of_birth': DateFormat('yyyy-MM-dd').format(_dob!),
      if (_diseases.isNotEmpty) 'chronic_disease': _diseases.join(', '),
    };
    try {
      final existingId = widget.existing != null
          ? int.tryParse(widget.existing!['id'].toString())
          : null;
      await widget.onSubmit(data, existingId: existingId);
      widget.snack(
        widget.existing != null
            ? 'Patient updated successfully'
            : 'Patient added successfully',
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
            16,
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

              // ── Name row ─────────────────────────────────────────────────
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

              // ── Phone ─────────────────────────────────────────────────────
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

              // ── Email ─────────────────────────────────────────────────────
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

              // ── National ID ───────────────────────────────────────────────
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

              // ── Address ───────────────────────────────────────────────────
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

              // ── Gender toggle ─────────────────────────────────────────────
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

              // ── Date of birth ─────────────────────────────────────────────
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

              // ── Chronic diseases ──────────────────────────────────────────
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

              // ── Save button ───────────────────────────────────────────────
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
              // ── Safe-area gap below button ──────────────────────────────  ← ADD HERE
              SizedBox(
                height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GENDER BUTTON  (private to this file — mirrors original _GBtn)
// ══════════════════════════════════════════════════════════════════════════════

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
