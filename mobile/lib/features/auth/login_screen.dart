import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final raw = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _error = null);
    try {
      await ref.read(authProvider.notifier).sendOtp(raw);
      if (mounted) context.go('/otp');
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authProvider).busy;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => context.go('/onboarding'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: AppLogo(size: 72)),
              const SizedBox(height: 28),
              const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              const Text(
                'Enter your mobile number to continue',
                style: TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 24),
              const Text('Mobile number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                      color: AppColors.inputFill(context),
                    ),
                    child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phone,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 10,
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: 'Enter mobile number',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
                          borderSide: BorderSide(color: AppColors.accent, width: 1.4),
                        ),
                      ),
                      onSubmitted: (_) => busy ? null : _submit(),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              AppButton(label: 'Continue', loading: busy, onPressed: busy ? null : _submit),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with', style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 13)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _SocialButton(label: 'Apple', icon: Icons.apple_rounded)),
                ],
              ),
              const SizedBox(height: 28),
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

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SocialButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coming soon — use mobile number login')),
        );
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
