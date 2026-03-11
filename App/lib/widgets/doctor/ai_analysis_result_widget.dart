// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/ai_analysis_result_widget.dart
//
// Reusable result card for AI Imaging tab.
//
// Currently shows a "No analysis yet" placeholder.
// When the backend AI service is ready, pass the result string via [result]
// and the card will render the analysis output.
//
// Pure StatelessWidget — no local state.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

class AIAnalysisResultWidget extends StatelessWidget {
  /// The AI analysis result text. Pass null to show the placeholder.
  final String? result;

  /// Whether the AI analysis is currently running.
  final bool isLoading;

  const AIAnalysisResultWidget({this.result, this.isLoading = false, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.navy.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading
          ? _buildLoading()
          : result != null
          ? _buildResult(result!)
          : _buildPlaceholder(),
    );
  }

  // ── Loading state ──────────────────────────────────────────────────────────

  Widget _buildLoading() => const Column(
    children: [
      SizedBox(height: 8),
      CircularProgressIndicator(color: _T.navy, strokeWidth: 2),
      SizedBox(height: 12),
      Text(
        'Running AI analysis...',
        style: TextStyle(fontSize: 13, color: _T.textS),
      ),
      SizedBox(height: 8),
    ],
  );

  // ── Placeholder (no analysis yet) ─────────────────────────────────────────

  Widget _buildPlaceholder() => Column(
    children: [
      Icon(
        Icons.image_search_rounded,
        size: 40,
        color: _T.textM.withOpacity(0.35),
      ),
      const SizedBox(height: 10),
      Text(
        'No analysis yet',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _T.textH.withOpacity(0.45),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Upload an image and tap "Analyze Image"\nto see AI results here.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: _T.textS.withOpacity(0.7),
          height: 1.5,
        ),
      ),
    ],
  );

  // ── Result display ─────────────────────────────────────────────────────────

  Widget _buildResult(String text) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.biotech_rounded, color: _T.teal, size: 16),
          const SizedBox(width: 6),
          const Text(
            'AI Analysis Result',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _T.teal,
              fontSize: 13,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        text,
        style: const TextStyle(fontSize: 13, color: _T.textH, height: 1.55),
      ),
    ],
  );
}
