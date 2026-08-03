// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/ai_imaging_review_page.dart
//
// Medical Image upload + doctor review workflow.
//
// Backend response field priority (SKIN vs XRAY differ):
//  Priority 1 — ai_report_raw  : structured Map,   used by SKIN images.
//  Priority 2 — ai_report      : structured Map,   used by XRAY images (XRayReport).
//  Priority 3 — ai_diagnosis   : raw string/JSON,  last-resort fallback.
//
// Workflow:
//  1. POST /medical-images  → extract draft via priority chain (no polling).
//  2. Show editable draft pre-filled with AI data.
//  3. "Confirm Report" stages the doctor's edits locally — it does NOT call
//     the backend. PATCH /medical-images/{id}/review (which triggers PDF +
//     WhatsApp delivery) is deferred until DoctorConsultationPage submits it
//     during "Complete Consultation", so confirming never sends a message by
//     itself and each image is only ever sent once.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';
import 'package:Hakim/widgets/doctor/ai_analysis_result_widget.dart';

typedef _T = DoctorTheme;

enum _Phase { uploading, view, editing, confirmed, error }

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

  _Phase _phase = _Phase.uploading;
  String? _errorMsg;

  int? _imageId;

  // Snapshot of ai_report_raw used to compute the confirm diff.
  Map<String, dynamic> _originalRaw = {};

  // Set once the doctor taps "Confirm Report". Held locally and only sent to
  // the backend (PATCH .../review, which triggers WhatsApp delivery) when the
  // doctor later taps "Complete Consultation" — see DoctorConsultationPage.
  Map<String, dynamic>? _confirmedDiff;

  // ── Form controllers (one per report field) ────────────────────────────────
  final _cImageType = TextEditingController();
  final _cRegion = TextEditingController();
  final _cQuality = TextEditingController();
  final _cFindings = TextEditingController();
  final _cImpressions = TextEditingController();
  final _cDifferentials = TextEditingController();
  final _cRecommendations = TextEditingController();
  final _cUrgency = TextEditingController();
  final _cUrgencyReason = TextEditingController();
  final _cSummary = TextEditingController();
  final _cDoctorNotes = TextEditingController();

  CancelToken _cancelToken = CancelToken();

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
    _upload();
  }

  @override
  void dispose() {
    _cancelToken.cancel('Page disposed');
    _pulseCtrl.dispose();
    _cImageType.dispose();
    _cRegion.dispose();
    _cQuality.dispose();
    _cFindings.dispose();
    _cImpressions.dispose();
    _cDifferentials.dispose();
    _cRecommendations.dispose();
    _cUrgency.dispose();
    _cUrgencyReason.dispose();
    _cSummary.dispose();
    _cDoctorNotes.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _listToText(dynamic v) {
    if (v == null) return '';
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .join('\n');
    }
    return v.toString().trim();
  }

  List<String> _textToList(String text) => text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _fillForm(Map<String, dynamic> raw) {
    _cImageType.text =
        (raw['imageType'] ?? raw['image_type'] ?? '').toString();
    _cRegion.text = (raw['region'] ?? raw['body_region'] ?? '').toString();
    _cQuality.text = (raw['quality'] ?? '').toString();
    _cFindings.text = _listToText(raw['findings']);
    _cImpressions.text =
        _listToText(raw['impressions'] ?? raw['impression']);
    _cDifferentials.text =
        _listToText(raw['differentials'] ?? raw['differential_diagnoses']);
    _cRecommendations.text = _listToText(raw['recommendations']);
    _cUrgency.text = (raw['urgency'] ?? '').toString();
    _cUrgencyReason.text = (raw['urgency_reason'] ?? '').toString();
    _cSummary.text =
        (raw['summary'] ?? raw['clinical_summary'] ?? '').toString();
  }

  // ── Draft data extraction (handles SKIN, XRAY, and text fallback) ───────────

  /// Tries three sources in priority order and returns the first non-empty result.
  ///   1. ai_report_raw  — structured Map, returned by SKIN images.
  ///   2. ai_report      — structured Map (XRayReport), returned by XRAY images.
  ///   3. ai_diagnosis   — raw string / JSON, last-resort fallback.
  static Map<String, dynamic> _extractDraftData(Map<String, dynamic> data) {
    // ── Priority 1: ai_report_raw as Map ─────────────────────────────────────
    final raw1 = data['ai_report_raw'];
    if (raw1 is Map && raw1.isNotEmpty) {
      return Map<String, dynamic>.from(raw1);
    }

    // ── Priority 2: ai_report_raw as JSON string ──────────────────────────────
    if (raw1 is String && raw1.trim().isNotEmpty) {
      final t = raw1.trim();
      if (t.startsWith('{')) {
        try {
          final decoded = jsonDecode(t);
          if (decoded is Map && decoded.isNotEmpty) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
      if (!_isAiErrorPlaceholder(t)) return _parseTextDiagnosis(t);
    }

    // ── Priority 3: ai_report as Map (XRAY — backend parses XRayReport) ──────
    final raw2 = data['ai_report'];
    if (raw2 is Map && raw2.isNotEmpty) {
      return Map<String, dynamic>.from(raw2);
    }

    // ── Priority 4: ai_diagnosis string (text or JSON fallback) ──────────────
    final raw3 = data['ai_diagnosis'];
    if (raw3 is String && raw3.trim().isNotEmpty) {
      final t = raw3.trim();
      if (_isAiErrorPlaceholder(t)) return {};
      if (t.startsWith('{')) {
        try {
          final decoded = jsonDecode(t);
          if (decoded is Map && decoded.isNotEmpty) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
      return _parseTextDiagnosis(t);
    }

    return {};
  }

  static bool _isAiErrorPlaceholder(String t) =>
      t.startsWith('[AI') || t.startsWith('[Lab') || t.startsWith('[Error');

  /// Parses a structured text report (section headings + bullet lines) into a
  /// field map matching the same keys used by structured JSON responses.
  static Map<String, dynamic> _parseTextDiagnosis(String text) {
    final result = <String, dynamic>{};

    // Metadata lines: "Image Type: X-Ray", "Region: Chest", etc.
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
          result['imageType'] =
              val.replaceAll(RegExp(r'[^\w\s]'), '').trim();
          break;
        case 'region':
          result['region'] = val;
          break;
        case 'image quality':
          result['quality'] =
              val.replaceAll(RegExp(r'[^\w\s]'), '').trim();
          break;
        case 'urgency':
          result['urgency'] =
              val.replaceAll(RegExp(r'[^\w\s]'), '').trim();
          break;
      }
    }

    // Section blocks: ALL-CAPS header followed by indented lines.
    final sections = <String, List<String>>{};
    String? currentSection;
    final divider = RegExp(r'^[\s─\-─]{6,}$', multiLine: true);

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (divider.hasMatch(line) || line.contains('══')) continue;

      final isHeader = line.isNotEmpty &&
          line == line.toUpperCase() &&
          !line.contains(':') &&
          line.length > 3 &&
          RegExp(r'[A-Z]').hasMatch(line);

      if (isHeader) {
        currentSection = line;
        sections.putIfAbsent(currentSection, () => []);
      } else if (currentSection != null && line.isNotEmpty) {
        sections[currentSection]!.add(line);
      }
    }

    for (final entry in sections.entries) {
      final title = entry.key;
      final lines = entry.value.where((l) => l.isNotEmpty).toList();
      if (lines.isEmpty) continue;

      if (title.contains('SUMMARY')) {
        result['summary'] = lines.join(' ');
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
        result['differentials'] = lines
            .map((l) => l.replaceAll(RegExp(r'^\s*[-•Δ]\s*'), '').trim())
            .where((l) => l.isNotEmpty)
            .toList();
      } else if (title.contains('RECOMMENDATION')) {
        result['recommendations'] = lines
            .map((l) => l.replaceFirst(RegExp(r'^\s*→\s*'), '').trim())
            .where((l) => l.isNotEmpty)
            .toList();
      }
    }

    // If nothing was extracted but there is text, at least populate summary.
    if (result.isEmpty && text.trim().isNotEmpty) {
      result['summary'] = text.trim();
    }

    debugPrint(
      '📋 _parseTextDiagnosis: extracted keys=${result.keys.toList()}',
    );
    return result;
  }

  // Returns only the fields that the doctor actually changed.
  Map<String, dynamic> _buildDiff() {
    final diff = <String, dynamic>{};
    final orig = _originalRaw;

    void checkStr(
      String sendKey,
      TextEditingController ctrl,
      List<String> origKeys,
    ) {
      final current = ctrl.text.trim();
      String original = '';
      for (final k in origKeys) {
        if (orig.containsKey(k)) {
          original = (orig[k] ?? '').toString().trim();
          break;
        }
      }
      if (current != original) diff[sendKey] = current;
    }

    void checkList(
      String sendKey,
      TextEditingController ctrl,
      List<String> origKeys,
    ) {
      final current = _textToList(ctrl.text);
      dynamic origVal;
      for (final k in origKeys) {
        if (orig.containsKey(k)) {
          origVal = orig[k];
          break;
        }
      }
      final List<String> original;
      if (origVal is List) {
        original = origVal
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (origVal != null && origVal.toString().trim().isNotEmpty) {
        original = [origVal.toString().trim()];
      } else {
        original = [];
      }
      if (current.join('\n') != original.join('\n')) diff[sendKey] = current;
    }

    checkStr('imageType', _cImageType, ['imageType', 'image_type']);
    checkStr('region', _cRegion, ['region', 'body_region']);
    checkStr('quality', _cQuality, ['quality']);
    checkList('findings', _cFindings, ['findings']);
    checkList('impressions', _cImpressions, ['impressions', 'impression']);
    checkList('differentials', _cDifferentials,
        ['differentials', 'differential_diagnoses']);
    checkList('recommendations', _cRecommendations, ['recommendations']);
    checkStr('urgency', _cUrgency, ['urgency']);
    checkStr('urgency_reason', _cUrgencyReason, ['urgency_reason']);
    checkStr('summary', _cSummary, ['summary', 'clinical_summary']);

    return diff;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _upload() async {
    if (!mounted) return;

    if (!_cancelToken.isCancelled) _cancelToken.cancel();
    _cancelToken = CancelToken();
    final myToken = _cancelToken;

    setState(() {
      _phase = _Phase.uploading;
      _errorMsg = null;
    });

    try {
      final visitId = await widget.ensureVisit();
      if (myToken.isCancelled || !mounted) return;

      final uploaded = await ApiService.uploadMedicalImage(
        imageFile: widget.imageFile,
        visitId: visitId,
        imageType: widget.imageType,
        description: '${widget.imageType} medical image analysis',
        cancelToken: myToken,
      );
      if (myToken.isCancelled || !mounted) return;

      debugPrint('🖼️ Upload response keys: ${uploaded.keys.toList()}');

      _imageId = int.tryParse((uploaded['id'] ?? 0).toString()) ?? 0;
      if (_imageId == null || _imageId! <= 0) {
        if (mounted) {
          setState(() {
            _phase = _Phase.error;
            _errorMsg =
                'Upload did not return a valid image ID. Please retry.';
          });
        }
        return;
      }

      // Extract draft AI data using the priority chain:
      //   ai_report_raw (SKIN) → ai_report (XRAY) → ai_diagnosis (fallback).
      debugPrint(
        '🖼️ ai_report_raw=${uploaded['ai_report_raw'].runtimeType}  '
        'ai_report=${uploaded['ai_report'].runtimeType}  '
        'ai_diagnosis=${uploaded['ai_diagnosis'].runtimeType}',
      );
      final Map<String, dynamic> raw = _extractDraftData(uploaded);

      _originalRaw = Map<String, dynamic>.from(raw);
      _fillForm(raw);
      _cDoctorNotes.text =
          (uploaded['doctor_notes'] ?? '').toString();

      if (mounted) setState(() => _phase = _Phase.view);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMsg =
            'Upload failed: ${DoctorViewModel.extractError(e)}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMsg = 'Upload failed: ${DoctorViewModel.extractError(e)}';
      });
    }
  }

  // Stages the doctor's review locally — does NOT call the backend. The
  // PATCH .../review call (which triggers WhatsApp delivery) is deferred
  // until "Complete Consultation", so confirming a report here never sends
  // a message to the patient by itself.
  void _confirmReport() {
    if (_imageId == null || !mounted) return;

    final diff = _buildDiff();
    debugPrint(
      '📋 Confirm Report (staged locally) — image #$_imageId '
      '— changed fields: ${diff.keys.toList()}',
    );

    setState(() {
      _confirmedDiff = diff;
      _phase = _Phase.confirmed;
      _errorMsg = null;
    });
  }

  /// Result handed back to DoctorConsultationPage once confirmed: the image
  /// ID plus the doctor's edits, to be submitted via reviewMedicalImage when
  /// the consultation is completed.
  Map<String, dynamic>? get _confirmedPayload =>
      _confirmedDiff == null || _imageId == null
          ? null
          : {'imageId': _imageId, 'diff': _confirmedDiff};

  Future<void> _saveDoctorNotes() async {
    if (_imageId == null) return;
    try {
      await ApiService.updateMedicalImageNotes(
        _imageId!,
        _cDoctorNotes.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor notes saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save notes: ${DoctorViewModel.extractError(e)}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onPop() {
    switch (_phase) {
      case _Phase.confirmed:
        Navigator.of(context).pop(_confirmedPayload);
        return;
      case _Phase.view:
      case _Phase.editing:
      case _Phase.error:
        Navigator.of(context).pop(null);
        return;
      case _Phase.uploading:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Cancel Upload?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: const Text(
                'The image is still uploading. Leave anyway?',
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
                    _cancelToken.cancel('User left');
                    Navigator.pop(ctx);
                    Future.delayed(Duration.zero, () {
                      if (mounted) Navigator.of(context).pop(null);
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
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _dt = Theme.of(context).extension<DoctorThemeData>()!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, __) {
        if (didPop) return;
        _onPop();
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
            if (_phase == _Phase.view || _phase == _Phase.confirmed)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _phase == _Phase.confirmed
                      ? () => Navigator.of(context).pop(_confirmedPayload)
                      : _confirmReport,
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
            ..._buildBody(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    switch (_phase) {
      case _Phase.uploading:
        return [
          _buildLoadingCard(
            'Uploading and analyzing image...',
            'The AI is processing your medical image.\nThis usually takes just a moment.',
          ),
        ];
      case _Phase.view:
        return [
          _buildAnalysisCompleteBanner(),
          const SizedBox(height: 16),
          if (_errorMsg != null) ...[
            _buildInlineError(),
            const SizedBox(height: 12),
          ],
          _buildDraftReportCard(),
          const SizedBox(height: 16),
          _buildDoctorNotesSection(),
          const SizedBox(height: 20),
          _buildViewActions(),
        ];
      case _Phase.editing:
        return [
          if (_errorMsg != null) ...[
            _buildInlineError(),
            const SizedBox(height: 12),
          ],
          _buildDraftBanner(),
          const SizedBox(height: 16),
          _buildEditableForm(),
          const SizedBox(height: 16),
          _buildDoctorNotesSection(),
          const SizedBox(height: 20),
          _buildConfirmButton(),
        ];
      case _Phase.confirmed:
        return [
          _buildConfirmedBanner(),
          const SizedBox(height: 16),
          _buildConfirmedReport(),
          const SizedBox(height: 20),
          _buildDoneButton(),
        ];
      case _Phase.error:
        return [_buildErrorCard()];
    }
  }

  // ── Image preview (unchanged from original design) ─────────────────────────

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  // ── Loading card (upload & confirming phases) ──────────────────────────────

  Widget _buildLoadingCard(String message, String subMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: _dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.navy.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
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
          const SizedBox(height: 24),
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: _T.navy,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _dt.textH,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _dt.textS, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Inline error shown during review phase ─────────────────────────────────

  Widget _buildInlineError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _T.urgent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.urgent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: _T.urgent.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMsg!,
              style: TextStyle(
                fontSize: 12,
                color: _T.urgent.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Analysis complete banner (teal — shown in view phase) ────────────────────

  Widget _buildAnalysisCompleteBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _T.teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.teal.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: _T.teal, size: 18),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
                Text(
                  'Review findings before closing',
                  style: TextStyle(
                    fontSize: 11,
                    color: _T.teal.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Draft report card (view phase — AIAnalysisResultWidget with Edit hook) ──

  Widget _buildDraftReportCard() {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _originalRaw.isNotEmpty
            ? AIAnalysisResultWidget(
                result: _originalRaw,
                onEditTap: () => setState(() {
                  _phase = _Phase.editing;
                  _errorMsg = null;
                }),
              )
            : _buildEmptyDraftFallback(),
      ),
    );
  }

  // Shown when the AI returned no structured data — lets the doctor fill manually.
  Widget _buildEmptyDraftFallback() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(
            Icons.image_search_rounded,
            size: 44,
            color: _dt.textM.withValues(alpha: 0.28),
          ),
          const SizedBox(height: 12),
          Text(
            'No AI Analysis Available',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _dt.textH.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The AI could not produce a structured report for this image.\n'
            'You can fill in the fields manually.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _dt.textS, height: 1.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _phase = _Phase.editing),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text(
                'Fill in Manually',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _T.navy,
                side: const BorderSide(color: _T.navy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── View phase action buttons ──────────────────────────────────────────────

  Widget _buildViewActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () =>
                setState(() {
                  _phase = _Phase.editing;
                  _errorMsg = null;
                }),
            icon: const Icon(Icons.rate_review_rounded, size: 20),
            label: const Text(
              'Review & Edit Report',
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
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(null),
            style: OutlinedButton.styleFrom(
              foregroundColor: _dt.textS,
              side: BorderSide(color: _dt.textS.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Done Without Confirming'),
          ),
        ),
      ],
    );
  }

  // ── Draft banner (orange — awaiting review) ────────────────────────────────

  Widget _buildDraftBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            color: Color(0xFFE65100),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Generated Draft Report — Awaiting Doctor Review',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and edit the fields below if needed, '
                  'then tap Confirm Report to finalize.',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFFBF360C).withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirmed banner (green — doctor approved) ─────────────────────────────

  Widget _buildConfirmedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF2E7D32),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doctor Approved Final Report',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This report has been reviewed and approved.',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Editable report form ───────────────────────────────────────────────────

  Widget _buildEditableForm() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _T.teal.withValues(alpha: 0.12),
                  _T.navy.withValues(alpha: 0.06),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: _T.teal.withValues(alpha: 0.15)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: _T.teal, size: 18),
                SizedBox(width: 8),
                Text(
                  'AI Draft Report — Edit as Needed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.teal,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Information ────────────────────────────────────
                _sectionTitle(
                  Icons.info_outline_rounded,
                  'Image Information',
                  _T.navy,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _formField(
                        'Image Type',
                        _cImageType,
                        hint: 'e.g. XRAY, SKIN',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _formField(
                        'Region',
                        _cRegion,
                        hint: 'e.g. Chest, Arm',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _formField(
                  'Image Quality',
                  _cQuality,
                  hint: 'e.g. Good, Fair, Poor',
                ),

                const SizedBox(height: 18),
                _sectionTitle(
                  Icons.search_rounded,
                  'Findings',
                  const Color(0xFF1565C0),
                ),
                const SizedBox(height: 6),
                _formField(
                  'Findings',
                  _cFindings,
                  maxLines: 5,
                  hint: 'Enter each finding on a new line',
                ),

                const SizedBox(height: 18),
                _sectionTitle(
                  Icons.psychology_rounded,
                  'Impressions',
                  _T.navy,
                ),
                const SizedBox(height: 6),
                _formField(
                  'Impressions',
                  _cImpressions,
                  maxLines: 4,
                  hint: 'Enter each impression on a new line',
                ),

                const SizedBox(height: 18),
                _sectionTitle(
                  Icons.balance_rounded,
                  'Differential Diagnoses',
                  const Color(0xFF6A1B9A),
                ),
                const SizedBox(height: 6),
                _formField(
                  'Differentials',
                  _cDifferentials,
                  maxLines: 4,
                  hint: 'e.g. Pneumonia (~70%)\nCOPD (~20%)',
                ),

                const SizedBox(height: 18),
                _sectionTitle(
                  Icons.lightbulb_outline_rounded,
                  'Recommendations',
                  _T.teal,
                ),
                const SizedBox(height: 6),
                _formField(
                  'Recommendations',
                  _cRecommendations,
                  maxLines: 4,
                  hint: 'Enter each recommendation on a new line',
                ),

                const SizedBox(height: 18),
                _sectionTitle(
                  Icons.warning_amber_rounded,
                  'Urgency & Summary',
                  const Color(0xFFE65100),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _formField(
                        'Urgency',
                        _cUrgency,
                        hint: 'e.g. Routine, Urgent',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _formField(
                        'Urgency Reason',
                        _cUrgencyReason,
                        hint: 'Brief reason',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _formField(
                  'Clinical Summary',
                  _cSummary,
                  maxLines: 4,
                  hint: 'Overall clinical summary',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _formField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _dt.textS,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 12.5,
            color: _dt.textH,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _dt.textS.withValues(alpha: 0.45),
              fontSize: 11.5,
            ),
            filled: true,
            fillColor: _dt.bgInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: _dt.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: _dt.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: _T.teal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Doctor Notes (separate — PATCH /medical-images/{id}) ──────────────────

  Widget _buildDoctorNotesSection() {
    return Container(
      decoration: BoxDecoration(
        color: _dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dt.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: _T.navy.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: _dt.divider)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  color: _dt.textM,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Doctor Notes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _dt.textH,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _saveDoctorNotes,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _T.navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_outlined, size: 12, color: _T.navy),
                        SizedBox(width: 4),
                        Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _T.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _cDoctorNotes,
              maxLines: 4,
              style: TextStyle(
                fontSize: 12.5,
                color: _dt.textH,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText:
                    'Add personal clinical notes, observations, or additional context...',
                hintStyle: TextStyle(
                  color: _dt.textS.withValues(alpha: 0.45),
                  fontSize: 11.5,
                ),
                filled: true,
                fillColor: _dt.bgInput,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: _dt.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: _dt.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: _T.navy, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirm button ─────────────────────────────────────────────────────────

  Widget _buildConfirmButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _confirmReport,
            icon: const Icon(Icons.verified_rounded, size: 20),
            label: const Text(
              'Confirm Report',
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
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () => setState(() => _phase = _Phase.view),
            style: OutlinedButton.styleFrom(
              foregroundColor: _dt.textS,
              side: BorderSide(color: _dt.textS.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Back to View'),
          ),
        ),
      ],
    );
  }

  // ── Confirmed report display ───────────────────────────────────────────────

  Widget _buildConfirmedReport() {
    // Built locally from the original draft + the doctor's staged edits —
    // there is no server response to read from since the backend isn't
    // contacted until "Complete Consultation".
    final reportData = Map<String, dynamic>.from(_originalRaw)
      ..addAll(_confirmedDiff ?? {});

    return Container(
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
      child: AIAnalysisResultWidget(result: reportData, isLoading: false),
    );
  }

  // ── Done button ────────────────────────────────────────────────────────────

  Widget _buildDoneButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(_confirmedPayload),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text(
              'Done',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(_confirmedPayload),
            style: OutlinedButton.styleFrom(
              foregroundColor: _dt.textS,
              side: BorderSide(color: _dt.textS.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  // ── Full-page error card ───────────────────────────────────────────────────

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
            'Upload Failed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _dt.textH,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMsg ?? 'An unexpected error occurred.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _dt.textS,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _upload,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry Upload',
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
              onPressed: () => Navigator.of(context).pop(null),
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
}
