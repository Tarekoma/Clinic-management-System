// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/voice_tab.dart
//
// Voice Report tab — premium layout matching AI Imaging quality.
// VoiceRecordingWidget is self-contained (own card + states); this tab
// simply places it above the Doctor Notes card.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/widgets/doctor/voice_recording_widget.dart';
import 'package:flutter/material.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

class VoiceTab extends StatelessWidget {
  final TextEditingController notesCtrl;

  // Kept for API compatibility with the parent consultation page.
  // VoiceRecordingWidget manages its own processing UI internally.
  final bool transcribing;

  final Future<void> Function(String path) onTranscribe;

  const VoiceTab({
    required this.notesCtrl,
    required this.transcribing,
    required this.onTranscribe,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Voice recording (self-contained premium card) ──────────────────
          VoiceRecordingWidget(onRecordingComplete: onTranscribe),

          const SizedBox(height: 14),

          // ── Doctor's Notes ─────────────────────────────────────────────────
          _buildDoctorNotesCard(dt, loc),
        ],
      ),
    );
  }

  Widget _buildDoctorNotesCard(DoctorThemeData dt, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dt.divider),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: _T.navy.withValues(alpha: 0.04),
                border: Border(bottom: BorderSide(color: dt.divider)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: dt.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    loc.doctorNotesLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dt.textH,
                    ),
                  ),
                ],
              ),
            ),
            // Notes field
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: notesCtrl,
                maxLines: 8,
                style: TextStyle(
                  fontSize: 13,
                  color: dt.textH,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: loc.additionalNotesHint,
                  hintStyle: TextStyle(
                    color: dt.textS.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: dt.bgInput,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: dt.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: dt.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _T.navy, width: 1.5),
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
