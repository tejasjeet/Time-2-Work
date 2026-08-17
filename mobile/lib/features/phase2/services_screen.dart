import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/fixtures/app_fixtures.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(servicesProvider);
    final area = ref.watch(authProvider).user?.areaLabel?.split(',').first ?? 'your area';
    final muted = AppColors.hint(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Services'),
        actions: [
          IconButton(onPressed: () => context.push('/search'), icon: const Icon(Icons.search_rounded)),
        ],
      ),
      body: list.when(
        loading: () => _ServiceList(area: area, items: AppFixtures.services.map((s) => s.title).toList(), useFixtures: true),
        error: (_, __) => _ServiceList(area: area, items: AppFixtures.services.map((s) => s.title).toList(), useFixtures: true),
        data: (items) {
          if (items.isEmpty) {
            return _ServiceList(area: area, items: const [], useFixtures: true);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text('Services near $area', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Book verified professionals for home & daily needs.', style: TextStyle(color: muted)),
              const SizedBox(height: 16),
              ...items.asMap().entries.map((entry) {
                final s = entry.value;
                final fixture = AppFixtures.services[entry.key % AppFixtures.services.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ServiceListTile(
                    service: FixtureService(
                      id: s.id,
                      title: s.title,
                      subtitle: s.description ?? s.address ?? s.category ?? 'Local service',
                      imageUrl: fixture.imageUrl,
                      icon: IconKey.shop,
                      rating: 4.6,
                      reviews: 40,
                      startingPrice: s.price != null ? '₹${s.price!.toInt()}' : '₹250',
                    ),
                    onTap: () => context.push('/search-results?q=${Uri.encodeComponent(s.title)}'),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  const _ServiceList({required this.area, required this.items, required this.useFixtures});

  final String area;
  final List<String> items;
  final bool useFixtures;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Services near $area',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Book verified professionals with real photos and ratings',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 16),
        ...AppFixtures.services.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ServiceListTile(
              service: s,
              onTap: () => context.push('/search-results?q=${Uri.encodeComponent(s.title)}'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 290,
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
      ],
    );
  }
}
