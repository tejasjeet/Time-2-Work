import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';
import '../../core/utils/friendly_error.dart';
import '../../shared/widgets/widgets.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String userId;
  const ReportScreen({super.key, required this.userId});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _report({bool alsoBlock = false}) async {
    if (_reason.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a short reason')));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(userRepositoryProvider).reportUser(widget.userId, _reason.text.trim());
      if (alsoBlock) {
        await ref.read(userRepositoryProvider).blockUser(widget.userId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
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
      appBar: AppBar(title: const Text('Report user')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            const Text('Phone numbers are never shown. Tell us what went wrong.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            AppField(controller: _reason, label: 'Reason', hint: 'Spam, harassment, fake job…', maxLines: 5),
            const Spacer(),
            AppButton(label: 'Submit report', loading: _busy, onPressed: () => _report()),
            const SizedBox(height: 10),
            AppButton(label: 'Report and block', outlined: true, onPressed: _busy ? null : () => _report(alsoBlock: true)),
          ],
        ),
      ),
    );
  }
}
