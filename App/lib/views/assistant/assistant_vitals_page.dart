// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_vitals_page.dart
//
// Bottom sheet for assistants to record patient vitals before a consultation.
// Supports: Blood Pressure, Heart Rate, Temperature, Weight, Height,
//           Chief Complaint, and Notes.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/utils/assistant_theme.dart';

typedef _T = AssistantTheme;

class AssistantVitalsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onSaved;

  const AssistantVitalsPage({
    required this.appointment,
    this.onSaved,
    super.key,
  });

  @override
  ConsumerState<AssistantVitalsPage> createState() =>
      _AssistantVitalsPageState();
}

class _AssistantVitalsPageState extends ConsumerState<AssistantVitalsPage> {
  final _formKey = GlobalKey<FormState>();

  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _complaintCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _saving = false;
  bool _hasExisting = false;

  int get _appointmentId =>
      int.tryParse((widget.appointment['id'] ?? '0').toString()) ?? 0;

  int get _patientId =>
      int.tryParse(
        (widget.appointment['patient_id'] ??
                widget.appointment['patient']?['id'] ??
                '0')
            .toString(),
      ) ??
      0;

  String get _patientName {
    final fn =
        widget.appointment['patient_first_name'] ??
        widget.appointment['patient']?['first_name'] ??
        '';
    final ln =
        widget.appointment['patient_last_name'] ??
        widget.appointment['patient']?['last_name'] ??
        '';
    return '$fn $ln'.trim();
  }

  @override
  void initState() {
    super.initState();
    _prefillExisting();
  }

  Future<void> _prefillExisting() async {
    final vm = ref.read(assistantViewModelProvider.notifier);
    final cached = vm.getCachedVitals(_appointmentId);
    if (cached != null) {
      _fillFromVitals(cached);
      return;
    }
    final existing = await vm.fetchVitalsForAppointment(_appointmentId);
    if (existing != null && mounted) {
      _fillFromVitals(existing);
    }
  }

  void _fillFromVitals(Map<String, dynamic> v) {
    setState(() => _hasExisting = true);
    _systolicCtrl.text =
        (v['blood_pressure_systolic'] ?? '').toString().replaceAll('null', '');
    _diastolicCtrl.text =
        (v['blood_pressure_diastolic'] ?? '').toString().replaceAll('null', '');
    _heartRateCtrl.text =
        (v['heart_rate'] ?? '').toString().replaceAll('null', '');
    _temperatureCtrl.text =
        (v['temperature'] ?? '').toString().replaceAll('null', '');
    _weightCtrl.text = (v['weight'] ?? '').toString().replaceAll('null', '');
    _heightCtrl.text = (v['height'] ?? '').toString().replaceAll('null', '');
    _complaintCtrl.text = (v['chief_complaint'] ?? '').toString();
    _notesCtrl.text = (v['notes'] ?? '').toString();
  }

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _heartRateCtrl.dispose();
    _temperatureCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _complaintCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final vitalsData = <String, dynamic>{};

      final sys = int.tryParse(_systolicCtrl.text.trim());
      final dia = int.tryParse(_diastolicCtrl.text.trim());
      final hr = int.tryParse(_heartRateCtrl.text.trim());
      final temp = double.tryParse(_temperatureCtrl.text.trim());
      final weight = double.tryParse(_weightCtrl.text.trim());
      final height = double.tryParse(_heightCtrl.text.trim());
      final complaint = _complaintCtrl.text.trim();
      final notes = _notesCtrl.text.trim();

      if (sys != null) vitalsData['blood_pressure_systolic'] = sys;
      if (dia != null) vitalsData['blood_pressure_diastolic'] = dia;
      if (hr != null) vitalsData['heart_rate'] = hr;
      if (temp != null) vitalsData['temperature'] = temp;
      if (weight != null) vitalsData['weight'] = weight;
      if (height != null) vitalsData['height'] = height;
      if (complaint.isNotEmpty) vitalsData['chief_complaint'] = complaint;
      if (notes.isNotEmpty) vitalsData['notes'] = notes;

      if (vitalsData.isEmpty) {
        _snack('Enter at least one vital before saving.', err: true);
        return;
      }

      await ref.read(assistantViewModelProvider.notifier).saveVitals(
        appointmentId: _appointmentId,
        patientId: _patientId,
        vitalsData: vitalsData,
      );

      if (!mounted) return;
      widget.onSaved?.call();
      Navigator.of(context).pop(true);
    } catch (e) {
      final loc2 = AppLocalizations.of(context)!;
      _snack(
        loc2.vitalsSaveFailed(e.toString().replaceAll('Exception: ', '')),
        err: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? _T.urgent : _T.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: at.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──────────────────────────────────────────────────
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: at.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _T.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_rounded,
                    color: _T.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasExisting
                            ? loc.updateVitals
                            : loc.recordVitalsForPatient(_patientName),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: at.textH,
                        ),
                      ),
                      if (_hasExisting)
                        Text(
                          loc.vitalsAlreadyRecorded,
                          style: TextStyle(fontSize: 11, color: _T.info),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: at.textM),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(color: at.divider, height: 16),

          // ── Form ────────────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 4, 20, bottom + 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.vitalsOptionalNote,
                      style: TextStyle(fontSize: 11, color: at.textM),
                    ),
                    const SizedBox(height: 16),

                    // ── Blood Pressure ──────────────────────────────────
                    _sectionLabel(loc.bloodPressureLabel, at),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _numericField(
                            controller: _systolicCtrl,
                            label: loc.systolicLabel,
                            context: context,
                            at: at,
                            decimal: false,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '/',
                            style: TextStyle(
                              fontSize: 20,
                              color: at.textM,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _numericField(
                            controller: _diastolicCtrl,
                            label: loc.diastolicLabel,
                            context: context,
                            at: at,
                            decimal: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Heart Rate ──────────────────────────────────────
                    _numericField(
                      controller: _heartRateCtrl,
                      label: loc.heartRateLabel,
                      context: context,
                      at: at,
                      decimal: false,
                      icon: Icons.monitor_heart_outlined,
                    ),
                    const SizedBox(height: 14),

                    // ── Temperature ─────────────────────────────────────
                    _numericField(
                      controller: _temperatureCtrl,
                      label: loc.temperatureLabel,
                      context: context,
                      at: at,
                      decimal: true,
                      icon: Icons.thermostat_rounded,
                    ),
                    const SizedBox(height: 14),

                    // ── Weight & Height ─────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _numericField(
                            controller: _weightCtrl,
                            label: loc.weightLabel,
                            context: context,
                            at: at,
                            decimal: true,
                            icon: Icons.scale_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _numericField(
                            controller: _heightCtrl,
                            label: loc.heightLabel,
                            context: context,
                            at: at,
                            decimal: true,
                            icon: Icons.height_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Chief Complaint ─────────────────────────────────
                    TextField(
                      controller: _complaintCtrl,
                      maxLines: 3,
                      decoration: _T.inpOf(
                        context,
                        loc.chiefComplaintLabel,
                        hint: loc.chiefComplaintHint,
                        pre: const Icon(
                          Icons.record_voice_over_rounded,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Notes ────────────────────────────────────────────
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: _T.inpOf(
                        context,
                        loc.vitalsNotesLabel,
                        hint: loc.vitalsNotesHint,
                        pre: const Icon(Icons.notes_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Save Button ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _T.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _hasExisting
                                    ? loc.updateVitals
                                    : loc.recordVitals,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, AssistantThemeData at) => Text(
    label,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: at.textS,
    ),
  );

  Widget _numericField({
    required TextEditingController controller,
    required String label,
    required BuildContext context,
    required AssistantThemeData at,
    required bool decimal,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]')),
      ],
      decoration: _T.inpOf(
        context,
        label,
        pre: icon != null ? Icon(icon, size: 18) : null,
      ),
    );
  }
}
