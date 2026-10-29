import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists optional shopping / hospital-bag item prices (VND) as a JSON map
/// `{itemId: int}` (see `GuideProgressService`).
class GuidePriceService {
  static Map<String, int> decode(String? raw) {
    if (raw == null) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      final result = <String, int>{};
      decoded.forEach((key, value) {
        if (key is String && key.isNotEmpty && value is int && value > 0) {
          result[key] = value;
        }
      });
      return result;
    } catch (_) {
      // Corrupt value: start fresh rather than crash.
      return <String, int>{};
    }
  }

  static String encode(Map<String, int> prices) {
    final ids = prices.keys.toList()..sort();
    return jsonEncode({for (final id in ids) id: prices[id]});
  }

  static Future<Map<String, int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(AppConstants.guidePricesKey));
  }

  static Future<void> save(Map<String, int> prices) async {
    final prefs = await SharedPreferences.getInstance();
    if (prices.isEmpty) {
      await prefs.remove(AppConstants.guidePricesKey);
      return;
    }
    await prefs.setString(AppConstants.guidePricesKey, encode(prices));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.guidePricesKey);
  }
}

/// Shared item prices for the guide detail screen.
class GuidePriceNotifier extends StateNotifier<Map<String, int>> {
  GuidePriceNotifier() : super(const <String, int>{}) {
    _loading = _load();
  }

  late final Future<void> _loading;

  Future<void> _load() async {
    final prices = await GuidePriceService.load();
    if (mounted) state = prices;
  }

  /// Completes once persisted prices are loaded.
  Future<void> get ready => _loading;

  /// Sets the price of [itemId]; null or <= 0 removes it.
  Future<void> setPrice(String itemId, int? price) async {
    await _loading;
    final next = {...state};
    if (price == null || price <= 0) {
      next.remove(itemId);
    } else {
      next[itemId] = price;
    }
    state = next;
    await GuidePriceService.save(next);
  }

  /// Clears in-memory prices (persisted prices are removed by the caller,
  /// e.g. the delete-all-data flow).
  void resetLocal() {
    state = const <String, int>{};
  }
}

final guidePriceProvider =
    StateNotifierProvider<GuidePriceNotifier, Map<String, int>>(
      (ref) => GuidePriceNotifier(),
    );
