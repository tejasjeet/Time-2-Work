import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/fixtures/app_fixtures.dart';
import '../../shared/widgets/detail_page_widgets.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class WorkerProfileScreen extends ConsumerWidget {
  final String workerId;
  const WorkerProfileScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = AppFixtures.workerById(workerId) ?? AppFixtures.workers.first;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Profile'),
        actions: [
          IconButton(onPressed: () => context.push('/saved'), icon: const Icon(Icons.bookmark_border_rounded)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          DetailHeroImage(imageUrl: worker.imageUrl, badge: worker.badge, height: 200),
          const SizedBox(height: 16),
          _ProfileHeader(worker: worker),
          const SizedBox(height: 24),
          DetailSection(
            title: 'About Me',
            child: DetailInfoCard(
              text: worker.about.isEmpty
                  ? 'Experienced ${worker.profession.toLowerCase()} serving nearby areas with reliable, on-time service.'
                  : worker.about,
            ),
          ),
          const SizedBox(height: 24),
          DetailSection(
            title: 'Services Offered',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (worker.skills.isEmpty ? ['Wiring', 'Repairs', 'Installation'] : worker.skills)
                  .map((s) => Chip(label: Text(s)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          DetailSection(
            title: 'Work Gallery',
            action: 'View All (24)',
            child: DetailGalleryStrip(urls: AppFixtures.workerGallery, moreLabel: '+19'),
          ),
          const SizedBox(height: 24),
          DetailSection(
            title: 'Reviews & Ratings',
            action: 'View All',
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${worker.rating}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: List.generate(5, (i) {
                          final star = 5 - i;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text('$star', style: const TextStyle(fontSize: 11)),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: star == 5 ? 0.82 : star == 4 ? 0.12 : 0.03,
                                    backgroundColor: AppColors.chip,
                                    color: onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const DetailReviewCard(
                  name: 'Rohit Kumar',
                  text: 'Excellent work! Very professional and completed the job on time.',
                  rating: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _InfoTile(icon: Icons.work_history_outlined, label: 'Experience', value: '${worker.experienceYears}+ Years'),
              _InfoTile(icon: Icons.payments_outlined, label: 'Hourly Rate', value: worker.priceRange),
              _InfoTile(icon: Icons.task_alt_outlined, label: 'Jobs Done', value: '${worker.jobsDone}+ Completed'),
              _InfoTile(icon: Icons.translate_rounded, label: 'Languages', value: worker.languages.join(', ')),
            ],
          ),
          const SizedBox(height: 24),
          DetailSection(
            title: 'Availability',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Today 8:00 AM - 9:00 PM', style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map(
                        (d) => Column(
                          children: [
                            Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: d == 'Sun' ? Colors.transparent : onSurface,
                                border: d == 'Sun' ? Border.all(color: AppColors.danger, width: 2) : null,
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DetailSection(
            title: 'Documents & Verification',
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Aadhaar', 'PAN', 'Police', 'Address']
                      .map((d) => Chip(avatar: Icon(Icons.verified, size: 16, color: onSurface), label: Text('$d Verified')))
                      .toList(),
                ),
                const SizedBox(height: 12),
                const DetailSafetyBanner(),
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
                  onPressed: () => context.push('/compare'),
                  icon: const Icon(Icons.compare_arrows_rounded),
                  label: const Text('Compare'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Book Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final FixtureWorker worker;
  const _ProfileHeader({required this.worker});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: FixtureImage(url: worker.imageUrl, width: 88, height: 88),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
                        if (worker.verified) Icon(Icons.verified, color: onSurface, size: 18),
                      ],
                    ),
                    Text(worker.profession, style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: onSurface, size: 16),
                        Text(' ${worker.rating} (${worker.reviews} reviews)', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Text('${worker.jobsDone} jobs done • ${worker.experienceYears}+ years'),
                    Text('Patna, Bihar • ${worker.distanceKm} km away'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DetailStatGrid(
            items: [
              DetailStatItem(icon: Icons.bolt_rounded, label: 'Response', value: worker.responseTime),
              DetailStatItem(icon: Icons.check_circle_outline, label: 'Completed', value: '${worker.jobsDone}+'),
              DetailStatItem(icon: Icons.calendar_month_outlined, label: 'Member', value: 'Apr 2020'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(worker.availability, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Chat'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Call'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: onSurface, size: 18),
          const Spacer(),
          Text(label, style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}
