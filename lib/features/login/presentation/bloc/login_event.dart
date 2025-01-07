// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();
}

class CreateAccountEvent extends LoginEvent {
  final String name;
  final String email;
  const CreateAccountEvent({
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [name, email];
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

class LoginOtpCorrect extends LoginEvent {
  const LoginOtpCorrect();

  @override
  List<Object?> get props => [];
}

class LogoutEvent extends LoginEvent {
  @override
  List<Object?> get props => [];
}

class LoginViaApple extends LoginEvent {
  @override
  List<Object?> get props => [];
}
