// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/doctor_finance_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/providers/doctor_providers.dart';
import 'package:Hakim/utils/doctor_theme.dart';
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
  bool _unpaidOnly = false;

  @override
  Widget build(BuildContext context) {
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
                  'Total Revenue',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${s['total']!.toStringAsFixed(0)} EGP',
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
                        label: 'Collected',
                        value: '${s['paid']!.toStringAsFixed(0)} EGP',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF69F0AE),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DoctorFinChip(
                        label: 'Outstanding',
                        value: '${s['unpaid']!.toStringAsFixed(0)} EGP',
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
            decoration: _T.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Collection Rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _T.textH,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(rate * 100).toStringAsFixed(0)}%',
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
                    backgroundColor: _T.bgInput,
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
              const Text(
                'Payment Records',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _T.textH,
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
                    color: _unpaidOnly ? _T.warningBg : _T.bgInput,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _unpaidOnly
                          ? _T.warning.withOpacity(0.4)
                          : _T.divider,
                    ),
                  ),
                  child: Text(
                    'Unpaid only',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _unpaidOnly ? _T.warning : _T.textS,
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
            const DoctorEmpty(
              icon: Icons.receipt_long_outlined,
              title: 'No payment records',
              sub: 'Payments appear here after booking.',
            )
          else
            ...list.map((a) => _buildRow(a, vm)),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> a, DoctorViewModel vm) {
    DateTime? dt;
    try {
      dt = DateTime.parse(a['start_time'].toString()).toLocal();
    } catch (_) {}
    final isPaid = a['is_paid'] == true;
    final fee = double.tryParse((a['fee'] ?? 0).toString()) ?? 0.0;
    final type =
        a['appointment_type_name'] ?? a['appointment_type'] ?? 'Consultation';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.bgCard,
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.textH,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    type,
                    if (dt != null) DateFormat('dd MMM').format(dt),
                  ].join('  •  '),
                  style: const TextStyle(fontSize: 11, color: _T.textS),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${fee.toStringAsFixed(0)} EGP',
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
                  isPaid ? 'PAID' : 'UNPAID',
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
