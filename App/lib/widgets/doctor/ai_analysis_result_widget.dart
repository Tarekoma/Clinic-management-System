import 'package:flutter/material.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

class AIAnalysisResultWidget extends StatefulWidget {
  final Map<String, dynamic>? result;
  final bool isLoading;

  /// When provided, the header Edit button calls this instead of toggling
  /// the internal raw-text editor. Use this to hand off editing to a parent
  /// screen that has a structured form.
  final VoidCallback? onEditTap;

  const AIAnalysisResultWidget({
    this.result,
    this.isLoading = false,
    this.onEditTap,
    Key? key,
  }) : super(key: key);

  @override
  State<AIAnalysisResultWidget> createState() => _AIAnalysisResultWidgetState();
}

class _AIAnalysisResultWidgetState extends State<AIAnalysisResultWidget> {
  late DoctorThemeData _dt; // set in build()
  late AppLocalizations _loc; // set in build()

  bool _isEditing = false;
  late final TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: _mapToEditableText(widget.result));
  }

  @override
  void didUpdateWidget(AIAnalysisResultWidget old) {
    super.didUpdateWidget(old);
    if (widget.result != old.result) {
      _editCtrl.text = _mapToEditableText(widget.result);
      _isEditing = false;
    }
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  String _mapToEditableText(Map<String, dynamic>? r) {
    if (r == null || r.isEmpty) return '';
    final buf = StringBuffer();
    void addField(String label, dynamic val) {
      if (val == null) return;
      final s = _listOrString(val);
      if (s.isNotEmpty) buf.writeln('$label:\n$s\n');
    }

    addField('Image Type', r['imageType'] ?? r['image_type']);
    addField('Region', r['region'] ?? r['body_region']);
    addField('Quality', r['quality']);
    addField('Findings', r['findings']);
    addField('Impressions', r['impressions'] ?? r['impression']);
    addField(
      'Differentials',
      r['differentials'] ?? r['differential_diagnoses'],
    );
    addField('Recommendations', r['recommendations']);
    return buf.toString().trim();
  }

  String _listOrString(dynamic v) {
    if (v == null) return '';
    if (v is List)
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .join('\n');
    final s = v.toString().trim();
    return s == 'null' || s.isEmpty ? '' : s;
  }

  List<String> _toList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final s = v.toString().trim();
    return s.isEmpty ? [] : [s];
  }

  _Differential _parseDiff(String text) {
    final probRx = RegExp(r'^(.+?)\s*\(~?(\d+)%\)\s*[—–-]?\s*(.*)$');
    final m = probRx.firstMatch(text.trim());
    if (m != null) {
      return _Differential(
        name: m.group(1)?.trim() ?? text,
        probability: int.tryParse(m.group(2) ?? '0') ?? 0,
        description: m.group(3)?.trim().replaceAll(RegExp(r'\.$'), '') ?? '',
      );
    }
    return _Differential(name: text.trim(), probability: 0, description: '');
  }

  Color _qualityColor(String q) {
    switch (q.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF1B8C4E);
      case 'good':
        return const Color(0xFF2196A5);
      case 'fair':
        return const Color(0xFFE0921A);
      case 'poor':
        return const Color(0xFFD32F2F);
      default:
        return _dt.textS;
    }
  }

  @override
  Widget build(BuildContext context) {
    _dt = Theme.of(context).extension<DoctorThemeData>()!;
    _loc = AppLocalizations.of(context)!;
    if (widget.isLoading) return _buildLoading();
    if (widget.result == null || widget.result!.isEmpty)
      return _buildPlaceholder();
    return _buildResult();
  }

  Widget _buildLoading() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(color: _T.navy, strokeWidth: 2.5),
        ),
        const SizedBox(height: 14),
        Text(
          _loc.runningAiAnalysis,
          style: TextStyle(fontSize: 13, color: _dt.textS.withOpacity(0.7)),
        ),
      ],
    ),
  );

  Widget _buildPlaceholder() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        Icon(
          Icons.image_search_rounded,
          size: 44,
          color: _dt.textM.withOpacity(0.28),
        ),
        const SizedBox(height: 10),
        Text(
          _loc.noAnalysisYet,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _dt.textH.withOpacity(0.38),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _loc.noAnalysisYetSub,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: _dt.textS.withOpacity(0.6),
            height: 1.5,
          ),
        ),
      ],
    ),
  );

  Widget _buildResult() {
    final r = widget.result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        if (_isEditing) _buildEditor() else _buildStructured(r),
      ],
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_T.teal.withOpacity(0.13), _T.navy.withOpacity(0.07)],
      ),
      borderRadius: _isEditing
          ? const BorderRadius.vertical(top: Radius.circular(16))
          : BorderRadius.zero,
      border: Border(bottom: BorderSide(color: _T.teal.withOpacity(0.2))),
    ),
    child: Row(
      children: [
        const Icon(Icons.biotech_rounded, color: _T.teal, size: 16),
        const SizedBox(width: 7),
        Text(
          _loc.aiAnalysisResultTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _T.teal,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            if (widget.onEditTap != null) {
              widget.onEditTap!();
            } else {
              setState(() => _isEditing = !_isEditing);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isEditing
                  ? _T.teal.withOpacity(0.15)
                  : _T.navy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                  size: 13,
                  color: _isEditing ? _T.teal : _dt.textS,
                ),
                const SizedBox(width: 4),
                Text(
                  _isEditing ? _loc.doneLabel : _loc.editLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isEditing ? _T.teal : _dt.textS,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEditor() => Padding(
    padding: const EdgeInsets.all(14),
    child: TextField(
      controller: _editCtrl,
      maxLines: null,
      minLines: 10,
      style: const TextStyle(
        fontSize: 12,
        height: 1.6,
        color: Color(0xFF1A2A3A),
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _dt.bgInput,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _T.teal.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _T.teal.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _T.teal, width: 1.5),
        ),
        hintText: _loc.editAiAnalysisHint,
        hintStyle: TextStyle(color: _dt.textS.withOpacity(0.4), fontSize: 12),
      ),
    ),
  );

  Widget _buildStructured(Map<String, dynamic> r) {
    final imageType = (r['imageType'] ?? r['image_type'] ?? '')
        .toString()
        .trim();
    final region = (r['region'] ?? r['body_region'] ?? '').toString().trim();
    final quality = (r['quality'] ?? '').toString().trim();

    final findings = _toList(r['findings']);
    final impressions = _toList(r['impressions'] ?? r['impression']);
    final diffRaw = _toList(r['differentials'] ?? r['differential_diagnoses']);
    final diffs = diffRaw.map(_parseDiff).toList();
    final recs = _toList(r['recommendations']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageType.isNotEmpty || region.isNotEmpty || quality.isNotEmpty)
            _buildMetaStrip(imageType, region, quality),

          if (findings.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionLabel(
              Icons.search_rounded,
              _loc.findingsLabel,
              const Color(0xFF1565C0),
            ),
            const SizedBox(height: 8),
            _buildFindingsList(findings),
          ],

          if (impressions.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionLabel(
              Icons.psychology_rounded,
              _loc.impressionLabel,
              _T.navy,
            ),
            const SizedBox(height: 8),
            _buildImpressionCard(impressions),
          ],

          if (diffs.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionLabel(
              Icons.balance_rounded,
              _loc.differentialDiagnosesLabel,
              const Color(0xFF6A1B9A),
            ),
            const SizedBox(height: 8),
            _buildDifferentialsList(diffs),
          ],

          if (recs.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionLabel(
              Icons.lightbulb_outline_rounded,
              _loc.recommendationsLabel,
              _T.teal,
            ),
            const SizedBox(height: 8),
            _buildRecommendationsList(recs),
          ],

          const SizedBox(height: 16),
          _buildDisclaimer(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMetaStrip(String imageType, String region, String quality) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (imageType.isNotEmpty)
          _MetaBadge(
            icon: Icons.monitor_heart_rounded,
            label: imageType.toUpperCase(),
            color: _T.navy,
          ),
        if (region.isNotEmpty)
          _MetaBadge(
            icon: Icons.place_outlined,
            label: _toTitleCase(region),
            color: const Color(0xFF1565C0),
          ),
        if (quality.isNotEmpty)
          _MetaBadge(
            icon: Icons.verified_outlined,
            label: '${_toTitleCase(quality)} ${_loc.qualitySuffix}',
            color: _qualityColor(quality),
          ),
      ],
    );
  }

  Widget _buildSectionLabel(IconData icon, String title, Color color) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    ],
  );

  Widget _buildFindingsList(List<String> items) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF1565C0).withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        items.length,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < items.length - 1 ? 9 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _dt.textH,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildImpressionCard(List<String> items) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_T.teal.withOpacity(0.10), _T.navy.withOpacity(0.05)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _T.teal.withOpacity(0.20)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _T.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _dt.textH,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _buildDifferentialsList(List<_Differential> diffs) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF6A1B9A).withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(diffs.length, (i) {
        final d = diffs[i];
        final hasProb = d.probability > 0;
        final barColor = i == 0
            ? const Color(0xFF6A1B9A)
            : i == 1
            ? const Color(0xFF9C27B0)
            : const Color(0xFFCE93D8);

        return Padding(
          padding: EdgeInsets.only(bottom: i < diffs.length - 1 ? 12 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      d.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _dt.textH,
                      ),
                    ),
                  ),
                  if (hasProb) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${d.probability}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: barColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasProb) ...[
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: d.probability / 100,
                    minHeight: 5,
                    backgroundColor: barColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
              if (d.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  d.description,
                  style: TextStyle(fontSize: 11, color: _dt.textS, height: 1.4),
                ),
              ],
            ],
          ),
        );
      }),
    ),
  );

  Widget _buildRecommendationsList(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(
      items.length,
      (i) => Padding(
        padding: EdgeInsets.only(bottom: i < items.length - 1 ? 8 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 10),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _T.teal.withOpacity(0.10),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: _T.teal,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  items[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _dt.textH,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildDisclaimer() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1, right: 8),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 15,
            color: Color(0xFF8A6100),
          ),
        ),
        Expanded(
          child: Text(
            _loc.aiDisclaimerText,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6D4C00),
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );

  String _toTitleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _Differential {
  final String name;
  final int probability;
  final String description;
  const _Differential({
    required this.name,
    required this.probability,
    required this.description,
  });
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}
