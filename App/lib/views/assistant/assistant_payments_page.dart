// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_payments_page.dart
//
// Refactored from _buildPayments() + _buildPaymentRow() + _togglePayment().
// Architecture change only — visual output identical.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/widgets/assistant/assistant_shared_widgets.dart';

typedef _T     = AssistantTheme;
typedef _Empty = AssistantEmpty;

class AssistantPaymentsPage extends ConsumerWidget {
  const AssistantPaymentsPage({Key? key}) : super(key: key);

  // ── SnackBar (needs a BuildContext — we pass it through) ─────────────────────

  void _snack(BuildContext context, String msg, {bool err = false}) {
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

  // ── Toggle payment via ViewModel ─────────────────────────────────────────────

  Future<void> _togglePayment(
    WidgetRef ref,
    BuildContext context,
    int id,
    bool currentlyPaid,
  ) async {
    try {
      await ref
          .read(assistantViewModelProvider.notifier)
          .togglePayment(id, currentlyPaid: currentlyPaid);
      _snack(context, currentlyPaid ? 'Marked as unpaid' : 'Marked as paid');
    } catch (e) {
      _snack(context, 'Failed to update payment: ${e.toString()}', err: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assistantViewModelProvider);
    final vm    = ref.read(assistantViewModelProvider.notifier);
    final stats = vm.paymentStats();

    final total  = stats['total']!;
    final paid   = stats['paid']!;
    final unpaid = stats['unpaid']!;
    final rate   = total > 0 ? paid / total : 0.0;

    final billable = state.appointments
        .where(
          (a) => (a['status'] ?? '').toUpperCase() != 'CANCELLED',
        )
        .toList()
      ..sort(
        (a, b) => (vm.parseDate(b['start_time']) ?? DateTime.now()).compareTo(
          vm.parseDate(a['start_time']) ?? DateTime.now(),
        ),
      );

    return RefreshIndicator(
      onRefresh: vm.fetchAppointments,
      color: _T.green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // ── Revenue hero card ─────────────────────────────────────────
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
                    '${total.toStringAsFixed(0)} EGP',
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
                        child: AssistantFinChip(
                          label: 'Collected',
                          value: '${paid.toStringAsFixed(0)} EGP',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF69F0AE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AssistantFinChip(
                          label: 'Outstanding',
                          value: '${unpaid.toStringAsFixed(0)} EGP',
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

            // ── Collection rate ───────────────────────────────────────────
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
                          color: _T.green,
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
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _T.greenLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            const Text(
              'Payment Records',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _T.textH,
              ),
            ),
            const SizedBox(height: 10),

            if (state.loadingAppointments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: _T.green, strokeWidth: 2),
                ),
              )
            else if (billable.isEmpty)
              const _Empty(
                icon: Icons.receipt_long_outlined,
                title: 'No payment records',
              )
            else
              ...billable.map(
                (a) => _PaymentRow(
                  appt: a,
                  onToggle: (id, isPaid) =>
                      _togglePayment(ref, context, id, isPaid),
                  apptName: vm.apptName,
                  parseDate: vm.parseDate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Payment row (private to this file — mirrors original _buildPaymentRow) ────

class _PaymentRow extends StatelessWidget {
  final Map<String, dynamic> appt;
  final Future<void> Function(int id, bool isPaid) onToggle;
  final String Function(Map<String, dynamic>) apptName;
  final DateTime? Function(dynamic) parseDate;

  const _PaymentRow({
    required this.appt,
    required this.onToggle,
    required this.apptName,
    required this.parseDate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPaid = appt['is_paid'] == true;
    final fee    = double.tryParse((appt['fee'] ?? 0).toString()) ?? 0.0;
    final dt     = parseDate(appt['start_time']);
    final name   = apptName(appt);
    final type   =
        (appt['appointment_type'] as Map?)?['name'] ??
        appt['appointment_type_name'] ??
        'Consultation';
    final id = int.tryParse((appt['id'] ?? '0').toString()) ?? 0;

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
            color: _T.green.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPaid ? _T.successBg : _T.warningBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid
                  ? Icons.check_circle_rounded
                  : Icons.pending_rounded,
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
                  name,
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
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => onToggle(id, isPaid),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPaid ? _T.successBg : _T.warningBg,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isPaid
                          ? _T.success.withOpacity(0.4)
                          : _T.warning.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    isPaid ? 'PAID ✓' : 'UNPAID — Tap',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isPaid ? _T.success : _T.warning,
                      letterSpacing: 0.4,
                    ),
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
