import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  /// Fresh install: follow the device until the user picks a theme.
  static const ThemeMode defaultMode = ThemeMode.system;

  ThemeNotifier() : super(defaultMode) {
    _loadTheme();
  }

  /// The brightness [mode] actually shows on a device set to
  /// [platformBrightness].
  static Brightness effectiveBrightness(
    ThemeMode mode,
    Brightness platformBrightness,
  ) => switch (mode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => platformBrightness,
  };

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(AppConstants.themeKey);
    state = themeIndex == null ? defaultMode : ThemeMode.values[themeIndex];
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.themeKey, mode.index);
  }

  /// Flips what the user currently sees; [platformBrightness] resolves
  /// [ThemeMode.system].
  Future<void> toggleTheme(Brightness platformBrightness) async {
    final isDark =
        effectiveBrightness(state, platformBrightness) == Brightness.dark;
    await setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  /// In-memory half of "Xóa toàn bộ dữ liệu"; the caller removes the pref.
  void resetLocal() {
    state = defaultMode;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
