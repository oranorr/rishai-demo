import 'package:equatable/equatable.dart';

class AuthResponseEntity extends Equatable {
  const AuthResponseEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
  final String accessToken;
  final String refreshToken;
  final Duration expiresIn;

  AuthResponseEntity copyWith({
    String? accessToken,
    String? refreshToken,
    Duration? expiresIn,
  }) {
    return AuthResponseEntity(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }

  @override
  List<Object> get props => [accessToken, refreshToken, expiresIn];

  @override
  bool get stringify => true;
}
