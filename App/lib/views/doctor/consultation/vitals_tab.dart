// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/vitals_tab.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

class VitalsTab extends ConsumerStatefulWidget {
  final int appointmentId;
  final int patientId;

  const VitalsTab({
    required this.appointmentId,
    required this.patientId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<VitalsTab> createState() => _VitalsTabState();
}

class _VitalsTabState extends ConsumerState<VitalsTab> {
  // ── Local, self-contained loading/error state ────────────────────────────
  // NOTE: This widget intentionally does NOT gate its spinner on
  // `doctorViewModelProvider`'s `loadingVitals` flag. If the ViewModel ever
  // fails to reset that flag on some code path (e.g. an early return, a
  // re-entrancy guard left "stuck" after a prior failed call, or a missing
  // `state = state.copyWith(loadingVitals: false)` on an error branch), this
  // tab would spin forever even though the local fetch already completed.
  // `_loading` below is ALWAYS reset in a `finally` block, so this tab is
  // guaranteed to leave the loading state regardless of what the ViewModel's
  // own flag does.
  bool _loading = true;
  bool _hasError = false;
  bool _didLoadOnce = false;

  static const _fetchTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    // Defer the first fetch to after the initial frame. fetchVitals() sets
    // provider state synchronously before its first await, which Riverpod
    // rejects when called directly inside initState during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;

    // No valid IDs to fetch with — don't even attempt the call, just show
    // the empty state immediately instead of spinning forever waiting on
    // a request that the backend will reject anyway.
    if (widget.appointmentId <= 0 && widget.patientId <= 0) {
      debugPrint(
        '⚠️ VitalsTab._load: no valid appointmentId/patientId — skipping fetch.',
      );
      setState(() {
        _loading = false;
        _hasError = false;
        _didLoadOnce = true;
      });
      return;
    }

    setState(() {
      _loading = true;
      _hasError = false;
    });

    debugPrint(
      '🩺 VitalsTab._load: start (appointmentId=${widget.appointmentId}, '
      'patientId=${widget.patientId})',
    );

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
      if (mounted) setState(() => _hasError = true);
    } catch (e, st) {
      debugPrint('❌ VitalsTab._load error: $e');
      debugPrint('$st');
      if (mounted) setState(() => _hasError = true);
    } finally {
      // ALWAYS reached — success, timeout, or any other exception — so the
      // spinner can never persist indefinitely once this future settles.
      if (mounted) {
        setState(() {
          _loading = false;
          _didLoadOnce = true;
        });
      }
    }
  }

  String _str(Map<String, dynamic> v, String key) =>
      (v[key] ?? '').toString().replaceAll('null', '').trim();

  @override
  Widget build(BuildContext context) {
    final vitalsState = ref.watch(doctorViewModelProvider);
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: _T.teal, strokeWidth: 2),
      );
    }

    final vitals = vitalsState.vitals.isNotEmpty
        ? vitalsState.vitals.first
        : null;

    if (vitals == null) {
      return _buildEmpty(dt, loc);
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
            _buildHeader(dt, loc, vitals),
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

  Widget _buildEmpty(DoctorThemeData dt, AppLocalizations loc) {
    return RefreshIndicator(
      onRefresh: _load,
      color: _T.teal,
      child: ListView(
        padding: const EdgeInsets.all(40),
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.monitor_heart_outlined,
            size: 64,
            color: dt.textM.withOpacity(0.4),
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
        ],
      ),
    );
  }

  Widget _buildHeader(
    DoctorThemeData dt,
    AppLocalizations loc,
    Map<String, dynamic> vitals,
  ) {
    final recordedAt = vitals['recorded_at'] ?? vitals['created_at'];
    String dateStr = '';
    if (recordedAt != null) {
      try {
        final dt2 = DateTime.parse(recordedAt.toString()).toLocal();
        dateStr = DateFormat('dd MMM yyyy  •  hh:mm a').format(dt2);
      } catch (_) {}
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _T.teal.withOpacity(0.1),
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

  Widget _buildVitalsGrid(
    DoctorThemeData dt,
    AppLocalizations loc,
    Map<String, dynamic> vitals,
  ) {
    final systolic = _str(vitals, 'blood_pressure_systolic');
    final diastolic = _str(vitals, 'blood_pressure_diastolic');
    final bpValue = (systolic.isNotEmpty && diastolic.isNotEmpty)
        ? '$systolic/$diastolic'
        : systolic;
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
            color: item.color.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: item.color.withOpacity(0.15)),
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
        border: Border.all(color: _T.navy.withOpacity(0.12)),
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
