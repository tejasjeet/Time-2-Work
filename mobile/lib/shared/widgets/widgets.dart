import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/fixtures/app_fixtures.dart';
import 'marketplace_widgets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/friendly_error.dart';
import '../../models/job.dart';

class AppButton extends StatelessWidget {
  final String label;
  final String? hindi;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.hindi,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final spinnerColor = outlined ? Theme.of(context).colorScheme.onSurface : AppColors.white;
    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label),
              if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20)],
            ],
          );

    if (outlined) {
      return OutlinedButton(onPressed: loading ? null : onPressed, child: child);
    }
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: color == null ? null : ElevatedButton.styleFrom(backgroundColor: color),
      child: child,
    );
  }
}

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscure;
  final Widget? prefix;
  final int? maxLength;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.obscure = false,
    this.prefix,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscure,
          maxLength: maxLength,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted),
            prefixIcon: prefix,
            counterText: '',
          ),
        ),
      ],
    );
  }
}

class LoadingView extends StatelessWidget {
  final String? label;
  const LoadingView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(label!, style: const TextStyle(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? illustration;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null) ...[
              illustration!,
              const SizedBox(height: 12),
            ] else
              Icon(icon, size: 48, color: AppColors.accent),
            if (illustration == null) const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.error, required this.onRetry});

  String get _message => friendlyError(error);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Could not load',
      subtitle: _message,
      action: AppButton(label: 'Retry', onPressed: onRetry),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const JobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pay = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(job.pay);
    final location = job.areaLabel ?? job.address ?? 'Nearby';
    final urgent = job.status.toLowerCase() == 'urgent' || job.workersRequired > 2;
    final imageUrl = AppFixtures.jobImageFor(job.category, title: job.title);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.panel(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FixtureImage(url: imageUrl, width: 72, height: 72),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (urgent)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('URGENT', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      Expanded(
                        child: Text(job.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${job.category.isEmpty ? 'Work' : job.category} • $location', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(job.date != null ? DateFormat.MMMd().format(job.date!) : 'Today', style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 12)),
                      const SizedBox(width: 12),
                      Text(pay, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}

class TeaserCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const TeaserCard({super.key, required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isDark ? onSurface : AppColors.white, size: 26),
              const SizedBox(height: 10),
              Text(title, style: TextStyle(color: isDark ? onSurface : AppColors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: isDark ? onSurface.withValues(alpha: 0.7) : Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  final String? url;
  final String? name;
  final double size;
  const AvatarCircle({super.key, this.url, this.name, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final safeName = (name ?? 'T').trim();
    final letter = safeName.isEmpty ? 'T' : safeName[0].toUpperCase();
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(context, letter),
        ),
      );
    }
    return _fallback(context, letter);
  }

  Widget _fallback(BuildContext context, String letter) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.chip,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final double size;
  const RatingStars({super.key, required this.value, this.onChanged, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          onPressed: onChanged == null ? null : () => onChanged!(star),
          iconSize: size,
          padding: const EdgeInsets.all(4),
          constraints: BoxConstraints.tight(Size(size + 8, size + 8)),
          icon: Icon(star <= value ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.accent),
        );
      }),
    );
  }
}

class MoneyText extends StatelessWidget {
  final num amount;
  final double size;
  const MoneyText(this.amount, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final text = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
    return Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800));
  }
}

class BilingualCta extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  const BilingualCta({super.key, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: AppStrings.iCanDoIt,
      hindi: AppStrings.iCanDoItHi,
      onPressed: onPressed,
      loading: loading,
      icon: Icons.handshake_outlined,
    );
  }
}
