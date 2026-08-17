import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/fixtures/app_fixtures.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_rounded, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saved', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      Text(
                        'Your saved workers, services and jobs',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () => context.push('/notifications'), icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_none_rounded))),
                IconButton(onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TabChip(label: 'Workers (${AppFixtures.workers.length})', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                const SizedBox(width: 8),
                _TabChip(label: 'Services (${AppFixtures.services.length})', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                const SizedBox(width: 8),
                _TabChip(label: 'Jobs (${AppFixtures.savedJobs.length})', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
              ],
            ),
            const SizedBox(height: 20),
            if (_tab == 0) ...[
              const SectionTitle(title: 'Saved Workers', action: 'See All'),
              const SizedBox(height: 10),
              SizedBox(
                height: 290,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppFixtures.workers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final w = AppFixtures.workers[i];
                    return WorkerCarouselCard(worker: w, saved: true, onTap: () => context.push('/workers/${w.id}'));
                  },
                ),
              ),
            ],
            if (_tab == 1) ...[
              const SectionTitle(title: 'Saved Services', action: 'See All'),
              const SizedBox(height: 10),
              ...AppFixtures.services.map((s) => ServiceListTile(service: s, onTap: () => context.push('/search-results?q=${s.title}'))),
            ],
            if (_tab == 2) ...[
              const SectionTitle(title: 'Saved Jobs', action: 'See All'),
              const SizedBox(height: 10),
              ...AppFixtures.savedJobs.map((j) => SavedJobTile(job: j, onTap: () => context.push('/jobs/${j.id}'))),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).dividerColor, width: selected ? 1.6 : 1),
            color: selected ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.chip) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
