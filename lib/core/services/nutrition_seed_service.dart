import '../data/content_pack_service.dart';
import '../utils/app_logger.dart';
import 'database_service.dart';

/// Seeds bundled nutrition content into Hive and refreshes it when the
/// bundled content pack changes (`lastUpdated`), so existing users receive
/// updated guides. Recipes (and their favourites) are only seeded once.
class NutritionSeedService {
  static const String contentVersionKey = 'nutrition_content_version';

  static Future<void> ensureSeeded() async {
    try {
      final version = ContentPackService.nutritionContentVersion;
      final savedVersion = DatabaseService.getSetting(contentVersionKey);
      final guides = DatabaseService.getAllNutrition();

      if (guides.isEmpty || savedVersion != version) {
        await DatabaseService.nutritionBox.clear();
        for (final guide in ContentPackService.nutritionGuides) {
          await DatabaseService.saveNutrition(guide);
        }
        await DatabaseService.saveSetting(contentVersionKey, version);
      }

      if (DatabaseService.getAllRecipes().isEmpty) {
        for (final recipe in ContentPackService.recipes) {
          await DatabaseService.saveRecipe(recipe);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Nutrition content seeding failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
