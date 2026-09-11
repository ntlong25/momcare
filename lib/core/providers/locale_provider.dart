import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('vi')) {
    _loadLocale();
  }

  static const String _localeKey = 'locale';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, 'vi');
    state = const Locale('vi');
  }

  Future<void> setLocale(Locale locale) async {
    state = const Locale('vi');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, 'vi');
  }

  Future<void> toggleLocale() async {
    await setLocale(const Locale('vi'));
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
