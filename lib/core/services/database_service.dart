import 'package:hive_flutter/hive_flutter.dart';
import '../models/pregnancy_model.dart';
import '../models/health_log_model.dart';
import '../models/appointment_model.dart';
import '../models/nutrition_model.dart';
import '../models/recipe_model.dart';
import '../models/menstrual_cycle_model.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import 'encryption_service.dart';

class DatabaseService {
  static final _logger = AppLogger.instance;

  static Future<void> init() async {
    try {
      _logger.info('Initializing Hive database');
      await Hive.initFlutter();

      // Register adapters
      Hive.registerAdapter(PregnancyModelAdapter());
      Hive.registerAdapter(HealthLogModelAdapter());
      Hive.registerAdapter(AppointmentModelAdapter());
      Hive.registerAdapter(NutritionModelAdapter());
      Hive.registerAdapter(RecipeModelAdapter());
      Hive.registerAdapter(MenstrualCycleModelAdapter());
      _logger.debug('Hive adapters registered');

      // Get encryption cipher for sensitive data
      final encryptionCipher = await EncryptionService.getEncryptionCipher();

      if (encryptionCipher != null) {
        _logger.info('Opening Hive boxes with encryption');
      } else {
        _logger.warning('Opening Hive boxes WITHOUT encryption (fallback mode)');
      }

      // Open boxes with encryption for sensitive health data
      await Hive.openBox<PregnancyModel>(
        AppConstants.pregnancyBox,
        encryptionCipher: encryptionCipher,
      );
      await Hive.openBox<HealthLogModel>(
        AppConstants.healthLogBox,
        encryptionCipher: encryptionCipher,
      );
      await Hive.openBox<AppointmentModel>(
        AppConstants.appointmentBox,
        encryptionCipher: encryptionCipher,
      );
      await Hive.openBox<MenstrualCycleModel>(
        AppConstants.menstrualCycleBox,
        encryptionCipher: encryptionCipher,
      );

      // These boxes don't contain sensitive data, so no encryption needed
      await Hive.openBox<NutritionModel>(AppConstants.nutritionBox);
      await Hive.openBox<RecipeModel>(AppConstants.recipeBox);
      await Hive.openBox(AppConstants.settingsBox);

      _logger.info('Hive database initialized successfully');
    } catch (e, stackTrace) {
      _logger.fatal('Failed to initialize Hive database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Pregnancy operations
  static Box<PregnancyModel> get pregnancyBox =>
      Hive.box<PregnancyModel>(AppConstants.pregnancyBox);

  static Future<void> savePregnancy(PregnancyModel pregnancy) async {
    await pregnancyBox.put(pregnancy.id, pregnancy);
  }

  static PregnancyModel? getActivePregnancy() {
    try {
      // Try to find active pregnancy
      final activePregnancy = pregnancyBox.values.cast<PregnancyModel?>().firstWhere(
        (p) => p?.isActive == true,
        orElse: () => null,
      );

      if (activePregnancy != null) {
        return activePregnancy;
      }

      // If no active pregnancy, return the first one if exists
      if (pregnancyBox.values.isNotEmpty) {
        _logger.debug('No active pregnancy found, returning first pregnancy');
        return pregnancyBox.values.first;
      }

      _logger.debug('No pregnancy data found');
      return null;
    } catch (e, stackTrace) {
      _logger.error('Error getting active pregnancy', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static List<PregnancyModel> getAllPregnancies() {
    return pregnancyBox.values.toList();
  }

  static Future<void> deletePregnancy(String id) async {
    await pregnancyBox.delete(id);
  }

  // Health Log operations
  static Box<HealthLogModel> get healthLogBox =>
      Hive.box<HealthLogModel>(AppConstants.healthLogBox);

  static Future<void> saveHealthLog(HealthLogModel log) async {
    await healthLogBox.put(log.id, log);
  }

  static List<HealthLogModel> getAllHealthLogs() {
    final logs = healthLogBox.values.toList();
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  static List<HealthLogModel> getHealthLogsByDateRange(DateTime start, DateTime end) {
    return healthLogBox.values
        .where((log) => log.date.isAfter(start) && log.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> deleteHealthLog(String id) async {
    await healthLogBox.delete(id);
  }

  // Appointment operations
  static Box<AppointmentModel> get appointmentBox =>
      Hive.box<AppointmentModel>(AppConstants.appointmentBox);

  static Future<void> saveAppointment(AppointmentModel appointment) async {
    await appointmentBox.put(appointment.id, appointment);
  }

  static List<AppointmentModel> getAllAppointments() {
    final appointments = appointmentBox.values.toList();
    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return appointments;
  }

  static List<AppointmentModel> getUpcomingAppointments() {
    final now = DateTime.now();
    return appointmentBox.values
        .where((apt) => apt.dateTime.isAfter(now) && !apt.isCompleted)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  static Future<void> deleteAppointment(String id) async {
    await appointmentBox.delete(id);
  }

  // Nutrition operations
  static Box<NutritionModel> get nutritionBox =>
      Hive.box<NutritionModel>(AppConstants.nutritionBox);

  static Future<void> saveNutrition(NutritionModel nutrition) async {
    await nutritionBox.put(nutrition.id, nutrition);
  }

  static List<NutritionModel> getAllNutrition() {
    return nutritionBox.values.toList();
  }

  static List<NutritionModel> getNutritionByCategory(String category) {
    return nutritionBox.values
        .where((nutrition) => nutrition.category == category)
        .toList();
  }

  static Future<void> deleteNutrition(String id) async {
    await nutritionBox.delete(id);
  }

  // Recipe operations
  static Box<RecipeModel> get recipeBox =>
      Hive.box<RecipeModel>(AppConstants.recipeBox);

  static Future<void> saveRecipe(RecipeModel recipe) async {
    await recipeBox.put(recipe.id, recipe);
  }

  static List<RecipeModel> getAllRecipes() {
    return recipeBox.values.toList();
  }

  static List<RecipeModel> getRecipesByCategory(String category) {
    return recipeBox.values
        .where((recipe) => recipe.category == category)
        .toList();
  }

  static List<RecipeModel> getFavoriteRecipes() {
    return recipeBox.values
        .where((recipe) => recipe.isFavorite)
        .toList();
  }

  static Future<void> deleteRecipe(String id) async {
    await recipeBox.delete(id);
  }

  // Settings operations
  static Box get settingsBox => Hive.box(AppConstants.settingsBox);

  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue);
  }

  // Menstrual Cycle operations
  static Box<MenstrualCycleModel> get menstrualCycleBox =>
      Hive.box<MenstrualCycleModel>(AppConstants.menstrualCycleBox);

  static Future<void> saveMenstrualCycle(MenstrualCycleModel cycle) async {
    await menstrualCycleBox.put(cycle.id, cycle);
  }

  static List<MenstrualCycleModel> getAllMenstrualCycles() {
    final cycles = menstrualCycleBox.values.toList();
    cycles.sort((a, b) => b.startDate.compareTo(a.startDate));
    return cycles;
  }

  static List<MenstrualCycleModel> getMenstrualCyclesByDateRange(
      DateTime start, DateTime end) {
    return menstrualCycleBox.values
        .where((cycle) =>
            cycle.startDate.isAfter(start) && cycle.startDate.isBefore(end))
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  static MenstrualCycleModel? getLastMenstrualCycle() {
    final cycles = getAllMenstrualCycles();
    return cycles.isNotEmpty ? cycles.first : null;
  }

  static Future<void> deleteMenstrualCycle(String id) async {
    await menstrualCycleBox.delete(id);
  }

  static Future<void> clearMenstrualCycles() async {
    await menstrualCycleBox.clear();
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await pregnancyBox.clear();
    await healthLogBox.clear();
    await appointmentBox.clear();
    await nutritionBox.clear();
    await recipeBox.clear();
    await menstrualCycleBox.clear();
  }
}
