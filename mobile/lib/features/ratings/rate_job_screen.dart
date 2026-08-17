import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';
import '../../core/utils/friendly_error.dart';
import '../../shared/widgets/widgets.dart';

class RateJobScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? toUserId;
  const RateJobScreen({super.key, required this.jobId, this.toUserId});

  @override
  ConsumerState<RateJobScreen> createState() => _RateJobScreenState();
}

class _RateJobScreenState extends ConsumerState<RateJobScreen> {
  int _stars = 5;
  final _review = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref.read(jobsRepositoryProvider).rate(
            widget.jobId,
            rating: _stars,
            review: _review.text.trim(),
            toUserId: widget.toUserId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for the review')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate / Rating dein')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            const Text('How was this job?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const Text('Kaam kaisa raha?', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            RatingStars(value: _stars, onChanged: (v) => setState(() => _stars = v)),
            const SizedBox(height: 16),
            AppField(controller: _review, label: 'Short review', hint: 'On time, good work…', maxLines: 4),
            const Spacer(),
            AppButton(label: 'Submit review / Review bhejein', loading: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
