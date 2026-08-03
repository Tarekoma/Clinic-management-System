// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/vitals_tab.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/clinic_helpers.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

// Purple accent constants — match the rest of the app's chronic-condition UI
const _kPurple = Color(0xFF6A1B9A);
const _kPurpleBg = Color(0xFFF3E5F5);

class VitalsTab extends ConsumerStatefulWidget {
  final int appointmentId;
  final int patientId;

  const VitalsTab({
    required this.appointmentId,
    required this.patientId,
    super.key,
  });

  @override
  ConsumerState<VitalsTab> createState() => _VitalsTabState();
}

class _VitalsTabState extends ConsumerState<VitalsTab> {
  // ── Vitals loading state ──────────────────────────────────────────────────
  // Intentionally local — not gated on the ViewModel flag so a stuck flag
  // can never freeze this tab. Always reset in a finally block.
  bool _loading = true;

  // ── Chronic conditions state ──────────────────────────────────────────────
  List<String> _chronicConditions = [];
  bool _conditionsLoaded = false;

  static const _fetchTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    // Defer past the first build frame — Riverpod forbids state mutations
    // that originate inside initState/the first synchronous build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  // ── Primary loader ────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (!mounted) return;

    if (widget.appointmentId <= 0 && widget.patientId <= 0) {
      debugPrint(
        '⚠️ VitalsTab._load: no valid appointmentId/patientId — skipping fetch.',
      );
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    debugPrint(
      '🩺 VitalsTab._load: start (appointmentId=${widget.appointmentId}, '
      'patientId=${widget.patientId})',
    );

    // Launch conditions fetch in parallel with vitals. It has its own
    // independent error handling and does NOT affect the vitals error state.
    if (widget.patientId > 0) _loadChronicConditions();

    try {
      await ref
          .read(doctorViewModelProvider.notifier)
          .fetchVitals(
            appointmentId: widget.appointmentId,
            patientId: widget.patientId,
          )
          .timeout(_fetchTimeout);

      debugPrint('✅ VitalsTab._load: fetchVitals completed normally.');
    } on TimeoutException catch (e) {
      debugPrint(
        '⏱️ VitalsTab._load: fetchVitals timed out after '
        '${_fetchTimeout.inSeconds}s — forcing exit from loading state. $e',
      );
    } catch (e, st) {
      debugPrint('❌ VitalsTab._load error: $e');
      debugPrint('$st');
    } finally {
      // ALWAYS reached — success, timeout, or any other exception.
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Chronic conditions loader ─────────────────────────────────────────────

  Future<void> _loadChronicConditions() async {
    if (widget.patientId <= 0) return;

    // Try the ViewModel's cached patients first — avoids an extra API call
    // when the patient record was already fetched for the patients list.
    final cached = ref.read(doctorViewModelProvider).patients.firstWhere(
      (p) => p['id'].toString() == widget.patientId.toString(),
      orElse: () => {},
    );

    if (cached.isNotEmpty && cached['patient_conditions'] is List) {
      final names = ClinicHelpers.extractChronicConditions(cached)
          .map(ClinicHelpers.conditionName)
          .where((n) => n.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _chronicConditions = names;
          _conditionsLoaded = true;
        });
      }
      debugPrint(
        '✅ VitalsTab._loadChronicConditions: '
        '${names.length} condition(s) from cache.',
      );
      return;
    }

    // Fallback: GET /clinic/patients/{id} always embeds patient_conditions.
    try {
      final full = await ApiService.getPatientById(widget.patientId);
      final names = ClinicHelpers.extractChronicConditions(full)
          .map(ClinicHelpers.conditionName)
          .where((n) => n.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _chronicConditions = names;
          _conditionsLoaded = true;
        });
      }
      debugPrint(
        '✅ VitalsTab._loadChronicConditions: '
        '${names.length} condition(s) from API.',
      );
    } catch (e) {
      debugPrint('⚠️ VitalsTab._loadChronicConditions: $e');
      // Mark loaded so the UI doesn't spin forever; show empty/no-conditions.
      if (mounted) setState(() => _conditionsLoaded = true);
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String _str(Map<String, dynamic> v, String key) =>
      (v[key] ?? '').toString().replaceAll('null', '').trim();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vitalsState = ref.watch(doctorViewModelProvider);
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _T.teal, strokeWidth: 2),
      );
    }

    final vitals = vitalsState.vitals.isNotEmpty
        ? vitalsState.vitals.first
        : null;

    // Both the empty-vitals and loaded-vitals views start with the chronic
    // conditions card so the doctor always sees the patient's medical history
    // context regardless of whether vitals have been recorded yet.
    if (vitals == null) {
      return _buildEmptyVitals(dt, loc);
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _T.teal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChronicConditionsCard(dt, loc),
            const SizedBox(height: 16),
            _buildVitalsHeader(dt, loc, vitals),
            const SizedBox(height: 16),
            _buildVitalsGrid(dt, loc, vitals),
            const SizedBox(height: 16),
            if (_str(vitals, 'chief_complaint').isNotEmpty)
              _buildComplaintCard(dt, loc, vitals),
            if (_str(vitals, 'notes').isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildNotesCard(dt, loc, vitals),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── Empty vitals view ─────────────────────────────────────────────────────

  Widget _buildEmptyVitals(DoctorThemeData dt, AppLocalizations loc) {
    return RefreshIndicator(
      onRefresh: _load,
      color: _T.teal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildChronicConditionsCard(dt, loc),
            const SizedBox(height: 40),
            Icon(
              Icons.monitor_heart_outlined,
              size: 64,
              color: dt.textM.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 20),
            Text(
              loc.noVitalsRecorded,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: dt.textS,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.noVitalsRecordedSub,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: dt.textM),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── Chronic Conditions Card ───────────────────────────────────────────────

  Widget _buildChronicConditionsCard(DoctorThemeData dt, AppLocalizations loc) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPurple.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header band ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            decoration: const BoxDecoration(
              color: _kPurpleBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medical_information_rounded,
                    color: _kPurple,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.chronicConditionsTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kPurple,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                // Count badge — only when conditions are present
                if (_conditionsLoaded && _chronicConditions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_chronicConditions.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Body ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: _buildConditionsBody(dt, loc),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsBody(DoctorThemeData dt, AppLocalizations loc) {
    // Small spinner while the fetch is in progress
    if (!_conditionsLoaded) {
      return const SizedBox(
        height: 24,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _kPurple,
              ),
            ),
          ],
        ),
      );
    }

    // Empty state — no chronic conditions on record
    if (_chronicConditions.isEmpty) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 17,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 9),
          Text(
            loc.noChronicDiseasesRecorded,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF388E3C),
            ),
          ),
        ],
      );
    }

    // Condition chips
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _chronicConditions
          .map((name) => _ConditionChip(name: name))
          .toList(),
    );
  }

  // ── Vitals header ─────────────────────────────────────────────────────────

  Widget _buildVitalsHeader(
    DoctorThemeData dt,
    AppLocalizations loc,
    Map<String, dynamic> vitals,
  ) {
    final recordedAt = vitals['recorded_at'] ?? vitals['created_at'];
    String dateStr = '';
    if (recordedAt != null) {
      try {
        final d = DateTime.parse(recordedAt.toString()).toLocal();
        dateStr = DateFormat('dd MMM yyyy  •  hh:mm a').format(d);
      } catch (_) {}
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _T.teal.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.monitor_heart_rounded,
            color: _T.teal,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.patientVitals,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: dt.textH,
                ),
              ),
              if (dateStr.isNotEmpty)
                Text(
                  '${loc.vitalsRecordedByAssistant}  •  $dateStr',
                  style: TextStyle(fontSize: 11, color: dt.textM),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Vitals grid ───────────────────────────────────────────────────────────

  Widget _buildVitalsGrid(
    DoctorThemeData dt,
    AppLocalizations loc,
    Map<String, dynamic> vitals,
  ) {
    final sys = _str(vitals, 'blood_pressure_systolic');
    final dia = _str(vitals, 'blood_pressure_diastolic');
    final bpValue =
        (sys.isNotEmpty && dia.isNotEmpty) ? '$sys/$dia' : sys;
    final heartRate = _str(vitals, 'heart_rate');
    final temperature = _str(vitals, 'temperature');
    final weight = _str(vitals, 'weight');
    final height = _str(vitals, 'height');

    final items = [
      if (bpValue.isNotEmpty)
        _VitalItem(
          icon: Icons.favorite_border_rounded,
          label: loc.bloodPressureLabel,
          value: bpValue,
          unit: loc.mmhgUnit,
          color: const Color(0xFFE53935),
        ),
      if (heartRate.isNotEmpty)
        _VitalItem(
          icon: Icons.monitor_heart_outlined,
          label: loc.heartRateLabel,
          value: heartRate,
          unit: loc.bpmUnit,
          color: const Color(0xFFE91E63),
        ),
      if (temperature.isNotEmpty)
        _VitalItem(
          icon: Icons.thermostat_rounded,
          label: loc.temperatureLabel,
          value: temperature,
          unit: loc.celsiusUnit,
          color: const Color(0xFFFF9800),
        ),
      if (weight.isNotEmpty)
        _VitalItem(
          icon: Icons.scale_rounded,
          label: loc.weightLabel,
          value: weight,
          unit: loc.kgUnit,
          color: _T.teal,
        ),
      if (height.isNotEmpty)
        _VitalItem(
          icon: Icons.height_rounded,
          label: loc.heightLabel,
          value: height,
          unit: loc.cmUnit,
          color: const Color(0xFF1565C0),
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => SizedBox(
              width: (MediaQuery.of(context).size.width - 52) / 2,
              child: _buildVitalCard(dt, item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildVitalCard(DoctorThemeData dt, _VitalItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: item.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: item.color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(fontSize: 11, color: dt.textM),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: item.value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: item.color,
                  ),
                ),
                TextSpan(
                  text: '  ${item.unit}',
                  style: TextStyle(fontSize: 11, color: dt.textM),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Chief Complaint card ──────────────────────────────────────────────────

  Widget _buildComplaintCard(
    DoctorThemeData dt,
    AppLocalizations loc,
    Map<String, dynamic> vitals,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.navy.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                color: _T.navy,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                loc.chiefComplaintLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dt.textS,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _str(vitals, 'chief_complaint'),
            style: TextStyle(fontSize: 14, color: dt.textH, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Notes card ────────────────────────────────────────────────────────────

  Widget _buildNotesCard(
    DoctorThemeData dt,
    AppLocalizations loc,
    Map<String, dynamic> vitals,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dt.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dt.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, color: dt.textM, size: 17),
              const SizedBox(width: 8),
              Text(
                loc.vitalsNotesLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dt.textS,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _str(vitals, 'notes'),
            style: TextStyle(fontSize: 13, color: dt.textH, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Chronic Condition Chip ────────────────────────────────────────────────────

class _ConditionChip extends StatelessWidget {
  final String name;
  const _ConditionChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: _kPurpleBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPurple.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _kPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kPurple,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vital item data class ─────────────────────────────────────────────────────

class _VitalItem {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _VitalItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });
}
