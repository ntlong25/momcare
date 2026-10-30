import 'package:flutter/material.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/food_model.dart';
import '../../../core/models/guide_models.dart';
import '../../../core/utils/food_filter.dart';
import '../../references/widgets/draft_content_note.dart';
import '../widgets/food_detail_sheet.dart';
import '../widgets/food_verdict_badge.dart';
import '../../../core/widgets/empty_state.dart';

/// "Bầu ăn được không?": accent-insensitive search over `foods.json` with
/// verdict and group filters.
class FoodLookupScreen extends StatefulWidget {
  static const String title = 'Bầu ăn được không?';
  static const String emptyPackText = 'Chưa có dữ liệu thực phẩm';
  static const String noResultsText = 'Không tìm thấy thực phẩm phù hợp';
  static const String allLabel = 'Tất cả';

  final bool showAppBar;

  /// Override the food pack (tests); defaults to the bundled content pack.
  final FoodPack? pack;

  /// Override source lookup (tests); defaults to `sources.json`.
  final Map<String, ContentSource>? sources;

  const FoodLookupScreen({
    super.key,
    this.showAppBar = true,
    this.pack,
    this.sources,
  });

  @override
  State<FoodLookupScreen> createState() => _FoodLookupScreenState();
}

class _FoodLookupScreenState extends State<FoodLookupScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  FoodVerdict? _verdict;
  String? _group;

  FoodPack get _pack => widget.pack ?? ContentPackService.foodPack;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final pack = _pack;
    final body = pack.isEmpty ? const _EmptyPack() : _buildLookup(pack);

    if (!widget.showAppBar) return body;
    return Scaffold(
      appBar: AppBar(title: const Text(FoodLookupScreen.title)),
      body: body,
    );
  }

  Widget _buildLookup(FoodPack pack) {
    final theme = Theme.of(context);
    final groups = FoodFilter.groupsIn(pack.items);
    final group = groups.contains(_group) ? _group : null;
    final results = FoodFilter.apply(
      pack.items,
      query: _query,
      verdict: _verdict,
      group: group,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Tìm thực phẩm, món ăn...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: _ChipRow(
                  children: [
                    _chip(
                      FoodLookupScreen.allLabel,
                      _verdict == null,
                      () => setState(() => _verdict = null),
                    ),
                    for (final verdict in FoodVerdict.values)
                      _chip(
                        verdict.label,
                        _verdict == verdict,
                        // Tapping the selected chip again resets the row.
                        () => setState(
                          () => _verdict = _verdict == verdict ? null : verdict,
                        ),
                      ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _ChipRow(
                  children: [
                    _chip(
                      'Mọi nhóm',
                      group == null,
                      () => setState(() => _group = null),
                    ),
                    for (final g in groups)
                      _chip(
                        FoodGroups.label(g),
                        group == g,
                        () => setState(() => _group = group == g ? null : g),
                      ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${results.length} kết quả',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              if (pack.isDraft)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverToBoxAdapter(child: DraftContentNote()),
                ),
              if (results.isEmpty)
                const SliverToBoxAdapter(child: _NoResults())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) => _FoodRow(
                      item: results[index],
                      onTap: () => FoodDetailSheet.show(
                        context,
                        item: results[index],
                        pack: pack,
                        sources: widget.sources ?? ContentPackService.sources,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<Widget> children;

  const _ChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(children: children),
    );
  }
}

class _FoodRow extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onTap;

  const _FoodRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.aliases.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.aliases.join(', '),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      item.groupLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FoodVerdictBadge(verdict: item.verdict),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.search_off,
      iconSize: 56,
      title: FoodLookupScreen.noResultsText,
      message:
          'Thử tìm bằng tên khác hoặc bỏ bớt bộ lọc. Nếu chưa chắc, hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng.',
    );
  }
}

class _EmptyPack extends StatelessWidget {
  const _EmptyPack();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              FoodLookupScreen.emptyPackText,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
