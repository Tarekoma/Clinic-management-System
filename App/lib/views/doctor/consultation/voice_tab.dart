// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/voice_tab.dart
//
// Tab — Voice Report + Doctor's Notes.
// Localized via AppLocalizations.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/widgets/doctor/voice_recording_widget.dart';
import 'package:flutter/material.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_consultation_widgets.dart';

typedef _T = DoctorTheme;

class VoiceTab extends StatelessWidget {
  // ── Controller (owned by parent State) ───────────────────────────────────
  final TextEditingController notesCtrl;

  // ── State snapshot ────────────────────────────────────────────────────────
  final bool transcribing;

  // ── Callbacks ────────────────────────────────────────────────────────────

  /// Called with the local file path when voice recording completes.
  /// The parent appends the transcript to [notesCtrl] and resets the flag.
  final Future<void> Function(String path) onTranscribe;

  const VoiceTab({
    required this.notesCtrl,
    required this.transcribing,
    required this.onTranscribe,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Voice Report ───────────────────────────────────────────────────
          DoctorConsultCard(
            title: loc.voiceReportTitle,
            icon: Icons.mic_rounded,
            child: Column(
              children: [
                VoiceRecordingWidget(onRecordingComplete: onTranscribe),
                if (transcribing) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _T.navy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        loc.transcribingAudio,
                        style: TextStyle(fontSize: 12, color: dt.textS),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Doctor's Notes ─────────────────────────────────────────────────
          DoctorConsultCard(
            title: loc.doctorNotesLabel,
            icon: Icons.edit_note_rounded,
            child: TextField(
              controller: notesCtrl,
              maxLines: 8,
              decoration: _T.inpOf(context, loc.additionalNotesHint),
            ),
          ),
        ],
      ),
    );
  }
}
