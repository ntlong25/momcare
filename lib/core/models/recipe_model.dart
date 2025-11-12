import 'package:hive/hive.dart';

part 'recipe_model.g.dart';

@HiveType(typeId: 4)
class RecipeModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String category;

  @HiveField(3)
  String description;

  @HiveField(4)
  List<String> ingredients;

  @HiveField(5)
  List<String> steps;

  @HiveField(6)
  int preparationTime; // in minutes

  @HiveField(7)
  int cookingTime; // in minutes

  @HiveField(8)
  int servings;

  @HiveField(9)
  String? imageUrl;

  @HiveField(10)
  List<String>? nutritionBenefits;

  @HiveField(11)
  bool isFavorite;

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  DateTime updatedAt;

  RecipeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.preparationTime,
    required this.cookingTime,
    required this.servings,
    this.imageUrl,
    this.nutritionBenefits,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalTime => preparationTime + cookingTime;

  RecipeModel copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    List<String>? ingredients,
    List<String>? steps,
    int? preparationTime,
    int? cookingTime,
    int? servings,
    String? imageUrl,
    List<String>? nutritionBenefits,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      preparationTime: preparationTime ?? this.preparationTime,
      cookingTime: cookingTime ?? this.cookingTime,
      servings: servings ?? this.servings,
      imageUrl: imageUrl ?? this.imageUrl,
      nutritionBenefits: nutritionBenefits ?? this.nutritionBenefits,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
