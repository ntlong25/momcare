// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menstrual_cycle_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenstrualCycleModelAdapter extends TypeAdapter<MenstrualCycleModel> {
  @override
  final int typeId = 2;

  @override
  MenstrualCycleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenstrualCycleModel(
      id: fields[0] as String,
      startDate: fields[1] as DateTime,
      endDate: fields[2] as DateTime?,
      cycleLengthDays: fields[3] as int?,
      periodLengthDays: fields[4] as int?,
      flowIntensity: fields[5] as String?,
      symptoms: (fields[6] as List?)?.cast<String>(),
      notes: fields[7] as String?,
      isFromHealthKit: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MenstrualCycleModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.cycleLengthDays)
      ..writeByte(4)
      ..write(obj.periodLengthDays)
      ..writeByte(5)
      ..write(obj.flowIntensity)
      ..writeByte(6)
      ..write(obj.symptoms)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.isFromHealthKit)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenstrualCycleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
