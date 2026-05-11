import 'package:equatable/equatable.dart';

/// Контекст email-логина / регистрации для экрана ввода OTP.
///
/// Код приходит с сервера по почте; клиент **не** хранит ожидаемый OTP.
class LoginInfoEntity extends Equatable {
  const LoginInfoEntity({
    required this.email,
    required this.name,
    this.shouldCreateHistoryDays = false,
  });
  final String email;
  final String name;

  /// Только для тестового сценария регистрации (200 дней истории).
  final bool shouldCreateHistoryDays;

  @override
  List<Object?> get props => [email, name, shouldCreateHistoryDays];
}
