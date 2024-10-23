import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseRepository {
  Future<User?> login();
  Future<User?> loginViaApple();
}
