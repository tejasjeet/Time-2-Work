import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AssetIllustration extends StatelessWidget {
  final String asset;
  final double height;
  final BoxFit fit;

  const AssetIllustration({
    super.key,
    required this.asset,
    this.height = 220,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        asset,
        height: height,
        width: double.infinity,
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _Fallback(height: height, label: 'Image unavailable'),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final double height;
  final String label;

  const _Fallback({required this.height, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 48, color: AppColors.muted),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

class LocationSticker extends StatelessWidget {
  const LocationSticker({super.key});

  @override
  Widget build(BuildContext context) {
    return const AssetIllustration(
      asset: 'assets/images/location_art.png',
      height: 200,
    );
  }
}

class OnboardingSticker extends StatelessWidget {
  const OnboardingSticker({super.key});

  @override
  Widget build(BuildContext context) {
    return const AssetIllustration(
      asset: 'assets/images/onboarding_art.png',
      height: 220,
    );
  }
}

class ProfileSetupIllustration extends StatelessWidget {
  const ProfileSetupIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const AssetIllustration(
      asset: 'assets/images/onboarding_art.png',
      height: 160,
    );
  }
}

class EmptyJobsIllustration extends StatelessWidget {
  const EmptyJobsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/empty_jobs_art.png',
      height: 140,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.work_off_outlined, size: 64, color: AppColors.muted),
    );
  }
}
