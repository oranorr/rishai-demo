import 'package:equatable/equatable.dart';

class LoginInfoEntity extends Equatable {
  final String email;
  final String name;
  final String verificationCode;

  const LoginInfoEntity({
    required this.email,
    required this.name,
    required this.verificationCode,
  });

  @override
  List<Object?> get props => [email, name, verificationCode];
}
