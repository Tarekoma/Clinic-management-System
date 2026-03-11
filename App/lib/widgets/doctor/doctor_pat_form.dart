// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/doctor_pat_form.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

const List<String> kChronicDiseases = [
  'Diabetes',
  'Hypertension',
  'Heart Disease',
  'Asthma',
  'Chronic Kidney Disease',
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
  // ── NEW: address controller ──────────────────────────────────────────────
  final _addr = TextEditingController();

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
      // ── NEW: pre-fill address ────────────────────────────────────────────
      _addr.text = e['address'] ?? '';
      _gender = (e['gender'] ?? 'MALE').toString().toUpperCase();
      try {
        final dob = e['birth_date'] ?? e['date_of_birth'];
        if (dob != null) _dob = DateTime.parse(dob.toString());
      } catch (_) {}
      final saved = e['chronic_diseases'];
      if (saved is List) _selectedDiseases.addAll(saved.cast<String>());
    }
  }

  @override
  void dispose() {
    _fn.dispose();
    _ln.dispose();
    _ph.dispose();
    _nid.dispose();
    _em.dispose();
    _addr.dispose(); // ── NEW ─────────────────────────────────────────────
    super.dispose();
  }

  Future<void> _save() async {
    if (_fn.text.trim().isEmpty || _ln.text.trim().isEmpty) {
      widget.snack('First and last name are required.', err: true);
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
        // ── NEW: include address if provided ────────────────────────────
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
      widget.snack(e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Safe area bottom accounts for system nav bar + keyboard ─────────────
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _T.bgCard,
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
                  child: TextField(
                    controller: _fn,
                    decoration: _T.inp('First Name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ln,
                    decoration: _T.inp('Last Name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Phone ────────────────────────────────────────────────────
            TextField(
              controller: _ph,
              keyboardType: TextInputType.phone,
              decoration: _T.inp(
                'Phone Number',
                pre: const Icon(Icons.phone_rounded, size: 18, color: _T.textM),
              ),
            ),
            const SizedBox(height: 14),

            // ── National ID ──────────────────────────────────────────────
            TextField(
              controller: _nid,
              decoration: _T.inp(
                'National ID',
                pre: const Icon(Icons.badge_rounded, size: 18, color: _T.textM),
              ),
            ),
            const SizedBox(height: 14),

            // ── NEW: Address ─────────────────────────────────────────────
            TextField(
              controller: _addr,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              minLines: 1,
              decoration: _T.inp(
                'Address',
                pre: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: _T.textM,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Gender ───────────────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Gender: ',
                  style: TextStyle(fontSize: 13, color: _T.textS),
                ),
                const SizedBox(width: 8),
                DoctorGBtn(
                  label: 'Male',
                  val: 'MALE',
                  sel: _gender == 'MALE',
                  onTap: () => setState(() => _gender = 'MALE'),
                ),
                const SizedBox(width: 8),
                DoctorGBtn(
                  label: 'Female',
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
                decoration: _T.inp(
                  'Date of Birth',
                  pre: const Icon(
                    Icons.cake_rounded,
                    size: 18,
                    color: _T.textM,
                  ),
                ),
                child: Text(
                  _dob != null
                      ? DateFormat('dd MMM yyyy').format(_dob!)
                      : 'Tap to select',
                  style: TextStyle(
                    fontSize: 13,
                    color: _dob != null ? _T.textH : _T.textM,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Chronic Diseases ─────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Chronic Diseases',
                  style: TextStyle(fontSize: 13, color: _T.textS),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${_selectedDiseases.length}/5)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Cannot add new diseases',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: _T.textM,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kChronicDiseases.map((disease) {
                final selected = _selectedDiseases.contains(disease);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedDiseases.remove(disease);
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
                      color: selected ? const Color(0xFFF3E5F5) : _T.bgInput,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF6A1B9A).withOpacity(0.5)
                            : _T.divider,
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
                          disease,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? const Color(0xFF6A1B9A)
                                : _T.textS,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
                            ? 'Save Changes'
                            : 'Add Patient',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            // ── NEW: Extra safe-area gap below button ────────────────────
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: sel ? _T.navy : _T.bgInput,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? _T.navy : _T.divider),
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
