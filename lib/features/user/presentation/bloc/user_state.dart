import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

import '../../../whoop/domain/entities/day_entity.dart';

part 'user_state.freezed.dart';

@freezed
sealed class UserState with _$UserState {
  const factory UserState.mainState({
    required final Status status,
    required final UserEntity user,
    required final List<DayEntity> days,
  }) = UserMainState;
}
