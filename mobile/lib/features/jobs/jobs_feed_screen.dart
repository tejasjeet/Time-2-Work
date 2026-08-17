import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';
import '../../repositories/jobs_repository.dart';
import '../../shared/widgets/illustrations.dart';
import '../../shared/widgets/widgets.dart';

class JobsFeedScreen extends ConsumerWidget {
  const JobsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isBusiness = user?.isBusiness ?? false;

    if (isBusiness) {
      return _BusinessJobsView(onRefresh: () => ref.invalidate(myJobsProvider));
    }

    final jobs = ref.watch(nearbyJobsProvider);
    final filters = ref.watch(jobFiltersProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs / Kaam'),
        actions: [
          IconButton(onPressed: () => context.push('/search'), icon: const Icon(Icons.search)),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _Chip(
                  label: '5 KM',
                  selected: filters.radiusKm == 5,
                  onTap: () {
                    ref.read(jobFiltersProvider.notifier).state = filters.radiusKm == 5
                        ? filters.copyWith(clearRadius: true)
                        : filters.copyWith(radiusKm: 5);
                  },
                ),
                _Chip(
                  label: '10 KM',
                  selected: filters.radiusKm == 10,
                  onTap: () {
                    ref.read(jobFiltersProvider.notifier).state = filters.radiusKm == 10
                        ? filters.copyWith(clearRadius: true)
                        : filters.copyWith(radiusKm: 10);
                  },
                ),
                _Chip(
                  label: filters.minPay == null ? 'Pay' : '₹${filters.minPay!.toInt()}+',
                  selected: filters.minPay != null,
                  onTap: () => _pickPay(context, ref, filters),
                ),
                _Chip(
                  label: filters.date == null ? 'Date' : '${filters.date!.day}/${filters.date!.month}',
                  selected: filters.date != null,
                  onTap: () {
                    if (filters.date != null) {
                      ref.read(jobFiltersProvider.notifier).state = filters.copyWith(clearDate: true);
                      return;
                    }
                    _pickDate(context, ref, filters);
                  },
                ),
                ...categories.maybeWhen(
                  data: (cats) => cats.map((c) => _Chip(
                        label: c.name,
                        selected: filters.category == c.slug,
                        onTap: () {
                          final selected = filters.category == c.slug;
                          ref.read(jobFiltersProvider.notifier).state = filters.copyWith(
                            category: selected ? null : c.slug,
                            clearCategory: selected,
                          );
                        },
                      )),
                  orElse: () => const <Widget>[],
                ),
                if (filters.hasActiveFilters)
                  _Chip(
                    label: 'Clear',
                    selected: false,
                    onTap: () => ref.read(jobFiltersProvider.notifier).state = const JobFilters(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => ref.invalidate(nearbyJobsProvider),
              child: jobs.when(
                loading: () => const LoadingView(label: 'Finding nearby work…'),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(nearbyJobsProvider)),
                data: (list) {
                  if (list.isEmpty) {
                    final hasFilters = filters.hasActiveFilters;
                    return EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      illustration: const EmptyJobsIllustration(),
                      title: hasFilters ? 'No jobs match these filters' : 'No jobs available yet',
                      subtitle: hasFilters
                          ? 'Try widening radius or clear pay / date filters.'
                          : 'Pull to refresh or check back later.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => JobCard(job: list[i], onTap: () => context.push('/jobs/${list[i].id}')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPay(BuildContext context, WidgetRef ref, JobFilters filters) async {
    final options = [null, 200.0, 500.0, 1000.0, 2000.0];
    final picked = await showModalBottomSheet<double?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Minimum pay', style: TextStyle(fontWeight: FontWeight.w800))),
            ...options.map((v) => ListTile(
                  title: Text(v == null ? 'Any pay' : '₹${v.toInt()}+'),
                  onTap: () => Navigator.pop(ctx, v ?? -1),
                )),
          ],
        ),
      ),
    );
    if (picked == null) return;
    ref.read(jobFiltersProvider.notifier).state = filters.copyWith(
      minPay: picked < 0 ? null : picked,
      clearPay: picked < 0,
    );
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref, JobFilters filters) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      initialDate: filters.date ?? now,
    );
    if (picked == null) {
      return;
    }
    ref.read(jobFiltersProvider.notifier).state = filters.copyWith(date: picked);
  }
}

class _BusinessJobsView extends ConsumerWidget {
  const _BusinessJobsView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(myJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My posted jobs'),
        actions: [
          IconButton(onPressed: () => context.go('/post'), icon: const Icon(Icons.add_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/post'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post job'),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => onRefresh(),
        child: jobs.when(
          loading: () => const LoadingView(label: 'Loading your jobs…'),
          error: (e, _) => ErrorView(error: e, onRetry: onRefresh),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyState(
                    icon: Icons.work_outline_rounded,
                    title: 'No jobs posted yet',
                    subtitle: 'Tap Post job to hire workers near you.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => JobCard(job: list[i], onTap: () => context.push('/jobs/${list[i].id}')),
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.accent,
        backgroundColor: AppColors.inputFill(context),
        checkmarkColor: AppColors.white,
        side: BorderSide.none,
      ),
    );
  }
}
