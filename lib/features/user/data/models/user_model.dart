// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:rishai/features/user/domain/entities/food_preferences_entity.dart';

import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';

class UserModel extends Equatable {
  final String directusId;
  final int whoopId;
  final String email;
  final String name;
  final int? age;
  final String? gender;
  final FoodPreferences? foodPreferences;
  final BodyMeasurementsEntity? bodyMeasurementsEntity;
  final UserGoal? userGoal;
  final List<int> daysIds;
  final String? adaptyId;
  final List<int> weekPlanIds;

  const UserModel({
    required this.directusId,
    required this.whoopId,
    required this.email,
    required this.name,
    required this.daysIds,
    required this.adaptyId,
    required this.weekPlanIds,
    this.age,
    this.gender,
    this.userGoal,
    this.foodPreferences,
    this.bodyMeasurementsEntity,
  });

  UserModel copyWith({
    String? directusId,
    int? whoopId,
    String? email,
    String? name,
    int? age,
    String? gender,
    UserGoal? userGoal,
    FoodPreferences? foodPreferences,
    BodyMeasurementsEntity? bodyMeasurementsEntity,
    List<int>? daysIds,
    int? userWhoopId,
    String? adaptyId,
    List<int>? weekPlanIds,
  }) {
    return UserModel(
      directusId: directusId ?? this.directusId,
      whoopId: whoopId ?? this.whoopId,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      userGoal: userGoal ?? this.userGoal,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      bodyMeasurementsEntity:
          bodyMeasurementsEntity ?? this.bodyMeasurementsEntity,
      daysIds: daysIds ?? this.daysIds,
      adaptyId: adaptyId ?? this.adaptyId,
      weekPlanIds: weekPlanIds ?? this.weekPlanIds,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> foodPreferences = {
      'diets': map['diets'],
      'cuisines': map['cuisines'],
      'goal': map['goal'],
      'restrictions': map['restrictions'] ?? [],
    };

    return UserModel(
      directusId: map['id'].toString(),
      whoopId: map['whoopId'] ?? 0,
      email: map['email'] as String,
      name: map['name'] as String,
      bodyMeasurementsEntity:
          map['bodyMeasurements'] != null && map['bodyMeasurements']!.isNotEmpty
              ? BodyMeasurementsEntity.fromMap(
                  map['bodyMeasurements'] as Map<String, dynamic>,
                )
              : null,
      age: map['age'],
      gender: map['gender'],
      foodPreferences: FoodPreferences.fromMap(
        foodPreferences,
      ),
      userGoal: map['userGoal'] != null && map['userGoal'].isNotEmpty
          ? UserGoal.fromMap(map['userGoal'])
          : null,
      daysIds: List.from(map['days']).cast<int>(),
      adaptyId: map['adaptyId'],
      weekPlanIds: List.from(map['weekPlanIds']).cast<int>(),
      // userWhoopId: map['userWhoopId'] as int,
    );
  }

  // String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List get props {
    return [
      directusId,
      whoopId,
      email,
      name,
      bodyMeasurementsEntity,
    ];
  }

  UserEntity toEntity() {
    return UserEntity(
      directusId: directusId,
      whoopId: whoopId,
      email: email,
      name: name,
      bodyMeasurements: bodyMeasurementsEntity,
      age: age,
      gender: gender != null ? Gender.values.byName(gender!) : null,
      foodPreferences: foodPreferences,
      userGoal: userGoal,
      daysIds: daysIds,
      adaptyId: adaptyId,
      weekPlanIds: weekPlanIds,
      // userWhoopId: userWhoopId,
    );
  }
}
