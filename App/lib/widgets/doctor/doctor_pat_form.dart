// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_pat_form.dart
// Localized via AppLocalizations.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

const List<String> kChronicDiseases = [
  'Diabetes',
  'Hypertension',
  'Heart Disease',
  'Asthma',
  'Chronic Kidney Disease',
  'Thyroid Disorder',
  'Arthritis',
  'Obesity',
];

// ── Patient Form ──────────────────────────────────────────────────────────────

class DoctorPatForm extends StatefulWidget {
  final Map<String, dynamic>? existing;

  /// Called with the validated form data.
  final Future<void> Function(Map<String, dynamic> data, {int? existingId})
  onSubmit;

  final void Function(String, {bool err}) snack;

  const DoctorPatForm({
    this.existing,
    required this.onSubmit,
    required this.snack,
    Key? key,
  }) : super(key: key);

  @override
  State<DoctorPatForm> createState() => _DoctorPatFormState();
}

class _DoctorPatFormState extends State<DoctorPatForm> {
  final _fn = TextEditingController();
  final _ln = TextEditingController();
  final _ph = TextEditingController();
  final _nid = TextEditingController();
  final _em = TextEditingController();
  final _addr = TextEditingController();
  final _customDiseaseCtrl = TextEditingController();

  String _gender = 'MALE';
  DateTime? _dob;
  bool _saving = false;
  final List<String> _selectedDiseases = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _fn.text = e['first_name'] ?? '';
      _ln.text = e['last_name'] ?? '';
      _ph.text = e['phone'] ?? '';
      _nid.text = e['national_id'] ?? '';
      _em.text = e['email'] ?? '';
      _addr.text = e['address'] ?? '';
      _gender = (e['gender'] ?? 'MALE').toString().toUpperCase();
      try {
        final dob = e['birth_date'] ?? e['date_of_birth'];
        if (dob != null) _dob = DateTime.parse(dob.toString());
      } catch (_) {}
      // Backend returns patient_conditions (array of condition objects).
      // Extract names where category == CHRONIC.
      final conditions = e['patient_conditions'];
      if (conditions is List) {
        for (final c in conditions) {
          if (c is! Map) continue;
          final cat =
              (c['category'] ?? (c['condition'] as Map?)?['category'] ?? '')
                  .toString()
                  .toUpperCase();
          if (cat != 'CHRONIC') continue;
          final name =
              (c['name'] ?? (c['condition'] as Map?)?['name'] ?? '')
                  .toString();
          if (name.isNotEmpty) _selectedDiseases.add(name);
        }
      }
    }
  }

  @override
  void dispose() {
    _fn.dispose();
    _ln.dispose();
    _ph.dispose();
    _nid.dispose();
    _em.dispose();
    _addr.dispose();
    _customDiseaseCtrl.dispose();
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

  void _addCustomDisease() {
    final name = _customDiseaseCtrl.text.trim();
    if (name.isEmpty) return;
    if (_selectedDiseases.any((s) => s.toLowerCase() == name.toLowerCase())) {
      _customDiseaseCtrl.clear();
      return;
    }
    setState(() {
      _selectedDiseases.add(name);
      _customDiseaseCtrl.clear();
    });
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    if (_fn.text.trim().isEmpty || _ln.text.trim().isEmpty) {
      _snack(loc.firstLastNameRequired, err: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'first_name': _fn.text.trim(),
        'last_name': _ln.text.trim(),
        if (_ph.text.isNotEmpty) 'phone': _ph.text.trim(),
        if (_nid.text.isNotEmpty) 'national_id': _nid.text.trim(),
        if (_em.text.isNotEmpty) 'email': _em.text.trim(),
        if (_addr.text.isNotEmpty) 'address': _addr.text.trim(),
        'gender': _gender,
        if (_dob != null) 'birth_date': DateFormat('yyyy-MM-dd').format(_dob!),
        'chronic_diseases': _selectedDiseases,
      };
      await widget.onSubmit(
        data,
        existingId: widget.existing != null
            ? int.tryParse(widget.existing!['id'].toString())
            : null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack(e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Localized display label for each diagnosis key in [kChronicDiseases].
  String _diseaseLabel(AppLocalizations loc, String disease) {
    switch (disease) {
      case 'Diabetes':
        return loc.diseaseDiabetes;
      case 'Hypertension':
        return loc.diseaseHypertension;
      case 'Heart Disease':
        return loc.diseaseHeartDisease;
      case 'Asthma':
        return loc.diseaseAsthma;
      case 'Chronic Kidney Disease':
        return loc.diseaseCkd;
      case 'Arthritis':
        return loc.diseaseArthritis;
      case 'Thyroid Disorder':
        return 'Thyroid Disorder';
      case 'Obesity':
        return 'Obesity';
      default:
        return disease;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    // ── Safe area bottom accounts for system nav bar + keyboard ─────────────
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        // keyboard height + system nav bar height + extra breathing room
        bottom: bottomInset + bottomPadding + 16,
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
                  color: dt.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.existing != null
                  ? loc.editPatientTitle
                  : loc.addNewPatientTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: dt.textH,
              ),
            ),
            const SizedBox(height: 20),

            // ── Name row ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fn,
                    decoration: _T.inpOf(context, loc.firstNameLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ln,
                    decoration: _T.inpOf(context, loc.lastNameLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Phone ────────────────────────────────────────────────────
            TextField(
              controller: _ph,
              keyboardType: TextInputType.phone,
              decoration: _T.inpOf(
                context,
                loc.phoneNumberLabel,
                pre: Icon(Icons.phone_rounded, size: 18, color: dt.textM),
              ),
            ),
            const SizedBox(height: 14),

            // ── National ID ──────────────────────────────────────────────
            TextField(
              controller: _nid,
              decoration: _T.inpOf(
                context,
                loc.nationalIdLabel,
                pre: Icon(Icons.badge_rounded, size: 18, color: dt.textM),
              ),
            ),
            const SizedBox(height: 14),

            // ── Email ────────────────────────────────────────────────────
            TextField(
              controller: _em,
              keyboardType: TextInputType.emailAddress,
              decoration: _T.inpOf(
                context,
                loc.emailOptionalLabel,
                pre: Icon(Icons.email_outlined, size: 18, color: dt.textM),
              ),
            ),
            const SizedBox(height: 14),

            // ── Address ─────────────────────────────────────────
            TextField(
              controller: _addr,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              minLines: 1,
              decoration: _T.inpOf(
                context,
                loc.addressLabel,
                pre: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: dt.textM,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Gender ───────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  loc.genderColonLabel,
                  style: TextStyle(fontSize: 13, color: dt.textS),
                ),
                const SizedBox(width: 8),
                DoctorGBtn(
                  label: loc.male,
                  val: 'MALE',
                  sel: _gender == 'MALE',
                  onTap: () => setState(() => _gender = 'MALE'),
                ),
                const SizedBox(width: 8),
                DoctorGBtn(
                  label: loc.female,
                  val: 'FEMALE',
                  sel: _gender == 'FEMALE',
                  onTap: () => setState(() => _gender = 'FEMALE'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Date of Birth ────────────────────────────────────────────
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime(1990),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _dob = d);
              },
              child: InputDecorator(
                decoration: _T.inpOf(
                  context,
                  loc.dateOfBirthLabel,
                  pre: Icon(Icons.cake_rounded, size: 18, color: dt.textM),
                ),
                child: Text(
                  _dob != null
                      ? DateFormat('dd MMM yyyy').format(_dob!)
                      : loc.tapToSelect,
                  style: TextStyle(
                    fontSize: 13,
                    color: _dob != null ? dt.textH : dt.textM,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Chronic Diseases ─────────────────────────────────────────
            Row(
              children: [
                Text(
                  loc.chronicDiseases,
                  style: TextStyle(fontSize: 13, color: dt.textS),
                ),
                const SizedBox(width: 6),
                if (_selectedDiseases.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selectedDiseases.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Predefined disease chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kChronicDiseases.map((disease) {
                final selected = _selectedDiseases
                    .any((s) => s.toLowerCase() == disease.toLowerCase());
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedDiseases.removeWhere(
                        (s) => s.toLowerCase() == disease.toLowerCase(),
                      );
                    } else {
                      _selectedDiseases.add(disease);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFF3E5F5) : dt.bgInput,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF6A1B9A).withValues(alpha: 0.5)
                            : dt.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Color(0xFF6A1B9A),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _diseaseLabel(loc, disease),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? const Color(0xFF6A1B9A)
                                : dt.textS,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            // Custom disease chips (names not in the predefined list)
            Builder(
              builder: (_) {
                final custom = _selectedDiseases
                    .where(
                      (s) => !kChronicDiseases.any(
                        (p) => p.toLowerCase() == s.toLowerCase(),
                      ),
                    )
                    .toList();
                if (custom.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: custom.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF6A1B9A).withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6A1B9A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(
                                () => _selectedDiseases.remove(name),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: Color(0xFF6A1B9A),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            // Custom disease entry
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customDiseaseCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _T.inpOf(
                      context,
                      'Add other condition…',
                      pre: Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: dt.textM,
                      ),
                    ),
                    onSubmitted: (_) => _addCustomDisease(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addCustomDisease,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Submit button ────────────────────────────────────────────
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
                            : loc.addPatient,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            // ── Extra safe-area gap below button ────────────────────
            // Ensures the button never sits directly on top of the
            // Android gesture / button navigation bar.
            SizedBox(height: bottomPadding > 0 ? 0 : 12),
          ],
        ),
      ),
    );
  }
}

// ── Gender Button ─────────────────────────────────────────────────────────────

class DoctorGBtn extends StatelessWidget {
  final String label, val;
  final bool sel;
  final VoidCallback onTap;
  const DoctorGBtn({
    required this.label,
    required this.val,
    required this.sel,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? _T.navy : dt.bgInput,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _T.navy : dt.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : dt.textS,
          ),
        ),
      ),
    );
  }
}
