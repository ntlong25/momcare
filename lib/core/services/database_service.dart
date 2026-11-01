import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pregnancy_model.dart';
import '../models/health_log_model.dart';
import '../models/appointment_model.dart';
import '../models/nutrition_model.dart';
import '../models/recipe_model.dart';
import '../models/menstrual_cycle_model.dart';
import '../models/fertility_log_model.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import 'encryption_service.dart';
import 'health_service.dart';

class DatabaseService {
  static final _logger = AppLogger.instance;

  /// SharedPreferences flag: whether sensitive boxes were opened encrypted.
  static const String _encryptionStateKey = 'hive_boxes_encrypted';

  static Future<void> init() async {
    try {
      _logger.info('Initializing Hive database');
      await Hive.initFlutter();

      // Register adapters
      _registerAdapter(PregnancyModelAdapter());
      _registerAdapter(HealthLogModelAdapter());
      _registerAdapter(AppointmentModelAdapter());
      _registerAdapter(NutritionModelAdapter());
      _registerAdapter(RecipeModelAdapter());
      _registerAdapter(MenstrualCycleModelAdapter());
      _registerAdapter(FertilityLogModelAdapter());
      _logger.debug('Hive adapters registered');

      // Get encryption cipher for sensitive data
      final prefs = await SharedPreferences.getInstance();
      final wasEncrypted = prefs.getBool(_encryptionStateKey);
      var encryptionCipher = await EncryptionService.getEncryptionCipher();

      if (encryptionCipher == null && wasEncrypted == true) {
        // Opening encrypted boxes without the key would make Hive discard
        // the frames it cannot read. Keep the data intact and stop here.
        throw const EncryptionUnavailableException(
          'Encrypted health data exists but the encryption key is unavailable',
        );
      }
      if (encryptionCipher != null && wasEncrypted == false) {
        // Boxes were created unencrypted during an earlier fallback; opening
        // them with a cipher would make them unreadable. Keep them as-is.
        _logger.warning(
          'SECURITY: existing Hive data was stored without encryption; '
          'keeping unencrypted mode to avoid data loss',
        );
        encryptionCipher = null;
        EncryptionService.isFallbackActive = true;
      }

      if (encryptionCipher != null) {
        _logger.info('Opening Hive boxes with encryption');
      } else {
        _logger.warning(
          'SECURITY: opening Hive boxes WITHOUT encryption (fallback mode)',
        );
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
      await openFertilityBoxes(encryptionCipher);

      // These boxes don't contain sensitive data, so no encryption needed
      await Hive.openBox<NutritionModel>(AppConstants.nutritionBox);
      await Hive.openBox<RecipeModel>(AppConstants.recipeBox);
      await Hive.openBox(AppConstants.settingsBox);

      // Remember how the sensitive boxes are stored for the next launch.
      await prefs.setBool(_encryptionStateKey, encryptionCipher != null);

      _logger.info('Hive database initialized successfully');
    } catch (e, stackTrace) {
      _logger.fatal(
        'Failed to initialize Hive database',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Opens the boxes of the daily fertility signals and their preferences.
  /// Both are new in Phase 25, so upgrades only add files; existing boxes
  /// are not touched.
  static Future<void> openFertilityBoxes(HiveCipher? encryptionCipher) async {
    await Hive.openBox<FertilityLogModel>(
      AppConstants.fertilityLogBox,
      encryptionCipher: encryptionCipher,
    );
    await Hive.openBox<dynamic>(
      AppConstants.fertilityPrefsBox,
      encryptionCipher: encryptionCipher,
    );
  }

  /// Merged change notifier for the named boxes (typed boxes are resolved
  /// with their own type, as Hive refuses mismatched generic lookups).
  /// Returns null when none of the boxes is open.
  static Listenable? listenableFor(List<String> boxNames) {
    final listenables = <Listenable>[];
    for (final name in boxNames) {
      if (!Hive.isBoxOpen(name)) continue;
      switch (name) {
        case AppConstants.pregnancyBox:
          listenables.add(pregnancyBox.listenable());
        case AppConstants.healthLogBox:
          listenables.add(healthLogBox.listenable());
        case AppConstants.appointmentBox:
          listenables.add(appointmentBox.listenable());
        case AppConstants.menstrualCycleBox:
          listenables.add(menstrualCycleBox.listenable());
        case AppConstants.fertilityLogBox:
          listenables.add(fertilityLogBox.listenable());
        case AppConstants.nutritionBox:
          listenables.add(nutritionBox.listenable());
        case AppConstants.recipeBox:
          listenables.add(recipeBox.listenable());
        default:
          listenables.add(Hive.box(name).listenable());
      }
    }
    if (listenables.isEmpty) return null;
    return Listenable.merge(listenables);
  }

  static void _registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  // Pregnancy operations
  static Box<PregnancyModel> get pregnancyBox =>
      Hive.box<PregnancyModel>(AppConstants.pregnancyBox);

  static Future<void> savePregnancy(PregnancyModel pregnancy) async {
    await pregnancyBox.put(pregnancy.id, pregnancy);
  }

  /// Saves [pregnancy] as the only active pregnancy. Any previously active
  /// pregnancy is kept for history but marked inactive.
  static Future<void> saveNewActivePregnancy(PregnancyModel pregnancy) async {
    final others = pregnancyBox.values
        .where((p) => p.id != pregnancy.id && p.isActive)
        .toList();
    for (final previous in others) {
      await pregnancyBox.put(
        previous.id,
        previous.copyWith(isActive: false, updatedAt: DateTime.now()),
      );
    }
    pregnancy.isActive = true;
    await pregnancyBox.put(pregnancy.id, pregnancy);
  }

  static PregnancyModel? getActivePregnancy() {
    try {
      // Prefer the most recently updated active pregnancy (older installs may
      // have several active entries from repeated setup).
      final active = pregnancyBox.values.where((p) => p.isActive).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (active.isNotEmpty) {
        return active.first;
      }

      // If no active pregnancy, return the first one if exists
      if (pregnancyBox.values.isNotEmpty) {
        _logger.debug('No active pregnancy found, returning first pregnancy');
        return pregnancyBox.values.first;
      }

      _logger.debug('No pregnancy data found');
      return null;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting active pregnancy',
        error: e,
        stackTrace: stackTrace,
      );
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

  static List<HealthLogModel> getHealthLogsByDateRange(
    DateTime start,
    DateTime end,
  ) {
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
    return recipeBox.values.where((recipe) => recipe.isFavorite).toList();
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
    DateTime start,
    DateTime end,
  ) {
    return menstrualCycleBox.values
        .where(
          (cycle) =>
              cycle.startDate.isAfter(start) && cycle.startDate.isBefore(end),
        )
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  static MenstrualCycleModel? getLastMenstrualCycle() {
    final cycles = getAllMenstrualCycles();
    return cycles.isNotEmpty ? cycles.first : null;
  }

  static Future<void> deleteMenstrualCycle(String id) async {
    await menstrualCycleBox.delete(id);
    await recomputeCycleLengths();
  }

  /// Saves a cycle entered or edited by the user and refreshes the stored
  /// cycle lengths, so entering an older period later never yields a negative
  /// cycle length.
  static Future<void> saveMenstrualCycleAndRecompute(
    MenstrualCycleModel cycle,
  ) async {
    await menstrualCycleBox.put(cycle.id, cycle);
    await recomputeCycleLengths();
  }

  /// Imports cycles from Apple Health / Health Connect without duplicating
  /// entries: synced cycles use a stable id per start date, and a cycle whose
  /// start date already exists locally (e.g. entered by hand) is skipped.
  /// Returns the number of new cycles stored.
  static Future<int> importMenstrualCycles(
    List<MenstrualCycleModel> cycles,
  ) async {
    var added = 0;
    for (final cycle in cycles) {
      final existing = menstrualCycleBox.values.where(
        (c) =>
            c.id != cycle.id &&
            HealthService.isSameDay(c.startDate, cycle.startDate),
      );
      if (existing.isNotEmpty) continue;
      if (!menstrualCycleBox.containsKey(cycle.id)) added++;
      await menstrualCycleBox.put(cycle.id, cycle);
    }
    await recomputeCycleLengths();
    return added;
  }

  static Future<void> recomputeCycleLengths() async {
    final updated = HealthService.withRecomputedCycleLengths(
      menstrualCycleBox.values.toList(),
    );
    for (final cycle in updated) {
      final current = menstrualCycleBox.get(cycle.id);
      if (current?.cycleLengthDays != cycle.cycleLengthDays) {
        await menstrualCycleBox.put(cycle.id, cycle);
      }
    }
  }

  static Future<void> clearMenstrualCycles() async {
    await menstrualCycleBox.clear();
  }

  // Fertility signals; read through FertilityLogService.
  static Box<FertilityLogModel> get fertilityLogBox =>
      Hive.box<FertilityLogModel>(AppConstants.fertilityLogBox);

  /// Encrypted, unlike [settingsBox]: even "reminders on" is sensitive here.
  static Box<dynamic> get fertilityPrefsBox =>
      Hive.box<dynamic>(AppConstants.fertilityPrefsBox);

  // Clear all data
  static Future<void> clearAllData() async {
    // First, so a reschedule triggered by the cycle box finds them gone.
    if (Hive.isBoxOpen(AppConstants.fertilityPrefsBox)) {
      await fertilityPrefsBox.clear();
    }
    if (Hive.isBoxOpen(AppConstants.fertilityLogBox)) {
      await fertilityLogBox.clear();
    }
    await pregnancyBox.clear();
    await healthLogBox.clear();
    await appointmentBox.clear();
    await nutritionBox.clear();
    await recipeBox.clear();
    await menstrualCycleBox.clear();
    await settingsBox.clear();
  }
}
