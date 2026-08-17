import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/fixtures/app_fixtures.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class CompareWorkersScreen extends ConsumerWidget {
  const CompareWorkersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(compareWorkersProvider);
    final workers = ids.map(AppFixtures.workerById).whereType<FixtureWorker>().toList();
    if (workers.isEmpty) {
      workers.addAll(AppFixtures.workers.take(3));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compare Workers'),
            Text('Choose the best professional for your job', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Share')),
          TextButton(onPressed: () {}, child: const Text('Save')),
          TextButton(onPressed: () => ref.read(compareWorkersProvider.notifier).state = [], child: const Text('Clear All')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                child: Text('Compare (${workers.length})', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () => context.push('/search-results?q=Electrician'), child: const Text('+ Add More')),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: workers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _CompareCard(worker: workers[i]),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Overview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          _CompareTable(workers: workers),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${workers.first.name} has the highest rating, fastest response time and most experience.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                OutlinedButton(onPressed: () => context.push('/workers/${workers.first.id}'), child: const Text('View Profile')),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.star_outline_rounded),
                  label: const Text('Save Comparison'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/workers/${workers.first.id}'),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Book Selected Worker'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final FixtureWorker worker;
  const _CompareCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Align(alignment: Alignment.topLeft, child: StatusBadge(label: worker.badge)),
          const SizedBox(height: 8),
          ClipOval(child: FixtureImage(url: worker.imageUrl, width: 72, height: 72)),
          const SizedBox(height: 8),
          Text(worker.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
              Text(' ${worker.rating} (${worker.reviews})'),
            ],
          ),
          Text('${worker.experienceYears}+ years experience', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          Text('${worker.distanceKm} km', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(worker.availability, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
          Text(worker.priceRange, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          const Spacer(),
          OutlinedButton(onPressed: () {}, child: const Text('Chat')),
        ],
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  final List<FixtureWorker> workers;
  const _CompareTable({required this.workers});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Rating', workers.map((w) => '★ ${w.rating}').toList()),
      ('Experience', workers.map((w) => '${w.experienceYears}+ yrs').toList()),
      ('Jobs Completed', workers.map((w) => '${w.jobsDone}+').toList()),
      ('Response Time', workers.map((w) => w.responseTime).toList()),
      ('Distance', workers.map((w) => '${w.distanceKm} km').toList()),
      ('Hourly Rate', workers.map((w) => w.priceRange).toList()),
      ('Availability', workers.map((w) => w.availability).toList()),
      ('Languages', workers.map((w) => w.languages.join(', ')).toList()),
      ('Verified', workers.map((_) => '✓ Background Verified').toList()),
    ];

    return Table(
      border: TableBorder.all(color: Theme.of(context).dividerColor),
      columnWidths: {
        0: const FlexColumnWidth(1.2),
        for (var i = 1; i <= workers.length; i++) i: const FlexColumnWidth(1),
      },
      children: rows
          .map(
            (r) => TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                ...r.$2.map((v) => Padding(padding: const EdgeInsets.all(8), child: Text(v, style: const TextStyle(fontSize: 11)))),
              ],
            ),
          )
          .toList(),
    );
  }
}
