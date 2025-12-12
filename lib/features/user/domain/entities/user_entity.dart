import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:rishai/features/food_diary/domain/pivot_life_scrore_entity.dart';
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
    required this.adaptyId,
    required this.weekPlanIds,
    required this.pivotLifeScore,
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
        weekPlanIds: [],
        adaptyId: null,
        pivotLifeScore: null,
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
  final String? adaptyId;
  @HiveField(10)
  final List<int> weekPlanIds;
  @HiveField(11)
  final PivotLifeScoreEntity? pivotLifeScore;

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
    String? adaptyId,
    List<int>? weekPlanIds,
    PivotLifeScoreEntity? pivotLifeScore,
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
      adaptyId: adaptyId ?? this.adaptyId,
      weekPlanIds: weekPlanIds ?? this.weekPlanIds,
      pivotLifeScore: pivotLifeScore ?? this.pivotLifeScore,
    );
  }

  @override
  String toString() {
    return 'UserEntity(directusId: $directusId, whoopId: $whoopId, email: $email, name: $name, age: $age, gender: $gender, foodPreferences: $foodPreferences, bodyMeasurements: $bodyMeasurements, adaptyId: $adaptyId, weekPlanIds: $weekPlanIds, pivotLifeScore: $pivotLifeScore)';
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
      // 'weekPlanIds': weekPlanIds,
      'pivotLifeScore': pivotLifeScore?.toMap(),
    };
  }

  bool get needsQuestionary {
    // bodyMeasurements исключены из проверки, так как они получаются отдельно от Whoop API
    // а не заполняются пользователем в опроснике
    return foodPreferences == null ||
        foodPreferences!.cuisines.isEmpty ||
        foodPreferences!.diets.isEmpty ||
        userGoal == null ||
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
        other.bodyMeasurements == bodyMeasurements &&
        other.userGoal == userGoal &&
        other.adaptyId == adaptyId &&
        other.pivotLifeScore == pivotLifeScore;
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
        bodyMeasurements.hashCode ^
        userGoal.hashCode ^
        adaptyId.hashCode ^
        pivotLifeScore.hashCode;
  }
}

@HiveType(typeId: 1)
enum Gender {
  @HiveField(0)
  male,
  @HiveField(1)
  female
}
