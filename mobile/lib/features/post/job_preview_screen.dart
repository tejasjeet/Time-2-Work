import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';
import 'post_job_screen.dart';

class JobPreviewScreen extends ConsumerStatefulWidget {
  const JobPreviewScreen({super.key});

  @override
  ConsumerState<JobPreviewScreen> createState() => _JobPreviewScreenState();
}

class _JobPreviewScreenState extends ConsumerState<JobPreviewScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final draft = ref.read(jobDraftProvider);
    final user = ref.read(authProvider).user;
    try {
      final job = await ref.read(jobsRepositoryProvider).create(
            draft.toJson(lat: user?.lat, lng: user?.lng),
          );
      if (mounted) context.push('/post/checkout?jobId=${job.id}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(jobDraftProvider);
    final pay = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(draft.pay);
    final muted = AppColors.hint(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Preview job')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.panel(context),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (draft.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(draft.category, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent, fontSize: 12)),
                        ),
                      const SizedBox(height: 12),
                      Text(draft.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2)),
                      const SizedBox(height: 10),
                      Text(pay, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.accent)),
                      const SizedBox(height: 16),
                      Text(draft.description.isEmpty ? 'No extra details added' : draft.description, style: TextStyle(color: muted, height: 1.45)),
                      const SizedBox(height: 16),
                      _MetaRow(icon: Icons.groups_outlined, label: '${draft.workersRequired} worker(s) needed'),
                      if (draft.date != null) _MetaRow(icon: Icons.event_outlined, label: DateFormat.yMMMd().format(draft.date!)),
                      if (draft.address.isNotEmpty) _MetaRow(icon: Icons.location_on_outlined, label: draft.address),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Next: pay the posting fee, then your job goes live.', style: TextStyle(color: muted, fontSize: 13)),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: AppColors.canvas(context),
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.6))),
            ),
            child: SafeArea(
              top: false,
              child: AppButton(label: 'Continue to checkout', loading: _busy, onPressed: _create),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
