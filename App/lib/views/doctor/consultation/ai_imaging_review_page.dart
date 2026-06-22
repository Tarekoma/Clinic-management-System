// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/ai_imaging_review_page.dart
//
// Dedicated screen for medical image AI analysis.
// Navigate here immediately after image upload; analysis runs in background
// while showing a professional loading state.  Results are displayed using
// the same AIAnalysisResultWidget used elsewhere in the consultation flow.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';
import 'package:Hakim/widgets/doctor/ai_analysis_result_widget.dart';

typedef _T = DoctorTheme;

class AIImagingReviewPage extends StatefulWidget {
  final File imageFile;
  final String imageType;

  /// Returns the visit-id, creating one first if necessary.
  final Future<int> Function() ensureVisit;

  const AIImagingReviewPage({
    required this.imageFile,
    required this.imageType,
    required this.ensureVisit,
    super.key,
  });

  @override
  State<AIImagingReviewPage> createState() => _AIImagingReviewPageState();
}

class _AIImagingReviewPageState extends State<AIImagingReviewPage>
    with SingleTickerProviderStateMixin {
  late DoctorThemeData _dt;

  bool _loading = true;
  Map<String, dynamic>? _result;
  String? _errorMsg;

  // Persisted across retry attempts so we never re-upload the same image.
  int? _uploadedImageId;
  int? _cachedVisitId;

  // Cancels any in-flight Dio request when the page is disposed or a new
  // analysis is started, preventing stale responses from updating UI state.
  CancelToken _cancelToken = CancelToken();

  // Cycling status messages shown while waiting
  static const _msgs = [
    'Uploading medical image...',
    'Analyzing medical image...',
    'Generating AI report...',
    'Please wait while the analysis is being completed.',
  ];
  // When retrying (image already uploaded), skip straight to analysis messages.
  static const _retryMsgs = [
    'Checking analysis status...',
    'Analyzing medical image...',
    'Generating AI report...',
    'Please wait while the analysis is being completed.',
  ];
  int _msgIndex = 0;
  Timer? _msgTimer;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _runAnalysis();
  }

  @override
  void dispose() {
    _cancelToken.cancel('Page disposed');
    _msgTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Analysis ───────────────────────────────────────────────────────────────

  Future<void> _runAnalysis() async {
    if (!mounted) return;

    // Cancel any in-flight previous analysis and start with a fresh token so
    // stale Dio connections are released before opening new ones.
    if (!_cancelToken.isCancelled) _cancelToken.cancel('New analysis started');
    _cancelToken = CancelToken();
    final myToken = _cancelToken;

    final isRetry = _uploadedImageId != null;

    setState(() {
      _loading = true;
      _errorMsg = null;
      _result = null;
      _msgIndex = 0;
    });

    // Restart the message cycler using the appropriate message list.
    _msgTimer?.cancel();
    final msgs = isRetry ? _retryMsgs : _msgs;
    _msgTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _loading) {
        setState(() => _msgIndex = (_msgIndex + 1) % msgs.length);
      }
    });

    try {
      final visitId = _cachedVisitId ?? await widget.ensureVisit();
      if (myToken.isCancelled || !mounted) return;
      _cachedVisitId = visitId;

      Map<String, dynamic> result;

      if (isRetry) {
        // ── Retry path: skip re-upload, poll the existing image ────────────
        debugPrint('🔁 Retry: polling existing imageId=$_uploadedImageId…');
        result = {};
      } else {
        // ── First run: upload the image ────────────────────────────────────
        final uploaded = await ApiService.uploadMedicalImage(
          imageFile: widget.imageFile,
          visitId: visitId,
          imageType: widget.imageType,
          description: '${widget.imageType} medical image analysis',
          cancelToken: myToken,
        );
        if (myToken.isCancelled || !mounted) return;
        debugPrint('🖼️ Upload response: $uploaded');
        _uploadedImageId = int.tryParse((uploaded['id'] ?? 0).toString()) ?? 0;
        result = Map<String, dynamic>.from(uploaded);

        // If the upload response already contains the ai_report, use it now.
        if (_uploadedImageId! > 0 && uploaded['ai_report'] != null) {
          return _finish(result);
        }
      }

      // ── Poll until ai_report appears ───────────────────────────────────
      final imageId = _uploadedImageId ?? 0;
      if (imageId <= 0) {
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMsg = 'Upload did not return a valid image ID. Please retry.';
          });
        }
        return;
      }

      debugPrint('⏳ Polling getVisitImages — visitId=$visitId imageId=$imageId');
      const maxAttempts = 36; // 3 minutes total (36 × 5 s)
      const interval = Duration(seconds: 5);
      // After this many attempts (~60 s) also accept any image on the visit
      // with an ai_report — some backends cap processing to one image per visit.
      const fallbackAfter = 12;
      bool resolved = false;

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        await Future.delayed(interval);
        if (myToken.isCancelled || !mounted) return;

        try {
          final images = await ApiService.getVisitImages(
            visitId,
            cancelToken: myToken,
          );
          if (myToken.isCancelled || !mounted) return;
          debugPrint('🔄 Poll $attempt/$maxAttempts — ${images.length} image(s)');

          // Primary: exact match on the uploaded imageId
          for (final img in images) {
            if (img['id']?.toString() == imageId.toString() &&
                img['ai_report'] != null) {
              result = Map<String, dynamic>.from(img as Map);
              resolved = true;
              debugPrint('✅ ai_report for imageId=$imageId on attempt $attempt');
              break;
            }
          }

          // Fallback (after ~60 s): accept any image with ai_report on this
          // visit — handles backends that reuse / cap one report per visit.
          if (!resolved && attempt >= fallbackAfter) {
            for (final img in images) {
              if (img['ai_report'] != null) {
                result = Map<String, dynamic>.from(img as Map);
                resolved = true;
                debugPrint(
                  '✅ Fallback: ai_report from image ${img['id']} '
                  'on attempt $attempt',
                );
                break;
              }
            }
          }

          if (resolved) break;
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) return;
          debugPrint('⚠️ Poll $attempt failed: $e');
        } catch (e) {
          debugPrint('⚠️ Poll $attempt failed: $e');
        }

        if (attempt == maxAttempts) {
          if (mounted) {
            setState(() {
              _loading = false;
              _errorMsg =
                  'The AI is still processing. Tap "Retry" to check again — '
                  'your image has already been uploaded.';
            });
          }
          return;
        }
      }

      if (myToken.isCancelled || !mounted) return;
      _finish(result);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = 'Analysis failed: ${DoctorViewModel.extractError(e)}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = 'Analysis failed: ${DoctorViewModel.extractError(e)}';
      });
    }
  }

  void _finish(Map<String, dynamic> result) {
    if (!mounted) return;
    final aiData = _extractAiImageData(result);
    if (!aiData.containsKey('imageType') && !aiData.containsKey('image_type')) {
      final t = result['image_type'] ?? result['imageType'];
      if (t != null) aiData['image_type'] = t;
    }
    setState(() {
      _loading = false;
      if (aiData.isNotEmpty) {
        _result = aiData;
      } else {
        _errorMsg = 'Could not extract analysis results. Please retry.';
      }
    });
  }

  // ── AI data extraction ─────────────────────────────────────────────────────

  static const _aiKeys = {
    'imageType',
    'image_type',
    'region',
    'quality',
    'findings',
    'impressions',
    'differentials',
    'recommendations',
    'urgency',
    'clinical_summary',
    'summary',
  };

  static Map<String, dynamic> _extractAiImageData(
    Map<String, dynamic> result,
  ) {
    int score(Map<String, dynamic> m) =>
        m.keys.where(_aiKeys.contains).length;

    Map<String, dynamic> toMap(dynamic v) {
      if (v is String && v.trim().isNotEmpty) return _parseTextReport(v);
      return v is Map ? Map<String, dynamic>.from(v) : {};
    }

    final candidates = [
      toMap(result['ai_report']),
      toMap(result['report']),
      toMap(result['ai_analysis']),
      toMap(result['analysis']),
      toMap(result['data']),
      toMap(result['image']),
      toMap(result['result']),
      result,
    ];

    for (final c in candidates) {
      if (score(c) >= 2) {
        debugPrint('✅ _extractAiImageData: matched — keys: ${c.keys.toList()}');
        return c;
      }
    }

    debugPrint('⚠️ _extractAiImageData: no candidate matched, using root.');
    return result;
  }

  static Map<String, dynamic> _parseTextReport(String text) {
    final result = <String, dynamic>{};

    final metaRx = RegExp(
      r'^\s*(Image Type|Region|Image Quality|Urgency)\s*:\s*(.+)$',
      multiLine: true,
      caseSensitive: false,
    );
    for (final m in metaRx.allMatches(text)) {
      final key = m.group(1)!.trim().toLowerCase();
      final val = m.group(2)!.trim();
      switch (key) {
        case 'image type':
          result['image_type'] =
              val.replaceAll(RegExp(r'[^\w\s]'), '').trim();
          break;
        case 'region':
          result['region'] = val;
          break;
        case 'image quality':
          result['quality'] = val.replaceAll(RegExp(r'[^\w\s]'), '').trim();
          break;
        case 'urgency':
          result['urgency'] = val.replaceAll(RegExp(r'[^\w\s]'), '').trim();
          break;
      }
    }

    final divider = RegExp(r'^[\s─\-─]{6,}$', multiLine: true);
    final sections = <String, List<String>>{};
    String? currentSection;

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (divider.hasMatch(line) || line.contains('══')) continue;

      final isHeader =
          line.isNotEmpty &&
          line == line.toUpperCase() &&
          !line.contains(':') &&
          line.length > 3 &&
          RegExp(r'[A-Z]').hasMatch(line);

      if (isHeader) {
        currentSection = line.trim();
        sections.putIfAbsent(currentSection, () => []);
      } else if (currentSection != null && line.isNotEmpty) {
        sections[currentSection]!.add(line);
      }
    }

    for (final entry in sections.entries) {
      final title = entry.key;
      final lines = entry.value.where((l) => l.isNotEmpty).toList();
      if (lines.isEmpty) continue;

      if (title.contains('CLINICAL SUMMARY') || title.contains('SUMMARY')) {
        result['clinical_summary'] = lines.join(' ');
      } else if (title == 'FINDINGS') {
        result['findings'] = lines
            .map((l) => l.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '').trim())
            .where((l) => l.isNotEmpty)
            .toList();
      } else if (title.contains('IMPRESSION')) {
        result['impressions'] = lines
            .map((l) => l.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '').trim())
            .where((l) => l.isNotEmpty)
            .toList();
      } else if (title.contains('DIFFERENTIAL')) {
        final combined = lines.join(' ');
        final parts = combined
            .split(RegExp(r'\|\s*Δ|^Δ'))
            .map((s) => s.replaceAll('Δ', '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
        result['differentials'] = parts;
      } else if (title.contains('RECOMMENDATION')) {
        result['recommendations'] = lines
            .map((l) => l.replaceFirst(RegExp(r'^\s*→\s*'), '').trim())
            .where((l) => l.isNotEmpty)
            .toList();
      }
    }

    debugPrint('📋 _parseTextReport: extracted keys=${result.keys.toList()}');
    return result;
  }

  // ── Confirm leave ──────────────────────────────────────────────────────────

  void _confirmLeave() {
    // onPopInvokedWithResult fires during the navigator's build phase.
    // Calling showDialog() synchronously here triggers a second navigator
    // operation on the same frame → !_debugLocked assertion.
    // Deferring to addPostFrameCallback guarantees the frame is fully built
    // before we push the dialog route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Leave Analysis?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'The AI is still analyzing your image.\n'
            'If you leave now, you can retry from the imaging tab.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Stay',
                style: TextStyle(
                  color: _T.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _cancelToken.cancel('User left analysis');
                Navigator.pop(ctx); // close dialog
                // Defer page-pop to the next event loop so it doesn't
                // overlap with the dialog's dismiss navigation.
                Future.delayed(Duration.zero, () {
                  if (mounted) Navigator.of(context).pop(false);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.urgent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Leave',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _dt = Theme.of(context).extension<DoctorThemeData>()!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, __) {
        if (didPop) return; // pop already committed — don't re-trigger dialog
        if (_loading) {
          _confirmLeave();
        } else {
          Navigator.of(context).pop(_result != null);
        }
      },
      child: Scaffold(
        backgroundColor: _dt.bgPage,
        appBar: AppBar(
          backgroundColor: _T.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'AI Image Analysis',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: [
            if (!_loading && _result != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _buildImagePreview(),
            const SizedBox(height: 20),
            if (_loading) _buildLoadingCard(),
            if (!_loading && _errorMsg != null) _buildErrorCard(),
            if (!_loading && _result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  // ── Image preview ──────────────────────────────────────────────────────────

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        color: _dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dt.divider),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withValues(alpha: 0.07),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: _T.gradCard(),
              child: Row(
                children: [
                  const Icon(
                    Icons.medical_information_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.imageType} Image',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.imageType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Image.file(
              widget.imageFile,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading card ───────────────────────────────────────────────────────────

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: _dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.navy.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          // Pulsing biotech icon
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
                child: const Icon(
                  Icons.biotech_rounded,
                  size: 40,
                  color: _T.navy,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: _T.navy,
              strokeWidth: 2.5,
            ),
          ),

          const SizedBox(height: 20),

          // Cycling status message with crossfade
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              (_uploadedImageId != null ? _retryMsgs : _msgs)[_msgIndex],
              key: ValueKey(_msgIndex),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _dt.textH,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'This may take up to a minute',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _dt.textS),
          ),

          const SizedBox(height: 20),

          // Disclaimer while waiting
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _T.teal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _T.teal.withValues(alpha: 0.20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 15, color: _T.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _uploadedImageId != null
                        ? 'Image already uploaded — waiting for AI to finish processing.'
                        : 'The image has been uploaded. The AI is processing it now.',
                    style: TextStyle(
                      fontSize: 11,
                      color: _T.teal.withValues(alpha: 0.85),
                      height: 1.4,
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

  // ── Error card ─────────────────────────────────────────────────────────────

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _T.urgent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.urgent.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: _T.urgent.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 14),
          Text(
            'Analysis Failed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _dt.textH,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMsg!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _dt.textS, height: 1.5),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _runAnalysis,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry Analysis',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: _dt.textS,
                side: BorderSide(color: _dt.textS.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Go Back'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result card ────────────────────────────────────────────────────────────

  Widget _buildResultCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI badge — same design language as VoiceReportReviewPage
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _T.teal.withValues(alpha: 0.12),
                _T.navy.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.teal.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: _T.teal,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Analysis Complete',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.teal,
                      ),
                    ),
                    Text(
                      'Review findings before closing',
                      style: TextStyle(
                        fontSize: 11,
                        color: _dt.textS.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Result widget in a card
        Container(
          decoration: BoxDecoration(
            color: _dt.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _dt.divider),
            boxShadow: [
              BoxShadow(
                color: _T.navy.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AIAnalysisResultWidget(result: _result, isLoading: false),
        ),

        const SizedBox(height: 24),

        // Done button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text(
              'Done',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

        const SizedBox(height: 10),

        // Discard / go back
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _dt.textS,
              side: BorderSide(color: _dt.textS.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Go Back'),
          ),
        ),
      ],
    );
  }
}
