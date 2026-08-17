import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/fixtures/app_fixtures.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final workers = AppFixtures.workers;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Search Results'),
            Text('$query near Patna, Bihar', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(onPressed: () => context.push('/notifications'), icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_none_rounded))),
          IconButton(onPressed: () => context.go('/saved'), icon: const Icon(Icons.favorite_border_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: query,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded)),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Chip(label: 'Category: $query', active: true),
                _Chip(label: 'Type: Services'),
                _Chip(label: 'Location: Patna, Bihar'),
                _Chip(label: 'Sort By: Best Match'),
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Text('Filters', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                      SizedBox(width: 6),
                      CircleAvatar(radius: 10, backgroundColor: AppColors.white, child: Text('2', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _Chip(label: 'All', active: true),
                _Chip(label: '✓ Verified'),
                _Chip(label: 'Top Rated'),
                _Chip(label: 'Near Me (2 km)'),
                _Chip(label: 'Available Now'),
                _Chip(label: 'Price ▾'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${workers.length * 30 + 5} $query found', style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
              const Text(' Showing results in 2 km', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ...workers.map(
            (w) => SearchResultCard(
              worker: w,
              onTap: () => context.push('/workers/${w.id}'),
              onCompare: () => context.push('/compare'),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(child: Text('Safety First — All electricians are background verified.', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryDark))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Need an Electrician Urgently?', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: () => context.go('/post'), child: const Text('Post a Job')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save More', style: TextStyle(fontWeight: FontWeight.w800)),
                      Text('10% OFF • Code T2W10', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  const _Chip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.accentSoft.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 1) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.accent : Theme.of(context).dividerColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: active ? AppColors.accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
