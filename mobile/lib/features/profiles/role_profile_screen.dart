import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/friendly_error.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';
import 'edit_profile_screen.dart';

class RoleProfileScreen extends ConsumerStatefulWidget {
  const RoleProfileScreen({super.key});

  @override
  ConsumerState<RoleProfileScreen> createState() => _RoleProfileScreenState();
}

class _RoleProfileScreenState extends ConsumerState<RoleProfileScreen> {
  bool? _availableNow;
  bool _availabilityBusy = false;

  Future<void> _setAvailability(bool value) async {
    setState(() {
      _availableNow = value;
      _availabilityBusy = true;
    });
    try {
      await ref.read(userRepositoryProvider).setAvailability(value);
      await ref.read(localStoreProvider).setAvailableNow(value);
      ref.invalidate(workerProfileProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _availableNow = !value);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _availabilityBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isWorker = user?.isWorker ?? true;
    final worker = ref.watch(workerProfileProvider);
    final business = ref.watch(businessProfileProvider);
    final muted = AppColors.hint(context);

    worker.whenData((p) {
      if (_availableNow == null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _availableNow == null) setState(() => _availableNow = p.availableNow);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              ProfileAvatar(name: user?.name, url: user?.photoUrl, size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Time2Work user', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    Text(isWorker ? 'Worker · Kaam dhundh rahe hain' : 'Business · Kaam post kar rahe hain', style: TextStyle(color: muted)),
                    if (user?.areaLabel != null) Text(user!.areaLabel!, style: TextStyle(color: muted)),
                    TextButton(
                      onPressed: () => context.push('/profile/edit'),
                      child: const Text('Edit profile / Profile badlein'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user?.about != null && user!.about!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(user.about!),
          ],
          const SizedBox(height: 16),
          if (isWorker)
            worker.when(
              loading: () => const LinearProgressIndicator(color: AppColors.accent),
              error: (_, __) => const SizedBox.shrink(),
              data: (p) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.skills.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.skills.map((s) => Chip(label: Text(s))).toList(),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppStrings.availableNow, style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(AppStrings.availableNowHi, style: TextStyle(color: muted)),
                    value: _availableNow ?? p.availableNow,
                    activeThumbColor: AppColors.white,
                    activeTrackColor: AppColors.accent,
                    onChanged: _availabilityBusy ? null : _setAvailability,
                  ),
                ],
              ),
            )
          else
            business.when(
              loading: () => const LinearProgressIndicator(color: AppColors.accent),
              error: (_, __) => const SizedBox.shrink(),
              data: (p) => Text(p.businessName ?? 'Business profile', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          const Divider(height: 32),
          _Link(icon: Icons.assignment_outlined, title: 'Applications', onTap: () => context.push('/applications')),
          _Link(icon: Icons.payments_outlined, title: 'Earnings', onTap: () => context.push('/earnings')),
          _Link(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () => context.push('/notifications')),
          _Link(icon: Icons.help_outline, title: 'Help', onTap: () => context.push('/help')),
          _Link(icon: Icons.sos_outlined, title: 'SOS / Aapatkaal', onTap: () => context.push('/sos')),
          _Link(icon: Icons.handyman_outlined, title: 'Local Services', onTap: () => context.push('/services')),
          _Link(icon: Icons.storefront_outlined, title: 'Local Bazar', onTap: () => context.push('/bazar')),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _Link({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
