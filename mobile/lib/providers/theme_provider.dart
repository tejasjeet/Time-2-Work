import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref) : super(ThemeMode.dark) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final saved = await _ref.read(localStoreProvider).getThemeMode();
    if (saved != null) {
      state = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _ref.read(localStoreProvider).setThemeMode(
          mode == ThemeMode.dark ? 'dark' : 'light',
        );
  }

  Future<void> toggle() async {
    await setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
