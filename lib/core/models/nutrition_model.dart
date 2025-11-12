import 'package:hive/hive.dart';

part 'nutrition_model.g.dart';

@HiveType(typeId: 3)
class NutritionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String category; // Trimester 1, 2, 3, Postpartum, Baby Food

  @HiveField(3)
  String description;

  @HiveField(4)
  List<String> benefits;

  @HiveField(5)
  List<String> recommendedFoods;

  @HiveField(6)
  List<String>? foodsToAvoid;

  @HiveField(7)
  String? imageUrl;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  NutritionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.benefits,
    required this.recommendedFoods,
    this.foodsToAvoid,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  NutritionModel copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    List<String>? benefits,
    List<String>? recommendedFoods,
    List<String>? foodsToAvoid,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NutritionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      benefits: benefits ?? this.benefits,
      recommendedFoods: recommendedFoods ?? this.recommendedFoods,
      foodsToAvoid: foodsToAvoid ?? this.foodsToAvoid,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
