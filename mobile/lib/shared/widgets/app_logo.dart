import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showName;
  final Color? nameColor;
  final bool invertOnDark;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showName = true,
    this.nameColor,
    this.invertOnDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            'assets/images/logo.jpeg',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        if (showName) ...[
          SizedBox(height: size * 0.18),
          Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800,
              color: nameColor ?? (invertOnDark ? AppColors.white : Theme.of(context).colorScheme.onSurface),
              letterSpacing: -0.4,
            ),
          ),
        ],
      ],
    );
  }
}
