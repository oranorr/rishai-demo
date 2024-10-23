import 'package:equatable/equatable.dart';

class AuthResponseEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final Duration expiresIn;
  const AuthResponseEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

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
