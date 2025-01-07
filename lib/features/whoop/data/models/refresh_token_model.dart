class RefreshTokenModel {
  RefreshTokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory RefreshTokenModel.fromMap(Map<String, dynamic> map) {
    return RefreshTokenModel(
      accessToken: map['access_token'],
      refreshToken: map['refresh_token'],
      expiresIn: Duration(seconds: map['expires_in']),
    );
  }
  final String accessToken;
  final String refreshToken;
  final Duration expiresIn;
}
