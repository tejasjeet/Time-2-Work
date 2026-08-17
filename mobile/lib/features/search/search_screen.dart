import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/json_helpers.dart';
import '../../models/job.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/illustrations.dart';
import '../../shared/widgets/widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _q,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Jobs, skills, area…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              onSubmitted: (v) => ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(searchResultsProvider)),
              data: (data) {
                final jobs = data.jobs;
                final people = data.users;
                if (ref.watch(searchQueryProvider).trim().isEmpty) {
                  return const EmptyState(
                    icon: Icons.search,
                    illustration: EmptyJobsIllustration(),
                    title: 'Search nearby work',
                    subtitle: 'Try “helper”, “delivery”, “painter”',
                  );
                }
                if (jobs.isEmpty && people.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    illustration: EmptyJobsIllustration(),
                    title: 'No matches',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (jobs.isNotEmpty) const SectionHeader(title: 'Jobs'),
                    ...jobs.map((m) {
                      final job = Job.fromJson(m);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: JobCard(job: job, onTap: () => context.push('/jobs/${job.id}')),
                      );
                    }),
                    if (people.isNotEmpty) const SectionHeader(title: 'People'),
                    ...people.map((m) {
                      final sanitized = Map<String, dynamic>.from(m)
                        ..remove('phone')
                        ..remove('phoneNumber')
                        ..remove('mobile');
                      final id = readId(sanitized);
                      final name = readString(sanitized, ['name', 'displayName']) ?? 'Member';
                      return ListTile(
                        leading: AvatarCircle(name: name, url: readString(sanitized, ['photoUrl', 'avatar'])),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(readString(sanitized, ['areaLabel', 'area']) ?? 'Approximate area'),
                        onTap: id.isEmpty ? null : () => context.push('/users/$id'),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
