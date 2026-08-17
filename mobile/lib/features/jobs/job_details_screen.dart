import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/fixtures/app_fixtures.dart';
import '../../core/utils/friendly_error.dart';
import '../../models/job.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/detail_page_widgets.dart';
import '../../shared/widgets/widgets.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailsScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  bool _applying = false;
  String? _message;

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      await ref.read(jobsRepositoryProvider).apply(widget.jobId, message: 'I can do it / Main kar sakta hoon');
      ref.invalidate(myApplicationsProvider);
      if (mounted) {
        setState(() => _message = 'Applied! The owner will see you in Applications.');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application sent / Apply ho gaya')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(jobDetailProvider(widget.jobId));
    final me = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(jobDetailProvider(widget.jobId))),
        data: (job) {
          final pay = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(job.pay);
          final isOwner = me != null && job.posterId != null && me.id == job.posterId;
          final hero = AppFixtures.jobImageFor(job.category, title: job.title);
          final gallery = AppFixtures.jobGalleryFor(job.category, title: job.title);
          final onSurface = Theme.of(context).colorScheme.onSurface;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    DetailHeroImage(
                      imageUrl: hero,
                      badge: job.status.toUpperCase() == 'URGENT' ? 'URGENT' : job.category.isEmpty ? 'WORK' : job.category.toUpperCase(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Text(job.category.isEmpty ? 'Work' : job.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        const Spacer(),
                        Text(job.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: onSurface.withValues(alpha: 0.7))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(job.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.15)),
                    const SizedBox(height: 8),
                    Text(pay, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    Text(_payLabel(job.payType), style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 13)),
                    const SizedBox(height: 16),
                    DetailStatGrid(
                      items: [
                        DetailStatItem(
                          icon: Icons.place_outlined,
                          label: 'Location',
                          value: job.areaLabel ?? job.address ?? 'Nearby',
                        ),
                        DetailStatItem(
                          icon: Icons.event_outlined,
                          label: 'Date',
                          value: job.date != null ? DateFormat.MMMd().format(job.date!) : 'Flexible',
                        ),
                        DetailStatItem(
                          icon: Icons.groups_outlined,
                          label: 'Workers',
                          value: '${job.workersAccepted}/${job.workersRequired}',
                        ),
                      ],
                    ),
                    if (job.distanceKm != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.social_distance, size: 16, color: onSurface.withValues(alpha: 0.55)),
                          const SizedBox(width: 6),
                          Text('${job.distanceKm!.toStringAsFixed(1)} KM away', style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    DetailSection(
                      title: 'About this work',
                      child: DetailInfoCard(text: job.description.isEmpty ? 'No extra details provided by the poster.' : job.description),
                    ),
                    const SizedBox(height: 24),
                    DetailSection(
                      title: 'Job photos',
                      action: 'View all',
                      child: DetailGalleryStrip(urls: gallery, moreLabel: '+3'),
                    ),
                    const SizedBox(height: 24),
                    if (job.posterName != null)
                      DetailSection(
                        title: 'Posted by',
                        child: DetailPosterCard(
                          name: job.posterName!,
                          photoUrl: job.posterPhoto,
                          rating: job.posterRating,
                          subtitle: 'Business on Time2Work',
                          onTap: job.posterId == null ? null : () => context.push('/users/${job.posterId}'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const DetailSafetyBanner(text: 'Posters and workers are verified for safer local work.'),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: job.posterId == null ? null : () => context.push('/report/${job.posterId}'),
                      child: const Text('Report this poster', style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: _bottomActions(context, job, isOwner, me?.isBusiness ?? false),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _payLabel(String payType) {
    switch (payType.toLowerCase()) {
      case 'hourly':
        return 'Per hour payment';
      case 'daily':
        return 'Per day payment';
      default:
        return 'Fixed payment';
    }
  }

  Widget _bottomActions(BuildContext context, Job job, bool isOwner, bool isBusiness) {
    if (isOwner) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(label: 'View applications', onPressed: () => context.push('/applications/job/${job.id}')),
          if (!job.isCompleted) ...[
            const SizedBox(height: 8),
            AppButton(
              label: 'Mark completed',
              outlined: true,
              onPressed: () async {
                await ref.read(jobsRepositoryProvider).updateStatus(job.id, 'completed');
                ref.invalidate(jobDetailProvider(job.id));
              },
            ),
          ],
        ],
      );
    }

    if (isBusiness) {
      return AppButton(
        label: 'Post your own job',
        onPressed: () => context.go('/post'),
      );
    }

    if (job.isCompleted) {
      return AppButton(
        label: 'Rate this job',
        onPressed: () => context.push('/rate/${job.id}${job.posterId != null ? '?toUserId=${job.posterId}' : ''}'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BilingualCta(loading: _applying, onPressed: job.isOpen ? _apply : null),
        if (!job.isOpen)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('This job is not open for new applications.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          ),
      ],
    );
  }
}
