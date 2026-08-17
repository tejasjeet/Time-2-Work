import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final radius = ref.watch(radiusKmProvider);
    final role = user?.role ?? 'worker';
    final isWorker = user?.isWorker ?? true;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark mode'),
            subtitle: Text(isDark ? 'Dark theme enabled' : 'Light theme enabled'),
            secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
            value: isDark,
            activeThumbColor: AppColors.white,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(height: 20),
          const Text('Active role', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(
            isWorker ? 'Find and apply for local work.' : 'Post jobs and hire workers near you.',
            style: TextStyle(color: AppColors.hint(context), fontSize: 13),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'worker', label: Text('Worker'), icon: Icon(Icons.engineering_outlined)),
              ButtonSegment(value: 'business', label: Text('Business'), icon: Icon(Icons.storefront_outlined)),
            ],
            selected: {role == 'business' ? 'business' : 'worker'},
            onSelectionChanged: (s) async {
              final next = s.first;
              if (next == role) return;
              await ref.read(authProvider.notifier).switchRole(next);
              ref.invalidate(workerProfileProvider);
              ref.invalidate(businessProfileProvider);
              ref.invalidate(nearbyJobsProvider);
              ref.invalidate(myJobsProvider);
              ref.invalidate(myApplicationsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(next == 'business' ? 'Switched to Business mode' : 'Switched to Worker mode')),
                );
              }
            },
          ),
          if (isWorker) ...[
            const SizedBox(height: 20),
            const Text('Preferred radius', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('Used when you tap 5 KM / 10 KM on the Jobs tab.', style: TextStyle(color: AppColors.hint(context), fontSize: 13)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 5, label: Text('5 KM')),
                ButtonSegment(value: 10, label: Text('10 KM')),
              ],
              selected: {radius == 10 ? 10 : 5},
              onSelectionChanged: (s) async {
                final km = s.first;
                ref.read(radiusKmProvider.notifier).state = km;
                await ref.read(localStoreProvider).setRadiusKm(km);
              },
            ),
          ],
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: const Text('Help'),
            onTap: () => context.push('/help'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.sos_outlined),
            title: const Text('SOS / Aapatkaal'),
            onTap: () => context.push('/sos'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Log out / Logout karein'),
          ),
        ],
      ),
    );
  }
}
