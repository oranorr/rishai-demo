import 'package:firebase_auth/firebase_auth.dart';

abstract class LoginRemoteDataSource {
  Future<User?> authorizeViaGoogle();
  Future<User?> authorizeViaApple();
}
