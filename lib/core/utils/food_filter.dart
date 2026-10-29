import '../models/food_model.dart';
import 'vietnamese_text.dart';

/// Search and filters for the "Bầu ăn được không?" lookup.
class FoodFilter {
  /// Items matching [query] (accent-insensitive substring of the name or an
  /// alias), [verdict] and [group] (null = any; all conditions combine with
  /// AND). Items whose name or alias starts with the query come first; ties
  /// are sorted by normalised name, then id.
  static List<FoodItem> apply(
    List<FoodItem> items, {
    String query = '',
    FoodVerdict? verdict,
    String? group,
  }) {
    final needle = normalizeVi(query);
    final matches = <_Match>[];
    for (final item in items) {
      if (verdict != null && item.verdict != verdict) continue;
      if (group != null && item.group != group) continue;
      final name = normalizeVi(item.name);
      if (needle.isEmpty) {
        matches.add(_Match(item, name, false));
        continue;
      }
      final terms = [name, ...item.aliases.map(normalizeVi)];
      if (!terms.any((term) => term.contains(needle))) continue;
      matches.add(
        _Match(item, name, terms.any((term) => term.startsWith(needle))),
      );
    }
    matches.sort((a, b) {
      if (a.prefix != b.prefix) return a.prefix ? -1 : 1;
      final byName = a.name.compareTo(b.name);
      return byName != 0 ? byName : a.item.id.compareTo(b.item.id);
    });
    return [for (final match in matches) match.item];
  }

  /// Groups present in [items], in [FoodGroups.labels] order; unknown groups
  /// follow, sorted by key.
  static List<String> groupsIn(List<FoodItem> items) {
    final present = items.map((item) => item.group).toSet();
    final known = FoodGroups.labels.keys.where(present.contains).toList();
    final unknown =
        present.where((g) => !FoodGroups.labels.containsKey(g)).toList()
          ..sort();
    return [...known, ...unknown];
  }
}

class _Match {
  final FoodItem item;
  final String name;
  final bool prefix;

  const _Match(this.item, this.name, this.prefix);
}
