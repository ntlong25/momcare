// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NutritionModelAdapter extends TypeAdapter<NutritionModel> {
  @override
  final int typeId = 3;

  @override
  NutritionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionModel(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      description: fields[3] as String,
      benefits: (fields[4] as List).cast<String>(),
      recommendedFoods: (fields[5] as List).cast<String>(),
      foodsToAvoid: (fields[6] as List?)?.cast<String>(),
      imageUrl: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.benefits)
      ..writeByte(5)
      ..write(obj.recommendedFoods)
      ..writeByte(6)
      ..write(obj.foodsToAvoid)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
