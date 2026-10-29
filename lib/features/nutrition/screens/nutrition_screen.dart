import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/nutrition_seed_service.dart';
import '../../../core/utils/nutrition_filter.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'nutrition_detail_screen.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final bool showAppBar;

  const NutritionScreen({
    super.key,
    this.initialTab = 0,
    this.showAppBar = true,
  });

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _guideCategory = NutritionFilter.all;
  String _recipeCategory = NutritionFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _initializeSampleData();
  }

  Future<void> _initializeSampleData() async {
    // Seeds on first use and refreshes guides when bundled content changes.
    await NutritionSeedService.ensureSeeded();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.lightbulb), text: 'Hướng dẫn'),
        Tab(icon: Icon(Icons.restaurant), text: 'Công thức'),
      ],
    );
    final tabBarView = TabBarView(
      controller: _tabController,
      children: [_buildGuidesTab(), _buildRecipesTab()],
    );

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Hướng dẫn dinh dưỡng'), bottom: tabBar)
          : null,
      body: widget.showAppBar
          ? tabBarView
          : Column(
              children: [
                tabBar,
                Expanded(child: tabBarView),
              ],
            ),
    );
  }

  Widget _buildGuidesTab() {
    final allNutrition = DatabaseService.getAllNutrition();
    final chips = NutritionFilter.chipsFor(allNutrition.map((n) => n.category));
    final selected = chips.contains(_guideCategory)
        ? _guideCategory
        : NutritionFilter.all;
    final filteredNutrition = allNutrition
        .where((n) => NutritionFilter.matches(n.category, selected))
        .toList();

    return Column(
      children: [
        _buildCategoryFilter(
          chips,
          selected,
          (chip) => setState(() => _guideCategory = chip),
        ),
        Expanded(
          child: filteredNutrition.isEmpty
              ? _buildEmptyState('Chưa có hướng dẫn dinh dưỡng')
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNutrition.length,
                    itemBuilder: (context, index) {
                      final nutrition = filteredNutrition[index];
                      return NutritionCard(
                        nutrition: nutrition,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  NutritionDetailScreen(nutrition: nutrition),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecipesTab() {
    final allRecipes = DatabaseService.getAllRecipes();
    final chips = NutritionFilter.chipsFor(allRecipes.map((r) => r.category));
    final selected = chips.contains(_recipeCategory)
        ? _recipeCategory
        : NutritionFilter.all;
    final filteredRecipes = allRecipes
        .where((r) => NutritionFilter.matches(r.category, selected))
        .toList();

    return Column(
      children: [
        _buildCategoryFilter(
          chips,
          selected,
          (chip) => setState(() => _recipeCategory = chip),
        ),
        Expanded(
          child: filteredRecipes.isEmpty
              ? _buildEmptyState('Chưa có công thức món ăn')
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                          setState(() {});
                        },
                        onFavoriteToggle: () async {
                          final updated = recipe.copyWith(
                            isFavorite: !recipe.isFavorite,
                            updatedAt: DateTime.now(),
                          );
                          await DatabaseService.saveRecipe(updated);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(
    List<String> categories,
    String selectedCategory,
    ValueChanged<String> onSelected,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => onSelected(category),
              selectedColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.3),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 100,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
