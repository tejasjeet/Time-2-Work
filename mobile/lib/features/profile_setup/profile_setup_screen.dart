import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/location/location_places.dart';
import '../../providers/auth_provider.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/illustrations.dart';
import '../../shared/widgets/widgets.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  String? _error;
  String? _photoLabel;
  String _role = 'worker';
  double _lat = 25.5941;
  double _lng = 85.1376;
  String _locationLabel = 'Patna, Bihar';
  bool _busyLocation = false;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _busyLocation = true);
    final loc = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    if (loc != null) {
      setState(() {
        _lat = loc.lat;
        _lng = loc.lng;
        _locationLabel = cityLabelFor(loc.lat, loc.lng);
        _busyLocation = false;
      });
      return;
    }
    setState(() => _busyLocation = false);
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Please enter your full name');
      return;
    }
    setState(() => _error = null);
    await ref.read(authProvider.notifier).saveProfile(
          name: _name.text.trim(),
          about: null,
          photoUrl: null,
        );
    await ref.read(authProvider.notifier).selectRole(_role);
    await ref.read(authProvider.notifier).saveLocation(lat: _lat, lng: _lng);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authProvider).busy;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const SizedBox(height: 8),
            const Center(child: AppLogo(size: 64)),
            const SizedBox(height: 24),
            const Text("Let's set up your profile", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Tell us a bit about yourself to personalize your experience.',
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            const SizedBox(height: 20),
            const Center(child: ProfileSetupIllustration()),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap: () async {
                      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (file != null) setState(() => _photoLabel = file.name);
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: AppColors.chip,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        _photoLabel == null ? Icons.person_outline_rounded : Icons.check_rounded,
                        size: 52,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _photoLabel == null ? 'Add profile photo' : 'Selected: $_photoLabel',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            AppField(controller: _name, label: 'Full name', hint: 'Enter your full name'),
            const SizedBox(height: 20),
            const Text('I am using Time2Work as', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _RoleTile(
                    selected: _role == 'worker',
                    icon: Icons.work_outline_rounded,
                    title: "I'm looking for work",
                    subtitle: 'Find jobs and opportunities',
                    onTap: () => setState(() => _role = 'worker'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleTile(
                    selected: _role == 'business',
                    icon: Icons.person_outline_rounded,
                    title: 'I want to hire',
                    subtitle: 'Post work and hire people',
                    onTap: () => setState(() => _role = 'business'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
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
                        const Text('Location', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          _busyLocation ? 'Detecting…' : _locationLabel,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _busyLocation ? null : _detectLocation,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 28),
            AppButton(label: 'Continue', loading: busy, icon: Icons.arrow_forward_rounded, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.accent : Theme.of(context).dividerColor, width: selected ? 1.6 : 1),
          color: selected ? AppColors.inputFill(context) : Theme.of(context).cardTheme.color,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.2)),
          ],
        ),
      ),
    );
  }
}
