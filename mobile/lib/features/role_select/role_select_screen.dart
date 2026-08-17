import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/widgets.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const Center(child: AppLogo(size: 64)),
            const SizedBox(height: 24),
            const Text(
              'How do you want to use Time2Work?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the option that best describes you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            const SizedBox(height: 24),
            _RoleCard(
              selected: _selected == 'worker',
              icon: Icons.work_outline_rounded,
              title: "I'm looking for work",
              body: 'Find jobs near you, connect with people and grow your career.',
              chips: const ['Find Jobs', 'Apply', 'Connect', 'Grow'],
              onTap: () => setState(() => _selected = 'worker'),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              selected: _selected == 'business',
              icon: Icons.groups_outlined,
              title: 'I want to hire',
              body: 'Post work, find trusted people and get things done.',
              chips: const ['Post Work', 'Find People', 'Chat', 'Manage'],
              onTap: () => setState(() => _selected = 'business'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Safe. Verified. Local.', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text(
                          'Time2Work keeps your data safe and connects you with verified people in your area.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: _selected == null ? null : () => ref.read(authProvider.notifier).selectRole(_selected!),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final List<String> chips;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.body,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.accent : Theme.of(context).dividerColor, width: selected ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(body, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.3)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: selected ? AppColors.accent : AppColors.muted),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.chip,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(c, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
