import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App mode enum
enum AppMode {
  prePregnancy, // Đang lên kế hoạch mang thai
  pregnancy,    // Đã mang thai
}

/// Mode notifier to manage app mode state
class AppModeNotifier extends StateNotifier<AppMode?> {
  AppModeNotifier() : super(null) {
    _loadMode();
  }

  static const String _modeKey = 'app_mode';

  /// Load saved mode from SharedPreferences
  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_modeKey);

    if (modeString != null) {
      state = modeString == 'prePregnancy'
          ? AppMode.prePregnancy
          : AppMode.pregnancy;
    }
  }

  /// Set app mode and save to SharedPreferences
  Future<void> setMode(AppMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _modeKey,
      mode == AppMode.prePregnancy ? 'prePregnancy' : 'pregnancy',
    );
  }

  /// Check if mode has been selected
  bool get hasSelectedMode => state != null;

  /// Switch to pregnancy mode (when user gets pregnant)
  Future<void> switchToPregnancy() async {
    await setMode(AppMode.pregnancy);
  }

  /// Switch to pre-pregnancy mode
  Future<void> switchToPrePregnancy() async {
    await setMode(AppMode.prePregnancy);
  }

  /// Clear mode selection (reset)
  Future<void> clearMode() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modeKey);
  }
}

/// Provider for app mode
final appModeProvider = StateNotifierProvider<AppModeNotifier, AppMode?>((ref) {
  return AppModeNotifier();
});

/// Helper to check if in pre-pregnancy mode
final isPrePregnancyProvider = Provider<bool>((ref) {
  final mode = ref.watch(appModeProvider);
  return mode == AppMode.prePregnancy;
});

/// Helper to check if in pregnancy mode
final isPregnancyProvider = Provider<bool>((ref) {
  final mode = ref.watch(appModeProvider);
  return mode == AppMode.pregnancy;
});
