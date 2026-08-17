import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  bool _busy = false;
  String? _result;

  Future<void> _confirmAndSend() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send SOS?'),
        content: const Text(
          'This will share your current location with Time2Work emergency support. Only use in a real emergency.\n\nKya aap sure hain?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('I understand', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final ok2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final confirm / Antim pushti'),
        content: const Text('Tap SEND SOS to alert support now.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Go back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: AppColors.white),
            child: const Text('SEND SOS'),
          ),
        ],
      ),
    );
    if (ok2 != true) return;

    setState(() => _busy = true);
    try {
      final loc = await ref.read(locationServiceProvider).current();
      final user = ref.read(authProvider).user;
      final lat = loc?.lat ?? user?.lat ?? 0;
      final lng = loc?.lng ?? user?.lng ?? 0;
      await ref.read(userRepositoryProvider).sos(lat: lat, lng: lng, note: 'SOS from Time2Work app');
      setState(() => _result = 'SOS sent. Help has been notified with your location.');
    } catch (e) {
      setState(() => _result = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS / Aapatkaal')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          children: [
            const Icon(Icons.sos, size: 72, color: AppColors.danger),
            const SizedBox(height: 16),
            const Text('Emergency help', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'We will send your location to Time2Work support. You will confirm twice before anything is sent.',
              textAlign: TextAlign.center,
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(_result!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
            const Spacer(),
            AppButton(
              label: 'SOS — double confirm',
              hindi: 'Do baar confirm karein',
              color: AppColors.danger,
              loading: _busy,
              onPressed: _confirmAndSend,
            ),
          ],
        ),
      ),
    );
  }
}
