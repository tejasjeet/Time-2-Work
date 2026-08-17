import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/location/location_places.dart';
import '../../core/fixtures/app_fixtures.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/marketplace_widgets.dart';
import '../../shared/widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isBusiness = user?.isBusiness ?? false;
    final jobs = ref.watch(isBusiness ? myJobsProvider : nearbyJobsProvider);
    final city = cityLabelFor(user?.lat ?? 25.5941, user?.lng ?? 85.1376);
    final firstName = (user?.name ?? 'there').trim().split(' ').first;
    final muted = AppColors.hint(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            if (isBusiness) {
              ref.invalidate(myJobsProvider);
            } else {
              ref.invalidate(nearbyJobsProvider);
            }
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/change-location'),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              (user?.areaLabel ?? city).split(',').first,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.expand_more_rounded, size: 18, color: muted),
                        ],
                      ),
                    ),
                  ),
                  _RoundIcon(icon: Icons.notifications_none_rounded, onTap: () => context.push('/notifications')),
                  const SizedBox(width: 8),
                  _RoundIcon(icon: Icons.bookmark_border_rounded, onTap: () => context.push('/saved')),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Hi $firstName,',
                style: TextStyle(color: muted, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                isBusiness ? 'Post work and hire locally' : 'What can we help with?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
              ),
              const SizedBox(height: 16),
              ComposerSearchBar(
                controller: _search,
                hint: isBusiness ? 'Search workers or services…' : 'Search jobs, workers, services…',
                onTap: () => context.push('/search'),
              ),
              const SizedBox(height: 26),
              if (isBusiness) ...[
                GptPromoBanner(onTap: () => context.go('/post')),
                const SizedBox(height: 28),
                SectionTitle(title: 'Your posted jobs', action: 'See all', onAction: () => context.go('/jobs')),
                const SizedBox(height: 10),
                jobs.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myJobsProvider)),
                  data: (list) {
                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No jobs posted yet. Tap + to hire workers.', style: TextStyle(color: muted)),
                      );
                    }
                    return Column(
                      children: list
                          .take(3)
                          .map(
                            (job) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: JobCard(job: job, onTap: () => context.push('/jobs/${job.id}')),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    QuickActionCard(
                      title: 'Post a job',
                      icon: Icons.work_outline_rounded,
                      onTap: () => context.go('/post'),
                    ),
                    const SizedBox(width: 10),
                    QuickActionCard(
                      title: 'Applications',
                      icon: Icons.assignment_outlined,
                      onTap: () => context.push('/applications'),
                    ),
                    const SizedBox(width: 10),
                    QuickActionCard(
                      title: 'Local bazar',
                      icon: Icons.storefront_outlined,
                      onTap: () => context.push('/bazar'),
                    ),
                  ],
                ),
              ] else ...[
              SectionTitle(title: 'Book a service', action: 'See all', onAction: () => context.push('/services')),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AppFixtures.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (_, i) {
                  final (label, icon) = AppFixtures.categories[i];
                  return CategoryGridTile(
                    label: label,
                    icon: categoryIcon(icon),
                    onTap: () => label == 'More' ? context.push('/services') : context.push('/search-results?q=$label'),
                  );
                },
              ),
              const SizedBox(height: 8),
              GptPromoBanner(onTap: () => context.go('/post')),
              const SizedBox(height: 28),
              SectionTitle(title: 'Nearby jobs', action: 'See all', onAction: () => context.go('/jobs')),
              const SizedBox(height: 10),
              jobs.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(nearbyJobsProvider)),
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No nearby jobs yet. Pull to refresh or post work.', style: TextStyle(color: muted)),
                    );
                  }
                  return Column(
                    children: list
                        .take(3)
                        .map(
                          (job) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: JobCard(job: job, onTap: () => context.push('/jobs/${job.id}')),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppFixtures.popularSearches
                    .map(
                      (s) => ActionChip(
                        label: Text(s),
                        onPressed: () => context.push('/search-results?q=$s'),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              SectionTitle(title: 'Most booked', action: 'See all', onAction: () => context.push('/services')),
              const SizedBox(height: 12),
              SizedBox(
                height: 288,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppFixtures.workers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final w = AppFixtures.workers[i];
                    return WorkerCarouselCard(
                      worker: w,
                      onTap: () => context.push('/workers/${w.id}'),
                      onSave: () => context.push('/saved'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              SectionTitle(title: 'Top professionals', action: 'See all', onAction: () => context.push('/search-results?q=Electrician')),
              const SizedBox(height: 12),
              SizedBox(
                height: 288,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppFixtures.workers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final w = AppFixtures.workers[i];
                    return WorkerCarouselCard(worker: w, onTap: () => context.push('/workers/${w.id}'));
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  QuickActionCard(
                    title: 'Find workers',
                    icon: Icons.person_search_outlined,
                    onTap: () => context.push('/search-results?q=Electrician'),
                  ),
                  const SizedBox(width: 10),
                  QuickActionCard(
                    title: 'Post a job',
                    icon: Icons.work_outline_rounded,
                    onTap: () => context.go('/post'),
                  ),
                  const SizedBox(width: 10),
                  QuickActionCard(
                    title: 'Local bazar',
                    icon: Icons.storefront_outlined,
                    onTap: () => context.push('/bazar'),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.inputFill(context),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
