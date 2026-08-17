import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/fixtures/app_fixtures.dart';

class FixtureImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;

  const FixtureImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.chip,
        child: const Center(child: Icon(Icons.image_outlined, color: AppColors.muted)),
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: AppColors.primaryLight,
        child: const Icon(Icons.broken_image_outlined, color: AppColors.primary),
      ),
    );
    if (radius != null) {
      return ClipRRect(borderRadius: radius!, child: image);
    }
    return image;
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.chip,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        label,
        style: TextStyle(color: onSurface, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionTitle({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

class CategoryCircle extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const CategoryCircle({super.key, required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkSurface : AppColors.surface,
              ),
              child: Icon(icon, size: 22, color: AppColors.accent),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.panel(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.accent, size: 24),
              const Spacer(),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: onSurface, fontSize: 13, height: 1.2)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkerCarouselCard extends StatelessWidget {
  final FixtureWorker worker;
  final bool saved;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const WorkerCarouselCard({
    super.key,
    required this.worker,
    this.saved = false,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.panel(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                FixtureImage(
                  url: worker.imageUrl,
                  height: 120,
                  width: double.infinity,
                  radius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                Positioned(top: 8, left: 8, child: StatusBadge(label: worker.badge)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onSave,
                    icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: saved ? AppColors.danger : AppColors.white),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                      if (worker.verified) const Icon(Icons.verified, color: AppColors.accent, size: 16),
                    ],
                  ),
                  Text(worker.profession, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.onSurface, size: 16),
                      Text(' ${worker.rating} (${worker.reviews})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const Spacer(),
                      Text('${worker.distanceKm} km', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(worker.priceRange, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.chip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      worker.availability,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceListTile extends StatelessWidget {
  final FixtureService service;
  final VoidCallback? onTap;

  const ServiceListTile({super.key, required this.service, this.onTap});

  IconData _icon(IconKey key) {
    switch (key) {
      case IconKey.electrical:
        return Icons.bolt_rounded;
      case IconKey.plumbing:
        return Icons.plumbing_rounded;
      case IconKey.painting:
        return Icons.format_paint_rounded;
      default:
        return Icons.home_repair_service_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.panel(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            FixtureImage(url: service.imageUrl, width: 64, height: 64, radius: BorderRadius.circular(12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_icon(service.icon), color: Theme.of(context).colorScheme.onSurface, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(service.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                    ],
                  ),
                  Text(service.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
                      Text(' ${service.rating}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text('Starting at ${service.startingPrice}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.bookmark, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class SavedJobTile extends StatelessWidget {
  final FixtureSavedJob job;
  final VoidCallback? onTap;

  const SavedJobTile({super.key, required this.job, this.onTap});

  Color _color(ColorKey key) => AppColors.muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.panel(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _color(job.color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.work_outline_rounded, color: _color(job.color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (job.urgent)
                    const Text('Urgent', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 11)),
                  Text(job.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text('${job.location} • ${job.postedAgo}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${job.applications} Applications', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 12)),
                      const Spacer(),
                      Text('Budget: ${job.budget}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.bookmark, color: Theme.of(context).colorScheme.onSurface),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class SearchResultCard extends StatelessWidget {
  final FixtureWorker worker;
  final VoidCallback? onTap;
  final VoidCallback? onCompare;

  const SearchResultCard({super.key, required this.worker, this.onTap, this.onCompare});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    FixtureImage(url: worker.imageUrl, width: 88, height: 88, radius: BorderRadius.circular(12)),
                    Positioned(top: 4, left: 4, child: StatusBadge(label: worker.badge)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                          if (worker.verified) Icon(Icons.verified, color: Theme.of(context).colorScheme.onSurface, size: 18),
                        ],
                      ),
                      Text('${worker.experienceYears}+ years experience', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.onSurface, size: 16),
                          Text(' ${worker.rating} (${worker.reviews} reviews)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                      Text(worker.skills.take(3).join(' • '), style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.chip,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⚡ ${worker.availability} • ${worker.responseTime}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${worker.distanceKm} km away', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    const Icon(Icons.favorite_border, color: AppColors.muted),
                    const SizedBox(height: 8),
                    Text(worker.startingPrice, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const Text('Starting price', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                    Text('${worker.jobsDone} jobs done', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Chat'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Call'))),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onTap,
                  child: const Text('Book Now'),
                ),
              ),
            ],
          ),
          if (onCompare != null)
            TextButton(onPressed: onCompare, child: const Text('Add to Compare')),
        ],
      ),
    );
  }
}

IconData categoryIcon(IconKey key) {
  switch (key) {
    case IconKey.electrical:
      return Icons.bolt_rounded;
    case IconKey.plumbing:
      return Icons.plumbing_rounded;
    case IconKey.painting:
      return Icons.format_paint_rounded;
    case IconKey.cleaning:
      return Icons.cleaning_services_rounded;
    case IconKey.tutor:
      return Icons.menu_book_rounded;
    case IconKey.driver:
      return Icons.directions_car_filled_rounded;
    case IconKey.briefcase:
      return Icons.work_outline_rounded;
    case IconKey.ac:
      return Icons.ac_unit_rounded;
    case IconKey.salon:
      return Icons.content_cut_rounded;
    default:
      return Icons.grid_view_rounded;
  }
}

class ComposerSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool readOnly;
  final ValueChanged<String>? onSubmitted;

  const ComposerSearchBar({
    super.key,
    this.hint = 'Search for a service',
    this.onTap,
    this.controller,
    this.readOnly = true,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.hint(context);
    return Material(
      color: AppColors.inputFill(context),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: readOnly ? onTap : null,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: muted, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: IgnorePointer(
                  ignoring: readOnly,
                  child: TextField(
                    controller: controller,
                    readOnly: readOnly,
                    onTap: onTap,
                    onSubmitted: onSubmitted,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: hint,
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_upward_rounded, color: AppColors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryGridTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const CategoryGridTile({super.key, required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 26, color: AppColors.accent),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.label(context)),
          ),
        ],
      ),
    );
  }
}

class GptPromoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const GptPromoBanner({
    super.key,
    this.title = 'Trusted help, 5 KM away',
    this.subtitle = 'Book electricians, plumbers, cleaners and more nearby.',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSidebar : AppColors.black,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('NEW', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                  ),
                  const SizedBox(height: 10),
                  Text(title, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.25)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: AppColors.white.withValues(alpha: 0.68), fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
