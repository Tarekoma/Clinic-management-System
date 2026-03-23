// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/notes_tab.dart
//
// Tab 2 — Notes & Voice.
//
// Displays:  Voice Report (recording widget + transcription status)
//            Medical Images (camera / gallery pick + AI scan)
//            Doctor's Notes (free-text)
//
// Pure StatelessWidget.  The notesCtrl is owned by the parent State so
// transcript/image text appended here via onTranscribe/onPickImage is
// immediately reflected in the TextField.  The parent holds the
// _transcribing flag and rebuilds this widget when it changes.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/widgets/doctor/voice_recording_widget.dart';
import 'package:flutter/material.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_consultation_widgets.dart';

typedef _T = DoctorTheme;

class voiceTab extends StatelessWidget {
  // ── Controller (owned by parent State) ───────────────────────────────────
  final TextEditingController notesCtrl;

  // ── State snapshot ────────────────────────────────────────────────────────
  final bool transcribing;

  // ── Callbacks ────────────────────────────────────────────────────────────

  /// Called with the local file path when voice recording completes.
  /// The parent appends the transcript to [notesCtrl] and resets the flag.
  final Future<void> Function(String path) onTranscribe;

  const voiceTab({
    required this.notesCtrl,
    required this.transcribing,
    required this.onTranscribe,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Voice Report ───────────────────────────────────────────────────
          DoctorConsultCard(
            title: 'Voice Report',
            icon: Icons.mic_rounded,
            child: Column(
              children: [
                VoiceRecordingWidget(onRecordingComplete: onTranscribe),
                if (transcribing) ...[
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _T.navy,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Transcribing audio...',
                        style: TextStyle(fontSize: 12, color: _T.textS),
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
            title: "Doctor's Notes",
            icon: Icons.edit_note_rounded,
            child: TextField(
              controller: notesCtrl,
              maxLines: 8,
              decoration: _T.inp('Additional notes, follow-up instructions...'),
            ),
          ),
        ],
      ),
    );
  }
}
