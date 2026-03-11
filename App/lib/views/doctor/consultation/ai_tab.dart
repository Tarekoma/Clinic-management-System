// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/ai_tab.dart
//
// Tab 3 — AI Clinical Assistant.
//
// Displays:  Gradient banner
//            "Analyze & Suggest" button (with loading state)
//            Suggestions card (when aiResult is non-null)
//              └─ "Apply to Diagnosis" action → navigates back to Clinical tab
//            Tips card
//
// Pure StatelessWidget.  All async logic lives in consultation_page.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

class AITab extends StatelessWidget {
  // ── State snapshot ────────────────────────────────────────────────────────
  final bool    aiLoading;
  final String? aiResult;

  // ── Callbacks ────────────────────────────────────────────────────────────

  /// Triggers AI analysis — implemented in consultation_page.dart.
  final Future<void> Function() onRunAI;

  /// Copies [suggestion] into the diagnosis controller and switches to
  /// the Clinical tab — implemented in consultation_page.dart.
  final void Function(String suggestion) onApplyToDiagnosis;

  const AITab({
    required this.aiLoading,
    required this.aiResult,
    required this.onRunAI,
    required this.onApplyToDiagnosis,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient banner ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _T.gradCard(),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Clinical Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Based on symptoms & findings',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Analyze button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: aiLoading ? null : onRunAI,
              icon: aiLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.psychology_rounded, size: 18),
              label: Text(aiLoading ? 'Analyzing...' : 'Analyze & Suggest'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),

          // ── Suggestions card (conditional) ────────────────────────────────
          if (aiResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _T.tealPale,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: _T.teal.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded,
                          color: _T.teal, size: 15),
                      const SizedBox(width: 6),
                      const Text(
                        'Suggestions',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _T.teal,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      // "Apply to Diagnosis" — calls back into consultation_page
                      TextButton(
                        onPressed: () => onApplyToDiagnosis(aiResult!),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Apply to Diagnosis',
                          style: TextStyle(
                            color: _T.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    aiResult!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _T.textH,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Tips card ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _T.bgInput,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'For better suggestions:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _T.textS,
                  ),
                ),
                const SizedBox(height: 8),
                for (final hint in const [
                  '• Fill in the Chief Complaint',
                  '• Add patient symptoms',
                  '• Enter examination findings',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      hint,
                      style: const TextStyle(fontSize: 12, color: _T.textS),
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
