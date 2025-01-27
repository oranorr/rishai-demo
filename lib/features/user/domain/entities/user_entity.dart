import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:rishai/features/user/domain/entities/food_preferences_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';

part 'body_measurements_entity.dart';
part 'user_entity.g.dart';

@HiveType(typeId: 0)
class UserEntity extends HiveObject {
  UserEntity({
    required this.directusId,
    required this.whoopId,
    required this.email,
    required this.name,
    required this.daysIds,
    required this.adaptyId,
    this.age,
    this.gender,
    this.foodPreferences,
    this.bodyMeasurements,
    this.userGoal,
  });

  factory UserEntity.unauthorized() => UserEntity(
        directusId: '-1',
        whoopId: 0,
        email: '',
        name: '',
        bodyMeasurements: const BodyMeasurementsEntity(
          height: 0,
          weight: 0,
          maxHeartRate: 0,
        ),
        foodPreferences: FoodPreferences(
          diets: [],
          cuisines: [],
          restrictions: [],
        ),
        age: 0,
        gender: Gender.male,
        daysIds: [],
        adaptyId: null,
      );
  @HiveField(0)
  final String directusId;
  @HiveField(1)
  final int whoopId;
  @HiveField(2)
  final String email;
  @HiveField(3)
  final String name;
  @HiveField(4)
  final int? age;
  @HiveField(5)
  final Gender? gender;
  @HiveField(6)
  final FoodPreferences? foodPreferences;
  @HiveField(7)
  final BodyMeasurementsEntity? bodyMeasurements;
  @HiveField(8)
  final UserGoal? userGoal;
  @HiveField(9)
  final List<int> daysIds;
  @HiveField(10)
  final String? adaptyId;

  UserEntity copyWith({
    String? directusId,
    int? whoopId,
    String? email,
    String? name,
    int? age,
    Gender? gender,
    FoodPreferences? foodPreferences,
    BodyMeasurementsEntity? bodyMeasurements,
    UserGoal? userGoal,
    List<int>? daysIds,
    String? adaptyId,
  }) {
    return UserEntity(
      directusId: directusId ?? this.directusId,
      whoopId: whoopId ?? this.whoopId,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      bodyMeasurements: bodyMeasurements ?? this.bodyMeasurements,
      userGoal: userGoal ?? this.userGoal,
      daysIds: daysIds ?? this.daysIds,
      adaptyId: adaptyId ?? this.adaptyId,
    );
  }

  @override
  String toString() {
    return 'UserEntity(directusId: $directusId, whoopId: $whoopId, email: $email, name: $name, age: $age, gender: $gender, foodPreferences: $foodPreferences, bodyMeasurements: $bodyMeasurements, daysIds: $daysIds, adaptyId: $adaptyId)';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'directusId': directusId,
      'whoopId': whoopId,
      'email': email,
      'name': name,
      'age': age,
      'gender': gender?.name,
      'bodyMeasurements': bodyMeasurements?.toMap(),
      'restrictions': foodPreferences?.restrictions,
      'diets': foodPreferences?.diets,
      'cuisines': foodPreferences?.cuisines,
      'userGoal': userGoal?.toMap(),
      'adaptyId': adaptyId,
    };
  }

  bool get needsQuestionary {
    return foodPreferences == null ||
        foodPreferences!.cuisines.isEmpty ||
        foodPreferences!.diets.isEmpty ||
        foodPreferences!.restrictions.isEmpty ||
        userGoal == null ||
        bodyMeasurements == null ||
        gender == null ||
        age == null;
  }

  @override
  bool operator ==(covariant UserEntity other) {
    if (identical(this, other)) {
      return true;
    }

    return other.directusId == directusId &&
        other.whoopId == whoopId &&
        other.email == email &&
        other.name == name &&
        other.age == age &&
        other.gender == gender &&
        other.foodPreferences == foodPreferences &&
        other.bodyMeasurements == bodyMeasurements;
  }

  @override
  int get hashCode {
    return directusId.hashCode ^
        whoopId.hashCode ^
        email.hashCode ^
        name.hashCode ^
        age.hashCode ^
        gender.hashCode ^
        foodPreferences.hashCode ^
        bodyMeasurements.hashCode;
  }
}

@HiveType(typeId: 1)
enum Gender {
  @HiveField(0)
  male,
  @HiveField(1)
  female
}
