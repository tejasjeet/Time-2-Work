import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../core/constants/app_colors.dart';

import '../../core/constants/app_strings.dart';

import '../../core/utils/friendly_error.dart';
import '../../providers/auth_provider.dart';

import '../../shared/widgets/app_logo.dart';

import '../../shared/widgets/widgets.dart';



class OtpScreen extends ConsumerStatefulWidget {

  const OtpScreen({super.key});



  @override

  ConsumerState<OtpScreen> createState() => _OtpScreenState();

}



class _OtpScreenState extends ConsumerState<OtpScreen> {

  final _controllers = List.generate(6, (_) => TextEditingController());

  final _nodes = List.generate(6, (_) => FocusNode());

  String? _error;



  @override

  void dispose() {

    for (final c in _controllers) {

      c.dispose();

    }

    for (final n in _nodes) {

      n.dispose();

    }

    super.dispose();

  }



  String get _code => _controllers.map((c) => c.text).join();



  Future<void> _submit() async {

    final code = _code.trim();

    if (code.length < 6) {

      setState(() => _error = 'Enter the 6-digit OTP');

      return;

    }

    setState(() => _error = null);

    try {

      await ref.read(authProvider.notifier).verifyOtp(code);

    } catch (e) {

      setState(() => _error = friendlyError(e));

    }

  }



  void _onChanged(int index, String value) {

    if (value.length > 1) {

      final digits = value.replaceAll(RegExp(r'\D'), '');

      for (var i = 0; i < digits.length && index + i < 6; i++) {

        _controllers[index + i].text = digits[i];

      }

      final next = (index + digits.length).clamp(0, 5);

      _nodes[next].requestFocus();

      return;

    }

    if (value.isNotEmpty && index < 5) {

      _nodes[index + 1].requestFocus();

    }

    if (value.isEmpty && index > 0) {

      _nodes[index - 1].requestFocus();

    }

  }



  @override

  Widget build(BuildContext context) {

    final auth = ref.watch(authProvider);

    final phone = auth.pendingPhone ?? '9876543210';

    final formatted = '+91 ${phone.substring(0, phone.length > 5 ? 5 : phone.length)} ${phone.length > 5 ? phone.substring(5) : ''}';



    return Scaffold(

      body: SafeArea(

        child: ListView(

          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),

          children: [

            IconButton(

              alignment: Alignment.centerLeft,

              padding: EdgeInsets.zero,

              onPressed: () => context.go('/login'),

              icon: const Icon(Icons.arrow_back_rounded),

            ),

            const SizedBox(height: 8),

            const Center(child: AppLogo(size: 72)),

            const SizedBox(height: 28),

            const Text('Verify your number', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),

            const SizedBox(height: 8),

            Text(

              "We've sent a 6-digit code to\n$formatted",

              style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.4),

            ),

            const SizedBox(height: 8),
            if (!kReleaseMode)
              Text(AppStrings.devOtpHint, style: TextStyle(color: AppColors.muted.withValues(alpha: 0.8), fontSize: 12)),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                final onSurface = Theme.of(context).colorScheme.onSurface;
                final fill = AppColors.inputFill(context);
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _nodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                    cursorColor: AppColors.accent,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: fill,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
                      ),
                    ),
                    onChanged: (v) => _onChanged(i, v),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            const Center(

              child: Text('Resend code in 00:25', style: TextStyle(color: AppColors.muted, fontSize: 13)),

            ),

            if (_error != null) ...[

              const SizedBox(height: 12),

              Text(_error!, style: const TextStyle(color: AppColors.danger)),

            ],

            const SizedBox(height: 32),

            AppButton(label: 'Verify & Continue', loading: auth.busy, onPressed: _submit),

            const SizedBox(height: 16),

            Center(

              child: TextButton(

                onPressed: () => context.go('/login'),

                child: const Text('Change mobile number', style: TextStyle(fontWeight: FontWeight.w600)),

              ),

            ),

          ],

        ),

      ),

    );

  }

}

