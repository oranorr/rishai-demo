import 'package:equatable/equatable.dart';

class LoginInfoEntity extends Equatable {
  const LoginInfoEntity({
    required this.email,
    required this.name,
    required this.verificationCode,
  });
  final String email;
  final String name;
  final String verificationCode;

  @override
  List<Object?> get props => [email, name, verificationCode];
}
