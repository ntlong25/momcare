import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/my_clinic.dart';

/// Persists "Nơi khám của tôi" as JSON under [AppConstants.myClinicKey].
class MyClinicService {
  static MyClinic decode(String? raw) {
    if (raw == null) return MyClinic.empty;
    try {
      return MyClinic.fromJson(jsonDecode(raw));
    } catch (_) {
      // Corrupt value: start fresh rather than crash.
      return MyClinic.empty;
    }
  }

  static String encode(MyClinic clinic) => jsonEncode(clinic.toJson());

  static Future<MyClinic> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(AppConstants.myClinicKey));
  }

  /// Saving an empty profile removes the key.
  static Future<void> save(MyClinic clinic) async {
    final prefs = await SharedPreferences.getInstance();
    if (clinic.isEmpty) {
      await prefs.remove(AppConstants.myClinicKey);
      return;
    }
    await prefs.setString(AppConstants.myClinicKey, encode(clinic));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.myClinicKey);
  }
}

/// Shared clinic profile for Cài đặt, Hôm nay and the emergency screen.
class MyClinicNotifier extends StateNotifier<MyClinic> {
  MyClinicNotifier() : super(MyClinic.empty) {
    _loading = _load();
  }

  late final Future<void> _loading;

  Future<void> _load() async {
    final clinic = await MyClinicService.load();
    if (mounted) state = clinic;
  }

  /// Completes once the persisted profile is loaded.
  Future<void> get ready => _loading;

  Future<void> save(MyClinic clinic) async {
    await _loading;
    state = clinic;
    await MyClinicService.save(clinic);
  }

  Future<void> clear() async {
    await _loading;
    state = MyClinic.empty;
    await MyClinicService.clear();
  }

  /// Clears the in-memory profile (the persisted one is removed by the
  /// caller, e.g. the delete-all-data flow).
  void resetLocal() {
    state = MyClinic.empty;
  }
}

final myClinicProvider = StateNotifierProvider<MyClinicNotifier, MyClinic>(
  (ref) => MyClinicNotifier(),
);
