import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/location/location_places.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/illustrations.dart';
import '../../shared/widgets/widgets.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen> {
  String? _error;
  bool _busy = false;
  bool _precise = true;
  double? _lat;
  double? _lng;
  String _label = 'Detecting location…';

  @override
  void initState() {
    super.initState();
    _refreshLocation(showErrors: false);
  }

  Future<void> _refreshLocation({bool showErrors = true}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final loc = await ref.read(locationServiceProvider).current(precise: _precise);
    if (!mounted) return;
    if (loc == null) {
      setState(() {
        _busy = false;
        _lat = 25.5941;
        _lng = 85.1376;
        _label = 'Patna, Bihar';
        if (showErrors) _error = 'Could not detect GPS. Using Patna as default.';
      });
      return;
    }
    setState(() {
      _busy = false;
      _lat = loc.lat;
      _lng = loc.lng;
      _label = cityLabelFor(loc.lat, loc.lng);
    });
  }

  Future<void> _allow() async {
    if (_lat == null || _lng == null) {
      await _refreshLocation();
    }
    if (_lat == null || _lng == null) return;
    setState(() => _busy = true);
    await ref.read(authProvider.notifier).saveLocation(lat: _lat!, lng: _lng!);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _usePatna() async {
    setState(() {
      _lat = 25.5941;
      _lng = 85.1376;
      _label = 'Patna, Bihar';
    });
    await ref.read(authProvider.notifier).saveLocation(lat: 25.5941, lng: 85.1376);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded)),
                const Spacer(),
                TextButton(onPressed: _busy ? null : _usePatna, child: const Text('Skip')),
              ],
            ),
            const Center(child: AppLogo(size: 64)),
            const SizedBox(height: 24),
            const Text(
              "Let's find work near you",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Allow location access to see nearby jobs, services and opportunities.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 20),
            const LocationSticker(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.location_on_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your current location', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(_label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                      TextButton(onPressed: _busy ? null : () => _refreshLocation(), child: const Text('Change')),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.my_location_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Use precise location', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            const Text('Get better results for near you.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _precise,
                        activeThumbColor: AppColors.white,
                        activeTrackColor: AppColors.black,
                        onChanged: _busy
                            ? null
                            : (v) {
                                setState(() => _precise = v);
                                _refreshLocation(showErrors: false);
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 16, color: AppColors.muted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'We never share your location with anyone. Your privacy is our priority.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: 'Allow Location Access',
              loading: _busy,
              icon: Icons.arrow_forward_rounded,
              onPressed: _allow,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _usePatna,
                child: const Text("I'll set location manually"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
