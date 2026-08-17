import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(earningsProvider);
    final txns = ref.watch(transactionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings / Kamai')),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(earningsProvider);
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            summary.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(earningsProvider)),
              data: (s) => Column(
                children: [
                  _Stat(label: 'Total earned', value: s.total),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _Mini(label: 'This month', value: s.thisMonth)),
                      const SizedBox(width: 10),
                      Expanded(child: _Mini(label: 'Pending', value: s.pending)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${s.completedJobs} jobs completed', style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            txns.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator(color: AppColors.amber)),
              error: (e, _) => Text(e.toString()),
              data: (list) {
                if (list.isEmpty) {
                  return const Text('No transactions yet', style: TextStyle(color: AppColors.muted));
                }
                return Column(
                  children: list.map((t) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.note ?? _prettyTxnType(t.type), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text([
                        if (t.uniqueTxnId.isNotEmpty) t.uniqueTxnId,
                        t.status,
                        if (t.commission > 0) 'Fee ₹${t.commission.toStringAsFixed(0)}',
                      ].join(' · ')),
                      trailing: MoneyText(t.net, size: 16),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final double value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSidebar : AppColors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value),
            style: const TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final double value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          MoneyText(value, size: 18),
        ],
      ),
    );
  }
}

String _prettyTxnType(String type) {
  switch (type) {
    case 'job_payout':
      return 'Job payment';
    case 'posting_fee':
      return 'Posting fee';
    case 'refund':
      return 'Refund';
    default:
      return type.replaceAll('_', ' ');
  }
}
