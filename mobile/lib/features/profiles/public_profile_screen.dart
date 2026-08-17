import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/fixtures/app_fixtures.dart';
import '../../core/network/json_helpers.dart';
import '../../models/review.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/detail_page_widgets.dart';
import '../../shared/widgets/marketplace_widgets.dart';
import '../../shared/widgets/widgets.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(userId));
    final extraReviews = ref.watch(userReviewsProvider(userId));
    return Scaffold(
      body: profile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(publicProfileProvider(userId))),
        data: (map) {
          final sanitized = Map<String, dynamic>.from(map)
            ..remove('phone')
            ..remove('phoneNumber')
            ..remove('mobile');
          final name = readString(sanitized, ['name', 'displayName', 'businessName']) ?? 'Member';
          final about = readString(sanitized, ['about', 'bio']) ?? '';
          final photo = readString(sanitized, ['photoUrl', 'avatar']);
          final area = readString(sanitized, ['areaLabel', 'area', 'locality']) ?? 'Approximate area';
          final rating = readDouble(sanitized['rating']);
          final role = readString(sanitized, ['role']) ?? 'Member';
          final reviewsRaw = sanitized['reviews'];
          final reviews = reviewsRaw is List
              ? reviewsRaw.whereType<Map>().map((e) => Review.fromJson(asMap(e))).toList()
              : <Review>[];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                actions: [
                  IconButton(onPressed: () => context.push('/report/$userId'), icon: const Icon(Icons.flag_outlined)),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      FixtureImage(url: AppFixtures.profileCover, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -36),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AvatarCircle(name: name, url: photo, size: 88),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                                    Text('$role • $area', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                                    if (rating != null)
                                      Row(
                                        children: [
                                          Icon(Icons.star_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface),
                                          Text(' ${rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (about.isNotEmpty)
                        DetailSection(title: 'About', child: DetailInfoCard(text: about))
                      else
                        DetailSection(title: 'About', child: DetailInfoCard(text: 'Active member on Time2Work near you.')),
                      const SizedBox(height: 24),
                      DetailSection(
                        title: 'Work photos',
                        child: DetailGalleryStrip(urls: AppFixtures.workerGallery.take(4).toList(), moreLabel: '+8'),
                      ),
                      const SizedBox(height: 24),
                      DetailSection(
                        title: 'Reviews',
                        child: Column(
                          children: [
                            if (reviews.isEmpty)
                              extraReviews.when(
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const DetailReviewCard(name: 'No reviews yet', text: 'Complete a job to receive reviews.', rating: 0),
                                data: (list) => list.isEmpty
                                    ? const DetailReviewCard(name: 'No reviews yet', text: 'Complete a job to receive reviews.', rating: 0)
                                    : Column(
                                        children: list
                                            .take(3)
                                            .map((r) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 10),
                                                  child: DetailReviewCard(
                                                    name: r.fromName ?? 'Reviewer',
                                                    text: r.text,
                                                    rating: r.rating.toDouble(),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                              ),
                            ...reviews.take(3).map(
                                  (r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: DetailReviewCard(
                                      name: r.fromName ?? 'Reviewer',
                                      text: r.text,
                                      rating: r.rating.toDouble(),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const DetailSafetyBanner(text: 'Report or block if something feels unsafe.'),
                      const SizedBox(height: 12),
                      AppButton(label: 'Report / Block', outlined: true, onPressed: () => context.push('/report/$userId')),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
