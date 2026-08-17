import 'package:flutter/material.dart';

/// ChatGPT visual language: charcoal surfaces, soft composer fills, green accent.
class AppColors {
  static const Color accent = Color(0xFF10A37F);
  static const Color accentHover = Color(0xFF1A7F64);
  static const Color accentSoft = Color(0xFFE6F6F1);

  static const Color black = Color(0xFF0D0D0D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F7F8);
  static const Color composer = Color(0xFFF4F4F4);
  static const Color muted = Color(0xFF6E6E80);
  static const Color border = Color(0xFFE5E5E5);
  static const Color chip = Color(0xFFF4F4F4);
  static const Color danger = Color(0xFFEF4444);

  static const Color darkBg = Color(0xFF212121);
  static const Color darkSidebar = Color(0xFF171717);
  static const Color darkSurface = Color(0xFF2F2F2F);
  static const Color darkComposer = Color(0xFF303030);
  static const Color darkBorder = Color(0xFF444444);
  static const Color darkText = Color(0xFFECECEC);
  static const Color darkMuted = Color(0xFFB4B4B4);

  static const Color primary = accent;
  static const Color primaryDark = accentHover;
  static const Color primaryLight = accentSoft;
  static const Color success = accent;
  static const Color warning = muted;
  static const Color info = muted;
  static const Color amber = accent;
  static const Color amberDark = accentHover;

  static Color canvas(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBg : white;
  }

  static Color panel(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurface : surface;
  }

  static Color inputFill(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkComposer : composer;
  }

  static Color label(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color hint(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkMuted : muted;
  }
}
