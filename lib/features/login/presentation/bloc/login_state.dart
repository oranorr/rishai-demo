import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/login/domain/entities/login_info_entity.dart';

part 'login_state.freezed.dart';

@freezed
sealed class LoginState with _$LoginState {
  const factory LoginState.mainState({
    required final Status status,
    final LoginInfoEntity? loginEntity,
    final String? otp,
    final String? errorMessage,
  }) = LoginMainState;
}
