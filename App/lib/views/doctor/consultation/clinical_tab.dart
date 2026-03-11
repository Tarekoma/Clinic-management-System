// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/clinical_tab.dart
//
// Tab 0 — Clinical examination.
//
// Displays:  Chief Complaint · Symptoms · Physical Examination · Diagnosis
//
// This widget is a pure StatelessWidget.  All mutable state lives in
// ConsultationPage's State class and is passed in via constructor parameters.
// Mutations are performed via the provided callback functions, which call
// setState() on the parent — keeping this widget free of any local state.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_consultation_widgets.dart';

typedef _T = DoctorTheme;

class ClinicalTab extends StatelessWidget {
  // ── Controllers (owned by parent State) ───────────────────────────────────
  final TextEditingController complaintCtrl;
  final TextEditingController diagCtrl;
  final TextEditingController examCtrl;
  final TextEditingController symptomCtrl;

  // ── Read-only data snapshot (rebuilt on every setState in parent) ──────────
  final List<String> symptoms;

  // ── Callbacks ────────────────────────────────────────────────────────────
  final void Function(String) onAddSymptom;
  final void Function(String) onRemoveSymptom;

  /// Called when "AI Diagnosis Suggestions" is tapped — navigates to AI tab
  /// and triggers the analysis. Implemented in consultation_page.dart.
  final VoidCallback onGoToAI;

  const ClinicalTab({
    required this.complaintCtrl,
    required this.diagCtrl,
    required this.examCtrl,
    required this.symptomCtrl,
    required this.symptoms,
    required this.onAddSymptom,
    required this.onRemoveSymptom,
    required this.onGoToAI,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Chief Complaint ────────────────────────────────────────────────
          DoctorConsultCard(
            title: 'Chief Complaint',
            icon: Icons.chat_bubble_outline_rounded,
            child: TextField(
              controller: complaintCtrl,
              maxLines: 2,
              decoration: _T.inp('What brings the patient in today?'),
            ),
          ),

          const SizedBox(height: 14),

          // ── Symptoms ───────────────────────────────────────────────────────
          DoctorConsultCard(
            title: 'Symptoms',
            icon: Icons.sick_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: symptomCtrl,
                        decoration: _T.inp('Add symptom...'),
                        onSubmitted: onAddSymptom,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => onAddSymptom(symptomCtrl.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _T.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
                // Symptom chips
                if (symptoms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: symptoms
                        .map((s) => DoctorSympChip(
                              label: s,
                              onRemove: () => onRemoveSymptom(s),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Physical Examination ───────────────────────────────────────────
          DoctorConsultCard(
            title: 'Physical Examination',
            icon: Icons.monitor_heart_outlined,
            child: TextField(
              controller: examCtrl,
              maxLines: 4,
              decoration: _T.inp('Vitals, examination findings...'),
            ),
          ),

          const SizedBox(height: 14),

          // ── Diagnosis ──────────────────────────────────────────────────────
          DoctorConsultCard(
            title: 'Diagnosis',
            icon: Icons.psychology_outlined,
            child: Column(
              children: [
                TextField(
                  controller: diagCtrl,
                  maxLines: 3,
                  decoration: _T.inp('Enter diagnosis or ICD code...'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onGoToAI,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('AI Diagnosis Suggestions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _T.navy,
                      side: const BorderSide(color: _T.navy),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
