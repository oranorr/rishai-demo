// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealPlanEntityAdapter extends TypeAdapter<MealPlanEntity> {
  @override
  final int typeId = 6;

  @override
  MealPlanEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealPlanEntity(
      meals: (fields[0] as List).cast<Meal>(),
      cycleId: fields[1] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MealPlanEntity obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.meals)
      ..writeByte(1)
      ..write(obj.cycleId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPlanEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealAdapter extends TypeAdapter<Meal> {
  @override
  final int typeId = 7;

  @override
  Meal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Meal(
      title: fields[0] as String,
      type: fields[1] as String,
      description: fields[2] as String,
      macros: fields[3] as MacrosBreakdown,
      ingredients: (fields[4] as List).cast<Ingredient>(),
      cookingInstructions: (fields[5] as List).cast<String>(),
      isRegenerated: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Meal obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.macros)
      ..writeByte(4)
      ..write(obj.ingredients)
      ..writeByte(5)
      ..write(obj.cookingInstructions)
      ..writeByte(6)
      ..write(obj.isRegenerated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MacrosBreakdownAdapter extends TypeAdapter<MacrosBreakdown> {
  @override
  final int typeId = 8;

  @override
  MacrosBreakdown read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MacrosBreakdown(
      kcal: fields[0] as int,
      protein: fields[1] as int,
      carbs: fields[2] as int,
      fat: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MacrosBreakdown obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.kcal)
      ..writeByte(1)
      ..write(obj.protein)
      ..writeByte(2)
      ..write(obj.carbs)
      ..writeByte(3)
      ..write(obj.fat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacrosBreakdownAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IngredientAdapter extends TypeAdapter<Ingredient> {
  @override
  final int typeId = 9;

  @override
  Ingredient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ingredient(
      title: fields[1] as String,
      quantity: fields[3] as double,
      unit: fields[4] as MeasurementUnit,
      emojiCode: fields[0] as String,
      category: fields[5] as String?,
      id: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Ingredient obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.emojiCode)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeasurementUnitAdapter extends TypeAdapter<MeasurementUnit> {
  @override
  final int typeId = 18;

  @override
  MeasurementUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MeasurementUnit.grams;
      case 1:
        return MeasurementUnit.milliliters;
      case 2:
        return MeasurementUnit.pieces;
      case 3:
        return MeasurementUnit.tablespoons;
      case 4:
        return MeasurementUnit.teaspoons;
      default:
        return MeasurementUnit.grams;
    }
  }

  @override
  void write(BinaryWriter writer, MeasurementUnit obj) {
    switch (obj) {
      case MeasurementUnit.grams:
        writer.writeByte(0);
        break;
      case MeasurementUnit.milliliters:
        writer.writeByte(1);
        break;
      case MeasurementUnit.pieces:
        writer.writeByte(2);
        break;
      case MeasurementUnit.tablespoons:
        writer.writeByte(3);
        break;
      case MeasurementUnit.teaspoons:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
