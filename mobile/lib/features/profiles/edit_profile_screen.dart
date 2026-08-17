import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/friendly_error.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _about;
  late final TextEditingController _extra;
  late final TextEditingController _name;
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _name = TextEditingController(text: user?.name ?? 'Time2Work user');
    _about = TextEditingController(text: user?.about ?? '');
    _extra = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authProvider).user;
    final isWorker = user?.isWorker ?? true;
    final localPhoto = await ref.read(localStoreProvider).getProfilePhotoPath();
    if (mounted && localPhoto != null) setState(() => _photoPath = localPhoto);

    try {
      if (isWorker) {
        final p = await ref.read(userRepositoryProvider).getWorkerProfile();
        if (!mounted) return;
        _about.text = p.about ?? user?.about ?? '';
        _extra.text = p.skills.join(', ');
        setState(() {});
      } else {
        final p = await ref.read(userRepositoryProvider).getBusinessProfile();
        if (!mounted) return;
        _about.text = p.about ?? user?.about ?? '';
        _extra.text = p.businessName ?? '';
        setState(() {});
      }
    } catch (_) {
      // Keep user-level fields if profile API is unavailable.
    }
  }

  @override
  void dispose() {
    _about.dispose();
    _extra.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file == null) return;
    setState(() => _photoPath = file.path);
  }

  Future<void> _save() async {
    final user = ref.read(authProvider).user;
    final isWorker = user?.isWorker ?? true;
    setState(() => _saving = true);
    try {
      if (_photoPath != null) {
        await ref.read(localStoreProvider).setProfilePhotoPath(_photoPath);
        ref.invalidate(profilePhotoPathProvider);
      }
      final about = _about.text.trim();
      if (isWorker) {
        final skills = _extra.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        await ref.read(userRepositoryProvider).putWorkerProfile({
          'bio': about,
          'skills': skills,
        });
        ref.invalidate(workerProfileProvider);
      } else {
        await ref.read(userRepositoryProvider).putBusinessProfile({
          'description': about,
          'businessName': _extra.text.trim(),
        });
        ref.invalidate(businessProfileProvider);
      }
      await ref.read(userRepositoryProvider).updateMe(about: about);
      await ref.read(authProvider.notifier).refreshMe();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isWorker = user?.isWorker ?? true;
    final muted = AppColors.hint(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  onTap: _pickPhoto,
                  customBorder: const CircleBorder(),
                  child: _photoPath != null
                      ? ClipOval(
                          child: Image.file(File(_photoPath!), width: 112, height: 112, fit: BoxFit.cover),
                        )
                      : ProfileAvatar(name: user?.name, url: user?.photoUrl, size: 112),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('Tap photo to change', style: TextStyle(color: muted, fontSize: 13))),
          const SizedBox(height: 28),
          Text('Full name', style: TextStyle(fontWeight: FontWeight.w600, color: muted, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            readOnly: true,
            style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.inputFill(context),
              hintText: 'Name cannot be changed here',
              suffixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: muted),
            ),
          ),
          const SizedBox(height: 20),
          AppField(
            controller: _about,
            label: 'About / description',
            hint: 'Tell people about your work and experience',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          AppField(
            controller: _extra,
            label: isWorker ? 'Skills (comma separated)' : 'Business name',
            hint: isWorker ? 'Electrician, Wiring, Repairs' : 'Your shop or company name',
          ),
          const SizedBox(height: 28),
          AppButton(label: 'Save changes', loading: _saving, onPressed: _saving ? null : _save),
        ],
      ),
    );
  }
}

class ProfileAvatar extends ConsumerWidget {
  final String? name;
  final String? url;
  final double size;

  const ProfileAvatar({super.key, this.name, this.url, this.size = 72});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localPath = ref.watch(profilePhotoPathProvider).valueOrNull;
    if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      return ClipOval(
        child: Image.file(File(localPath), width: size, height: size, fit: BoxFit.cover),
      );
    }
    return AvatarCircle(name: name, url: url, size: size);
  }
}

final profilePhotoPathProvider = FutureProvider<String?>((ref) async {
  return ref.watch(localStoreProvider).getProfilePhotoPath();
});
