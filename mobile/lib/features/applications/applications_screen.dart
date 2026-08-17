import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/application.dart';
import '../../providers/providers.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/fixtures/app_fixtures.dart';
import '../../shared/widgets/detail_page_widgets.dart';
import '../../shared/widgets/illustrations.dart';
import '../../shared/widgets/marketplace_widgets.dart';
import '../../shared/widgets/widgets.dart';

class ApplicationsScreen extends ConsumerStatefulWidget {
  final String? jobId;
  const ApplicationsScreen({super.key, this.jobId});

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: widget.jobId == null ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _decide(Application app, String status) async {
    try {
      await ref.read(applicationsRepositoryProvider).update(app.id, status);
      ref.invalidate(myApplicationsProvider);
      if (widget.jobId != null) ref.invalidate(jobApplicationsProvider(widget.jobId!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked $status')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(myApplicationsProvider);
    final inbox = widget.jobId == null ? null : ref.watch(jobApplicationsProvider(widget.jobId!));
    final myJobs = ref.watch(myJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobId == null ? 'Applications' : 'Applicants'),
        bottom: widget.jobId == null
            ? TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'I applied'),
                  Tab(text: 'Inbox'),
                ],
              )
            : null,
      ),
      body: widget.jobId != null
          ? inbox!.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(jobApplicationsProvider(widget.jobId!))),
              data: (list) => _InboxList(list: list, onDecide: _decide),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                mine.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myApplicationsProvider)),
                  data: (list) {
                    if (list.isEmpty) {
                      return const EmptyState(
                        icon: Icons.inbox_outlined,
                        illustration: EmptyJobsIllustration(),
                        title: 'No applications yet',
                        subtitle: 'Tap I Can Do It on a job.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final a = list[i];
                        final job = a.job;
                        return _ApplicationJobCard(
                          title: job?.title ?? 'Job',
                          category: job?.category ?? 'Work',
                          status: a.status.toUpperCase(),
                          onTap: a.jobId.isEmpty ? null : () => context.push('/jobs/${a.jobId}'),
                        );
                      },
                    );
                  },
                ),
                myJobs.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myJobsProvider)),
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return const EmptyState(
                        icon: Icons.work_outline,
                        illustration: EmptyJobsIllustration(),
                        title: 'You have not posted jobs yet',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: jobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final j = jobs[i];
                        return _ApplicationJobCard(
                          title: j.title,
                          category: j.category,
                          status: '${j.status} · ${j.workersAccepted}/${j.workersRequired} accepted',
                          onTap: () => context.push('/applications/job/${j.id}'),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _InboxList extends StatelessWidget {
  final List<Application> list;
  final void Function(Application, String) onDecide;
  const _InboxList({required this.list, required this.onDecide});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return const EmptyState(icon: Icons.people_outline, title: 'No applicants yet');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final a = list[i];
        final name = a.worker?.name ?? 'Worker';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FixtureImage(url: a.worker?.photoUrl ?? AppFixtures.workers.first.imageUrl, width: 56, height: 56),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(a.status.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: a.workerId.isEmpty ? null : () => context.push('/users/${a.workerId}'), icon: const Icon(Icons.open_in_new_rounded)),
                ],
              ),
              if (a.message != null && a.message!.isNotEmpty) ...[
                const SizedBox(height: 10),
                DetailInfoCard(text: a.message!),
              ],
              const SizedBox(height: 10),
              if (a.isApplied)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onDecide(a, 'accepted'),
                        child: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onDecide(a, 'rejected'),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                )
              else if (a.isAccepted && a.chatId != null)
                TextButton(
                  onPressed: () => context.push('/chats/${a.chatId}'),
                  child: const Text('Open chat'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ApplicationJobCard extends StatelessWidget {
  final String title;
  final String category;
  final String status;
  final VoidCallback? onTap;

  const _ApplicationJobCard({
    required this.title,
    required this.category,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FixtureImage(url: AppFixtures.jobImageFor(category, title: title), width: 56, height: 56),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(status, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
          ],
        ),
      ),
    );
  }
}
