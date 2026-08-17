import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/illustrations.dart';
import '../../shared/widgets/widgets.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ref.read(authProvider.notifier).completeOnboarding(),
                  child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const AppLogo(size: 72),
              const SizedBox(height: 24),
              const Text(
                'Local work. Real people.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: -0.4),
              ),
              const SizedBox(height: 10),
              const Text(
                'Find nearby jobs, hire trusted people, and discover services around you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.45),
              ),
              const SizedBox(height: 20),
              const Expanded(
                child: Center(child: OnboardingSticker()),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Log in',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  ref.read(authProvider.notifier).completeOnboarding();
                  context.go('/login');
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Create account',
                outlined: true,
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  ref.read(authProvider.notifier).completeOnboarding();
                  context.go('/login');
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'By continuing, you agree to our Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
