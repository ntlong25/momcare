// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthLogModelAdapter extends TypeAdapter<HealthLogModel> {
  @override
  final int typeId = 1;

  @override
  HealthLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthLogModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      weight: fields[2] as double?,
      systolicBP: fields[3] as int?,
      diastolicBP: fields[4] as int?,
      mood: fields[5] as String?,
      symptoms: (fields[6] as List?)?.cast<String>(),
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HealthLogModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.systolicBP)
      ..writeByte(4)
      ..write(obj.diastolicBP)
      ..writeByte(5)
      ..write(obj.mood)
      ..writeByte(6)
      ..write(obj.symptoms)
      ..writeByte(7)
      ..write(obj.notes)
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
      other is HealthLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
