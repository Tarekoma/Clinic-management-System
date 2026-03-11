// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/prescription_tab.dart
//
// Tab 1 — Prescription builder.
//
// Displays:  Add Medicine form · Prescription item list
//
// Pure StatelessWidget — no local state.  All controllers and the rx list
// are owned by consultation_page.dart and passed in via constructor.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/widgets/doctor/doctor_consultation_widgets.dart';

typedef _T = DoctorTheme;

class PrescriptionTab extends StatelessWidget {
  // ── Medicine input controllers (owned by parent State) ────────────────────
  final TextEditingController medNameCtrl;
  final TextEditingController medDoseCtrl;
  final TextEditingController medFreqCtrl;
  final TextEditingController medDurCtrl;

  // ── Current prescription list snapshot ───────────────────────────────────
  final List<Map<String, String>> rx;

  // ── Callbacks ────────────────────────────────────────────────────────────
  final VoidCallback onAddRx;
  final void Function(int index) onRemoveRx;

  const PrescriptionTab({
    required this.medNameCtrl,
    required this.medDoseCtrl,
    required this.medFreqCtrl,
    required this.medDurCtrl,
    required this.rx,
    required this.onAddRx,
    required this.onRemoveRx,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Add Medicine form ──────────────────────────────────────────────
          DoctorConsultCard(
            title: 'Add Medicine',
            icon: Icons.medication_rounded,
            child: Column(
              children: [
                // Name + Dose row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: medNameCtrl,
                        decoration: _T.inp('Medicine Name'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: medDoseCtrl,
                        decoration: _T.inp('Dose'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Frequency + Duration row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: medFreqCtrl,
                        decoration: _T.inp('Frequency (e.g. 3x/day)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: medDurCtrl,
                        decoration: _T.inp('Duration (e.g. 7 days)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Add button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: onAddRx,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add to Prescription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Prescription list ──────────────────────────────────────────────
          if (rx.isNotEmpty) ...[
            DoctorSecHead(title: 'Prescription (${rx.length})'),
            const SizedBox(height: 10),
            ...rx.asMap().entries.map(
                  (e) => DoctorRxItem(
                    index: e.key + 1,
                    med: e.value,
                    onRemove: () => onRemoveRx(e.key),
                  ),
                ),
          ] else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: _T.card(),
              child: const Center(
                child: Text(
                  'No medicines added yet.\nUse the form above to build the prescription.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _T.textS),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
