// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();
}

class CreateAccountEvent extends LoginEvent {
  final String name;
  final String email;

  /// Флаг для создания 200 дней истории (только для тестирования)
  final bool shouldCreateHistoryDays;

  const CreateAccountEvent({
    required this.name,
    required this.email,
    this.shouldCreateHistoryDays = false,
  });

  @override
  List<Object?> get props => [name, email, shouldCreateHistoryDays];
}

class LoginViaGoogle extends LoginEvent {
  const LoginViaGoogle();

  @override
  List<Object?> get props => [];
}

class LoginViaEmail extends LoginEvent {
  final String email;
  const LoginViaEmail({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}

class LoginCancelOtpEnter extends LoginEvent {
  const LoginCancelOtpEnter();

  @override
  List<Object?> get props => [];
}

/// OAuth (Google/Apple): пользователь уже подтверждён, OTP не нужен.
class LoginOtpCorrect extends LoginEvent {
  const LoginOtpCorrect();

  @override
  List<Object?> get props => [];
}

/// Email: код из письма, проверка на сервере (`verify-otp` + `users/me`).
class LoginSubmitEmailOtp extends LoginEvent {
  const LoginSubmitEmailOtp({required this.code});

  final String code;

  @override
  List<Object?> get props => [code];
}

class LogoutEvent extends LoginEvent {
  @override
  List<Object?> get props => [];
}

class LoginViaApple extends LoginEvent {
  @override
  List<Object?> get props => [];
}
