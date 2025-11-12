import 'package:hive_flutter/hive_flutter.dart';
import '../models/pregnancy_model.dart';
import '../models/health_log_model.dart';
import '../models/appointment_model.dart';
import '../models/nutrition_model.dart';
import '../models/recipe_model.dart';
import '../constants/app_constants.dart';

class DatabaseService {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(PregnancyModelAdapter());
    Hive.registerAdapter(HealthLogModelAdapter());
    Hive.registerAdapter(AppointmentModelAdapter());
    Hive.registerAdapter(NutritionModelAdapter());
    Hive.registerAdapter(RecipeModelAdapter());

    // Open boxes
    await Hive.openBox<PregnancyModel>(AppConstants.pregnancyBox);
    await Hive.openBox<HealthLogModel>(AppConstants.healthLogBox);
    await Hive.openBox<AppointmentModel>(AppConstants.appointmentBox);
    await Hive.openBox<NutritionModel>(AppConstants.nutritionBox);
    await Hive.openBox<RecipeModel>(AppConstants.recipeBox);
    await Hive.openBox(AppConstants.settingsBox);
  }

  // Pregnancy operations
  static Box<PregnancyModel> get pregnancyBox =>
      Hive.box<PregnancyModel>(AppConstants.pregnancyBox);

  static Future<void> savePregnancy(PregnancyModel pregnancy) async {
    await pregnancyBox.put(pregnancy.id, pregnancy);
  }

  static PregnancyModel? getActivePregnancy() {
    return pregnancyBox.values.firstWhere(
      (p) => p.isActive,
      orElse: () => pregnancyBox.values.isNotEmpty ? pregnancyBox.values.first : throw Exception('No pregnancy found'),
    );
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

  // Clear all data
  static Future<void> clearAllData() async {
    await pregnancyBox.clear();
    await healthLogBox.clear();
    await appointmentBox.clear();
    await nutritionBox.clear();
    await recipeBox.clear();
  }
}
