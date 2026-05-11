import 'package:equatable/equatable.dart';

/// Параметр для `POST /auth/request-otp`.
class RequestEmailOtpParams extends Equatable {
  const RequestEmailOtpParams({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Параметры для `verify-otp` + загрузка профиля.
class VerifyEmailOtpParams extends Equatable {
  const VerifyEmailOtpParams({
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  @override
  List<Object?> get props => [email, code];
}
