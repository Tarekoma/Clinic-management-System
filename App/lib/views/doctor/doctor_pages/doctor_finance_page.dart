// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_finance_page.dart
//
// CHANGES IN THIS VERSION:
//   • _buildRow no longer does:
//        a['appointment_type_name'] ?? a['appointment_type'] ?? 'Consultation'
//     which printed a raw Map (e.g. "id: 1, name: ..., duration_minutes: 30")
//     whenever appointment_type_name was null and appointment_type was a Map.
//     Replaced with _resolveType(), same safe pattern used in
//     doctor_appt_card.dart.
//   • DateFormat('dd MMM') now passes the active locale.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/widgets/doctor/doctor_shared_widgets.dart';
import 'package:Hakim/widgets/doctor/doctor_consultation_widgets.dart';
import 'package:Hakim/viewmodels/doctor_viewmodel.dart';

typedef _T = DoctorTheme;

class DoctorFinancePage extends ConsumerStatefulWidget {
  const DoctorFinancePage({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorFinancePage> createState() => _DoctorFinancePageState();
}

class _DoctorFinancePageState extends ConsumerState<DoctorFinancePage> {
  late DoctorThemeData _dt; // injected in build()
  bool _unpaidOnly = false;

  // ── Safe appointment-type resolver ─────────────────────────────────────
  // Handles three shapes: null, a Map ({id, name, duration_minutes, ...}),
  // or a plain String. Never falls through to a raw Map.toString().
  // Also maps known backend type-name strings (English, from the API) to
  // their localized equivalent, since the backend itself isn't localized.
  String _resolveType(dynamic raw, AppLocalizations loc) {
    String extracted;
    if (raw == null) {
      extracted = loc.consultationDefault;
    } else if (raw is Map) {
      extracted = (raw['name'] ?? raw['title'] ?? loc.consultationDefault)
          .toString();
    } else {
      final s = raw.toString().trim();
      extracted = s.isEmpty ? loc.consultationDefault : s;
    }
    return _localizeTypeName(extracted, loc);
  }

  // ── Maps a known backend type-name string to its localized label.
  // Falls back to the original string for any type name not in this list
  // (e.g. custom appointment types added by the doctor).
  String _localizeTypeName(String name, AppLocalizations loc) {
    switch (name.trim().toLowerCase()) {
      case 'initial consultation':
        return loc.initialConsultation;
      case 'consultation':
        return loc.visitTypeConsultation;
      case 'revisit':
      case 're-visit':
        return loc.visitTypeRevisit;
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    _dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final state = ref.watch(doctorViewModelProvider);
    final vm = ref.read(doctorViewModelProvider.notifier);
    final loading = state.loadingAppointments;
    final s = vm.financeStats;
    final rate = s['total']! > 0 ? s['paid']! / s['total']! : 0.0;
    final list = vm.billableAppointments(unpaidOnly: _unpaidOnly);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // ── Revenue hero ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(22),
            decoration: _T.gradCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.totalRevenue,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${arNumber(s['total']!, localeCode)} ${loc.currencyEgp}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DoctorFinChip(
                        label: loc.collected,
                        value:
                            '${arNumber(s['paid']!, localeCode)} ${loc.currencyEgp}',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF69F0AE),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DoctorFinChip(
                        label: loc.outstanding,
                        value:
                            '${arNumber(s['unpaid']!, localeCode)} ${loc.currencyEgp}',
                        icon: Icons.pending_rounded,
                        color: const Color(0xFFFFD54F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Collection rate ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _T.cardOf(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      loc.collectionRate,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _dt.textH,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${arNumber((rate * 100).round(), localeCode)}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _T.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 10,
                    backgroundColor: _dt.bgInput,
                    valueColor: const AlwaysStoppedAnimation<Color>(_T.teal),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── List header ───────────────────────────────────────────────────
          Row(
            children: [
              Text(
                loc.paymentRecords,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _dt.textH,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _unpaidOnly = !_unpaidOnly),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _unpaidOnly ? _T.warningBg : _dt.bgInput,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _unpaidOnly
                          ? _T.warning.withOpacity(0.4)
                          : _dt.divider,
                    ),
                  ),
                  child: Text(
                    loc.unpaidOnly,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _unpaidOnly ? _T.warning : _dt.textS,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Payment rows ──────────────────────────────────────────────────
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: _T.navy,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (list.isEmpty)
            DoctorEmpty(
              icon: Icons.receipt_long_outlined,
              title: loc.noPaymentRecords,
              sub: loc.noPaymentRecordsSub,
            )
          else
            ...list.map((a) => _buildRow(a, vm, loc, localeCode)),
        ],
      ),
    );
  }

  Widget _buildRow(
    Map<String, dynamic> a,
    DoctorViewModel vm,
    AppLocalizations loc,
    String localeCode,
  ) {
    DateTime? dt;
    try {
      dt = DateTime.parse(a['start_time'].toString()).toLocal();
    } catch (_) {}
    final isPaid = a['is_paid'] == true;
    final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0.0;

    // FIXED: was `a['appointment_type_name'] ?? a['appointment_type'] ?? 'Consultation'`
    // which printed a raw Map.toString() whenever appointment_type was a Map
    // and appointment_type_name was null (the "id: 1, name: ..." bug).
    final type = _resolveType(
      a['appointment_type_name'] ?? a['appointment_type'],
      loc,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _dt.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid
              ? _T.success.withOpacity(0.2)
              : _T.warning.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPaid ? _T.successBg : _T.warningBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: isPaid ? _T.success : _T.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.apptName(a),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _dt.textH,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    type,
                    if (dt != null)
                      arDigits(
                        DateFormat('dd MMM', localeCode).format(dt),
                        localeCode,
                      ),
                  ].join('  •  '),
                  style: TextStyle(fontSize: 11, color: _dt.textS),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${arNumber(fee, localeCode)} ${loc.currencyEgp}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isPaid ? _T.success : _T.warning,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isPaid ? _T.successBg : _T.warningBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isPaid ? loc.paidBadge : loc.unpaidBadge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isPaid ? _T.success : _T.warning,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
