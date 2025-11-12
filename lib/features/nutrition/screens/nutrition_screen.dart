import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_service.dart';
import '../../../core/data/sample_nutrition_data.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'nutrition_detail_screen.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeSampleData();
  }

  Future<void> _initializeSampleData() async {
    if (_initialized) return;

    final existingNutrition = DatabaseService.getAllNutrition();
    final existingRecipes = DatabaseService.getAllRecipes();

    if (existingNutrition.isEmpty) {
      final sampleNutrition = SampleNutritionData.getNutritionGuides();
      for (var nutrition in sampleNutrition) {
        await DatabaseService.saveNutrition(nutrition);
      }
    }

    if (existingRecipes.isEmpty) {
      final sampleRecipes = SampleNutritionData.getRecipes();
      for (var recipe in sampleRecipes) {
        await DatabaseService.saveRecipe(recipe);
      }
    }

    _initialized = true;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Guide'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.lightbulb), text: 'Guides'),
            Tab(icon: Icon(Icons.restaurant), text: 'Recipes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGuidesTab(),
          _buildRecipesTab(),
        ],
      ),
    );
  }

  Widget _buildGuidesTab() {
    final allNutrition = DatabaseService.getAllNutrition();
    final filteredNutrition = _selectedCategory == 'All'
        ? allNutrition
        : allNutrition.where((n) => n.category == _selectedCategory).toList();

    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: filteredNutrition.isEmpty
              ? _buildEmptyState('No nutrition guides available')
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
    final filteredRecipes = _selectedCategory == 'All'
        ? allRecipes
        : allRecipes.where((r) => r.category == _selectedCategory).toList();

    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: filteredRecipes.isEmpty
              ? _buildEmptyState('No recipes available')
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

  Widget _buildCategoryFilter() {
    final categories = ['All', ...AppConstants.nutritionCategories];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
