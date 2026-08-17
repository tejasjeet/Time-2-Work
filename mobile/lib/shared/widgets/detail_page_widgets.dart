import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'marketplace_widgets.dart';
import 'widgets.dart';

class DetailSection extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;

  const DetailSection({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title, action: action, onAction: onAction),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class DetailHeroImage extends StatelessWidget {
  final String imageUrl;
  final String? badge;
  final double height;

  const DetailHeroImage({super.key, required this.imageUrl, this.badge, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FixtureImage(
          url: imageUrl,
          width: double.infinity,
          height: height,
          radius: BorderRadius.circular(16),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(left: 12, bottom: 12, child: StatusBadge(label: badge!)),
      ],
    );
  }
}

class DetailStatGrid extends StatelessWidget {
  final List<DetailStatItem> items;
  const DetailStatGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(height: 8),
                      Text(item.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      Text(item.label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class DetailStatItem {
  final IconData icon;
  final String label;
  final String value;
  const DetailStatItem({required this.icon, required this.label, required this.value});
}

class DetailGalleryStrip extends StatelessWidget {
  final List<String> urls;
  final String? moreLabel;

  const DetailGalleryStrip({super.key, required this.urls, this.moreLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isLast = i == urls.length - 1 && moreLabel != null;
          return Stack(
            alignment: Alignment.center,
            children: [
              FixtureImage(url: urls[i], width: 112, height: 96, radius: BorderRadius.circular(12)),
              if (isLast)
                Container(
                  width: 112,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(moreLabel!, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class DetailPosterCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double? rating;
  final String subtitle;
  final VoidCallback? onTap;

  const DetailPosterCard({
    super.key,
    required this.name,
    this.photoUrl,
    this.rating,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            AvatarCircle(name: name, url: photoUrl, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  if (rating != null)
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface),
                        Text(' ${rating!.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
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

class DetailInfoCard extends StatelessWidget {
  final String text;
  const DetailInfoCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(text, style: const TextStyle(height: 1.5)),
    );
  }
}

class DetailReviewCard extends StatelessWidget {
  final String name;
  final String text;
  final double rating;
  final String? photoUrl;

  const DetailReviewCard({
    super.key,
    required this.name,
    required this.text,
    required this.rating,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarCircle(name: name, url: photoUrl, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800))),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface),
                        Text(' ${rating.toStringAsFixed(1)}'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailSafetyBanner extends StatelessWidget {
  final String text;
  const DetailSafetyBanner({super.key, this.text = 'All verifications completed. Your safety comes first.'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.chip,
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35))),
        ],
      ),
    );
  }
}
