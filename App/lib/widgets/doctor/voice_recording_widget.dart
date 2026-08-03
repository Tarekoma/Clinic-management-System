// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/voice_recording_widget.dart
//
// Premium voice recording widget — self-contained card with gradient header.
// States: idle → recording (active/paused) → processing (multi-step animation).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

class _Step {
  final String label;
  final IconData icon;
  const _Step(this.label, this.icon);
}

class VoiceRecordingWidget extends StatefulWidget {
  final Future<void> Function(String audioPath) onRecordingComplete;

  const VoiceRecordingWidget({super.key, required this.onRecordingComplete});

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isProcessing = false;

  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  // ── Animations ──────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _waveCtrl;
  late AnimationController _stepFadeCtrl;
  late Animation<double> _stepFadeAnim;

  // ── Processing steps ────────────────────────────────────────────────────────
  static const _steps = [
    _Step('Recording saved', Icons.save_alt_rounded),
    _Step('Uploading audio…', Icons.cloud_upload_outlined),
    _Step('Transcribing audio…', Icons.mic_none_rounded),
    _Step('Analyzing medical findings…', Icons.psychology_outlined),
    _Step('Generating structured report…', Icons.description_outlined),
  ];
  int _stepIndex = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _stepFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _stepFadeAnim = CurvedAnimation(parent: _stepFadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepTimer?.cancel();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _stepFadeCtrl.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ── Step cycling ─────────────────────────────────────────────────────────────

  void _startStepCycle() {
    _stepIndex = 0;
    _stepFadeCtrl.forward();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      _stepFadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _stepIndex = (_stepIndex + 1).clamp(0, _steps.length - 1);
        });
        _stepFadeCtrl.forward();
      });
    });
  }

  void _stopStepCycle() {
    _stepTimer?.cancel();
    _stepTimer = null;
    _stepFadeCtrl.reset();
  }

  // ── Permission ────────────────────────────────────────────────────────────────

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // ── Recording actions ─────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    try {
      if (!await _checkPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone permission is required'),
              backgroundColor: _T.urgent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${dir.path}/voice_report_$ts.m4a';

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

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) setState(() => _recordingDuration = Duration(seconds: t.tick));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: _T.urgent,
            behavior: SnackBarBehavior.floating,
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
            content: Text('Error pausing: $e'),
            backgroundColor: _T.urgent,
            behavior: SnackBarBehavior.floating,
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
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) {
          setState(
            () => _recordingDuration = Duration(seconds: startTick + t.tick),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resuming: $e'),
            backgroundColor: _T.urgent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _timer?.cancel();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingDuration = Duration.zero;
      });
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          if (mounted) {
            setState(() => _isProcessing = true);
            _startStepCycle();
          }
          try {
            await widget.onRecordingComplete(path);
          } finally {
            if (mounted) {
              _stopStepCycle();
              setState(() => _isProcessing = false);
            }
          }
        } else {
          throw Exception('Recording file not found');
        }
      }
    } catch (e) {
      if (mounted) {
        _stopStepCycle();
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: _T.urgent,
            behavior: SnackBarBehavior.floating,
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
        final f = File(_recordingPath!);
        if (await f.exists()) await f.delete();
      }
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingDuration = Duration.zero;
        _recordingPath = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling: $e'),
            backgroundColor: _T.urgent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    return Container(
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dt.divider),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildHeader(dt),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: _isProcessing
                  ? _buildProcessing(dt)
                  : _isRecording
                  ? _buildRecording(dt)
                  : _buildIdle(dt),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card header ────────────────────────────────────────────────────────────

  Widget _buildHeader(DoctorThemeData dt) {
    final String statusLabel = _isProcessing
        ? 'Processing…'
        : _isRecording
        ? (_isPaused ? 'Paused' : '● ${_formatDuration(_recordingDuration)}')
        : 'Ready';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        gradient: _T.gNavy,
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          const Text(
            'Voice Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Idle state ─────────────────────────────────────────────────────────────

  Widget _buildIdle(DoctorThemeData dt) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _T.navy.withValues(alpha: 0.07),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _T.navy.withValues(alpha: 0.14),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.mic_rounded, size: 40, color: _T.navy),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Start Voice Recording',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: dt.textH,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Dictate your clinical notes. AI will transcribe\nand structure the medical report automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: dt.textS, height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.mic_rounded, size: 20),
            label: const Text(
              'Start Recording',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // ── Recording state ────────────────────────────────────────────────────────

  Widget _buildRecording(DoctorThemeData dt) {
    final recColor = _isPaused ? _T.warning : _T.urgent;
    return Column(
      children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: recColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: recColor.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: recColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isPaused ? 'PAUSED' : 'RECORDING',
                style: TextStyle(
                  color: recColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Timer display
        Text(
          _formatDuration(_recordingDuration),
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w300,
            color: _isPaused ? dt.textS : _T.urgent,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),

        // Waveform
        _isPaused ? _buildPausedBars(dt) : _buildLiveBars(),
        const SizedBox(height: 24),

        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlBtn(
              icon: Icons.close_rounded,
              label: 'Cancel',
              color: _T.urgent,
              onTap: _cancelRecording,
            ),
            _controlBtn(
              icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              label: _isPaused ? 'Resume' : 'Pause',
              color: _T.warning,
              onTap: _isPaused ? _resumeRecording : _pauseRecording,
            ),
            _controlBtn(
              icon: Icons.stop_rounded,
              label: 'Save',
              color: _T.success,
              onTap: _stopRecording,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _isPaused
              ? 'Paused — tap Resume to continue'
              : 'Recording your consultation — tap Stop when done',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: dt.textS, height: 1.5),
        ),
      ],
    );
  }

  // Animated sine-wave bars while recording
  Widget _buildLiveBars() {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, __) {
        final t = _waveCtrl.value;
        return SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(22, (i) {
              final phase = i / 22 * 2 * pi;
              final raw = (sin(t * 2 * pi + phase) + 1) / 2;
              final height = raw * 42 + 6;
              return Container(
                width: 3.5,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _T.urgent.withValues(alpha: 0.55 + raw * 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // Static bars when paused
  Widget _buildPausedBars(DoctorThemeData dt) {
    const heights = [10.0, 22.0, 14.0, 30.0, 10.0, 18.0, 28.0, 12.0, 24.0, 8.0, 20.0];
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(22, (i) {
          final h = heights[i % heights.length];
          return Container(
            width: 3.5,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: dt.textM.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Processing state ───────────────────────────────────────────────────────

  Widget _buildProcessing(DoctorThemeData dt) {
    final step = _steps[_stepIndex];
    return Column(
      children: [
        // Pulsing icon that changes with each step
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _T.navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, size: 36, color: _T.navy),
            ),
          ),
        ),
        const SizedBox(height: 20),

        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: _T.navy,
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 16),

        // Step progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_steps.length, (i) {
            final active = i == _stepIndex;
            final done = i < _stepIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: (active || done)
                    ? _T.navy
                    : _T.navy.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Step label with fade transition
        FadeTransition(
          opacity: _stepFadeAnim,
          child: Column(
            children: [
              Text(
                step.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: dt.textH,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AI is actively working on your report…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: dt.textS,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
