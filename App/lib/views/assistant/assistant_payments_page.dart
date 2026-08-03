// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_payments_page.dart
//
// Refactored from _buildPayments() + _buildPaymentRow() + _togglePayment().
// Architecture change only — visual output identical.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/providers/assistant_providers.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/widgets/assistant/assistant_shared_widgets.dart';

typedef _T = AssistantTheme;
typedef _Empty = AssistantEmpty;

class AssistantPaymentsPage extends ConsumerWidget {
  const AssistantPaymentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;
    final state = ref.watch(assistantViewModelProvider);
    final vm = ref.read(assistantViewModelProvider.notifier);
    final stats = vm.paymentStats();

    final total = stats['total']!;
    final paid = stats['paid']!;
    final unpaid = stats['unpaid']!;
    final rate = total > 0 ? paid / total : 0.0;

    final billable =
        state.appointments
            .where((a) => (a['status'] ?? '').toUpperCase() != 'CANCELLED')
            .toList()
          ..sort(
            (a, b) => (vm.parseDate(b['start_time']) ?? DateTime.now())
                .compareTo(vm.parseDate(a['start_time']) ?? DateTime.now()),
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
                    loc.totalRevenue,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${arNumber(total, lc)} ${loc.currencyEgp}',
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
                          label: loc.collected,
                          value: '${arNumber(paid, lc)} ${loc.currencyEgp}',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF69F0AE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AssistantFinChip(
                          label: loc.outstanding,
                          value: '${arNumber(unpaid, lc)} ${loc.currencyEgp}',
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
              decoration: AssistantTheme.cardOf(context),
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
                          color: at.textH,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${arNumber(rate * 100, lc)}%',
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
                      backgroundColor: at.bgInput,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _T.greenLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Text(
              loc.paymentRecords,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: at.textH,
              ),
            ),
            const SizedBox(height: 10),

            if (state.loadingAppointments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: _T.green,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (billable.isEmpty)
              _Empty(
                icon: Icons.receipt_long_outlined,
                title: loc.noPaymentRecords,
                sub: loc.noPaymentRecordsSub,
              )
            else
              ...billable.map(
                (a) => _PaymentRow(
                  appt: a,
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
  final String Function(Map<String, dynamic>) apptName;
  final DateTime? Function(dynamic) parseDate;

  const _PaymentRow({
    required this.appt,
    required this.apptName,
    required this.parseDate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;
    final isPaid = appt['is_paid'] == true;
    final fee = double.tryParse((appt['fee'] ?? 0).toString()) ?? 0.0;
    final dt = parseDate(appt['start_time']);
    final name = apptName(appt);
    final type =
        (appt['appointment_type'] as Map?)?['name'] ??
        appt['appointment_type_name'] ??
        loc.consultationDefault;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: at.bgCard,
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
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: at.textH,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    type,
                    if (dt != null)
                      arDigits(DateFormat('dd MMM', lc).format(dt), lc),
                  ].join('  •  '),
                  style: TextStyle(fontSize: 11, color: at.textS),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${arNumber(fee, lc)} ${loc.currencyEgp}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isPaid ? _T.success : _T.warning,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
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
                  isPaid ? loc.paidCheckLabel : loc.unpaidTapLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isPaid ? _T.success : _T.warning,
                    letterSpacing: 0.4,
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
