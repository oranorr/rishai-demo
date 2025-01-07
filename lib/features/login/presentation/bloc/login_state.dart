// ignore: depend_on_referenced_packages
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/login/domain/entities/login_info_entity.dart';

part 'login_state.freezed.dart';

@freezed
sealed class LoginState with _$LoginState {
  const factory LoginState.mainState({
    required Status status,
    LoginInfoEntity? loginEntity,
    String? otp,
    String? errorMessage,
  }) = LoginMainState;
}
