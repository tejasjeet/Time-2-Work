import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

/// Approximate-area map. Never plots exact worker coordinates.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final jobs = ref.watch(nearbyJobsProvider);
    final radius = ref.watch(radiusKmProvider);
    final area = ref.read(locationServiceProvider).approximateArea(lat: user?.lat, lng: user?.lng);

    return Scaffold(
      appBar: AppBar(title: const Text('Map (approx.)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: CustomPaint(
              painter: _ApproxMapPainter(radiusKm: radius.toDouble()),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.blur_circular, size: 40, color: AppColors.black),
                    const SizedBox(height: 8),
                    Text('You · $area', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('$radius KM radius', style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Exact worker pins are never shown. Jobs appear as distance + area only.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          jobs.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(nearbyJobsProvider)),
            data: (list) => Column(
              children: list.take(12).map((j) {
                final dist = j.distanceKm != null ? '${j.distanceKm!.toStringAsFixed(1)} KM' : 'Nearby';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: AppColors.chip, child: Icon(Icons.work_outline, color: AppColors.black)),
                  title: Text(j.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('$dist · ${j.areaLabel ?? 'Approximate area'}'),
                  onTap: () => context.push('/jobs/${j.id}'),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproxMapPainter extends CustomPainter {
  final double radiusKm;
  _ApproxMapPainter({required this.radiusKm});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bg = Paint()..color = const Color(0xFFF3F4F6);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)), bg);

    final ring = Paint()
      ..color = AppColors.amber.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final maxR = size.shortestSide * 0.42;
    canvas.drawCircle(center, maxR, ring);
    canvas.drawCircle(center, maxR * (radiusKm <= 5 ? 0.62 : 0.92), Paint()..color = AppColors.amber.withOpacity(0.22));
    canvas.drawCircle(center, 10, Paint()..color = AppColors.black);
  }

  @override
  bool shouldRepaint(covariant _ApproxMapPainter oldDelegate) => oldDelegate.radiusKm != radiusKm;
}
