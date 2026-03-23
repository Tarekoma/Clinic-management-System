import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecordingWidget extends StatefulWidget {
  // ── FIX 1 ─────────────────────────────────────────────────────────────────
  // Changed from `Function(String audioPath)` → `Future<void> Function(String)`
  // so _stopRecording can await it.  Without this the transcription Future was
  // fire-and-forgotten: errors were silently swallowed and no navigation occurred.
  final Future<void> Function(String audioPath) onRecordingComplete;

  const VoiceRecordingWidget({Key? key, required this.onRecordingComplete})
    : super(key: key);

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;

  // ── FIX 2 ─────────────────────────────────────────────────────────────────
  // New flag: true while the parent is transcribing + navigating.
  // Prevents the widget from resetting to idle and showing "Recording saved"
  // before the review screen has opened.
  bool _isProcessing = false;

  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> _startRecording() async {
    try {
      if (!await _checkPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voice_report_$timestamp.m4a';
      _recordingPath = '${directory.path}/$fileName';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = Duration(seconds: timer.tick);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() => _isPaused = true);
      _timer?.cancel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pausing recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      setState(() => _isPaused = false);

      final startTick = _recordingDuration.inSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = Duration(seconds: startTick + timer.tick);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resuming recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── FIX 3 ─────────────────────────────────────────────────────────────────
  // _stopRecording now awaits widget.onRecordingComplete(path).
  //
  // Before this fix:
  //   widget.onRecordingComplete(path);   // ← unawaited, Future discarded
  //   showSnackBar('Recording saved');    // ← shown immediately, before transcription
  //
  // After this fix:
  //   setState(_isProcessing = true)      // ← show spinner
  //   await widget.onRecordingComplete(path)  // ← waits for transcription + navigation
  //   setState(_isProcessing = false)     // ← only reached if navigation was cancelled
  //
  // Any exception thrown inside onRecordingComplete (i.e. _onVoiceRecorded in
  // consultation_page.dart) is now caught here and surfaced as a snackbar.
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _timer?.cancel();

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingDuration = Duration.zero; // reset timer display to 00:00
      });

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          // Enter processing state — shows spinner instead of idle UI.
          if (mounted) setState(() => _isProcessing = true);

          try {
            // Awaiting here is the critical fix: the transcription + navigation
            // chain in consultation_page._onVoiceRecorded runs to completion
            // before we reset the widget state.
            await widget.onRecordingComplete(path);
          } finally {
            // Reset processing state whether navigation succeeded or was
            // cancelled (user pressed back from review screen).
            if (mounted) setState(() => _isProcessing = false);
          }
        } else {
          throw Exception('Recording file not found');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();
      _timer?.cancel();

      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingDuration = Duration.zero;
        _recordingPath = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // ── FIX 4 ─────────────────────────────────────────────────────────────
    // Show a dedicated processing state while the parent transcribes the audio.
    // Previously the widget jumped straight back to idle, giving no feedback
    // that work was happening and leaving the user confused.
    if (_isProcessing) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Transcribing audio…',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please wait while AI processes your recording',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isPaused ? Colors.orange : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPaused ? Icons.pause : Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPaused ? 'PAUSED' : 'RECORDING',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Timer
          Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _isRecording ? Colors.red : Colors.grey[600],
            ),
          ),

          const SizedBox(height: 20),

          // Waveform animation
          if (_isRecording && !_isPaused)
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(
                  20,
                  (index) => AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    curve: Curves.easeInOut,
                    width: 3,
                    height: 20 + (index % 3) * 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

          if (_isRecording && !_isPaused) const SizedBox(height: 20),

          // Control buttons
          if (!_isRecording)
            ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic, size: 32),
              label: const Text(
                'Start Recording',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.close, size: 32),
                  color: Colors.red,
                  tooltip: 'Cancel',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                IconButton(
                  onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    size: 32,
                  ),
                  color: Colors.orange,
                  tooltip: _isPaused ? 'Resume' : 'Pause',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                IconButton(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop, size: 32),
                  color: Colors.green,
                  tooltip: 'Stop & Save',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          Text(
            _isRecording
                ? (_isPaused
                      ? 'Recording paused. Tap resume to continue.'
                      : 'Recording... Tap stop when finished.')
                : 'Tap the microphone to start recording your medical report',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
