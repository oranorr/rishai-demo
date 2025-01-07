import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

part 'user_state.freezed.dart';

@freezed
sealed class UserState with _$UserState {
  const factory UserState.mainState({
    required Status status,
    required UserEntity user,
    required List<DayEntity> days,
  }) = UserMainState;
}
