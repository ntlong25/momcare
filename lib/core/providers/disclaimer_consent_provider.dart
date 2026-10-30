import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Whether the current disclaimer version has been accepted: null while
/// loading. Only [AppConstants.disclaimerVersion] counts, so raising that
/// constant asks everyone again.
class DisclaimerConsentNotifier extends StateNotifier<bool?> {
  DisclaimerConsentNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state =
        prefs.getInt(AppConstants.disclaimerAcceptedVersionKey) ==
        AppConstants.disclaimerVersion;
  }

  /// Stores the accepted version and when it was accepted.
  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.disclaimerAcceptedVersionKey,
      AppConstants.disclaimerVersion,
    );
    await prefs.setString(
      AppConstants.disclaimerAcceptedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    state = true;
  }

  /// In-memory half of "Xóa toàn bộ dữ liệu"; the caller removes the prefs.
  void resetLocal() {
    state = false;
  }
}

final disclaimerConsentProvider =
    StateNotifierProvider<DisclaimerConsentNotifier, bool?>(
      (ref) => DisclaimerConsentNotifier(),
    );
