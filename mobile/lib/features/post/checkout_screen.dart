import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/json_helpers.dart';
import '../../core/utils/friendly_error.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String jobId;
  const CheckoutScreen({super.key, required this.jobId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _busy = false;
  String? _error;
  String _status = 'Pay ₹19 posting fee to publish this job.';

  Future<void> _pay() async {
    if (widget.jobId.isEmpty) {
      setState(() => _error = 'Missing job id');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await ref.read(paymentsRepositoryProvider).createOrder(jobId: widget.jobId);
      final orderId = readString(order, ['orderId', 'id', '_id']) ?? widget.jobId;
      setState(() => _status = 'Processing payment…');
      await ref.read(paymentsRepositoryProvider).mockConfirm(orderId);
      try {
        await ref.read(jobsRepositoryProvider).payFee(widget.jobId);
      } catch (_) {}
      setState(() => _status = 'Publishing your job…');
      await ref.read(jobsRepositoryProvider).publish(widget.jobId);
      ref.invalidate(myJobsProvider);
      ref.invalidate(nearbyJobsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job is live / Job live ho gaya')));
        context.go('/jobs/${widget.jobId}');
      }
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posting fee')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(16)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Secure checkout', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text('₹19', style: TextStyle(color: AppColors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                  Text('One-time job posting fee', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(_status),
            const SizedBox(height: 8),
            Text(
              'Your job goes live immediately after payment.',
              style: TextStyle(color: AppColors.hint(context)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const Spacer(),
            AppButton(label: 'Pay ₹19 & publish / Abhi pay karein', loading: _busy, onPressed: _pay),
          ],
        ),
      ),
    );
  }
}
