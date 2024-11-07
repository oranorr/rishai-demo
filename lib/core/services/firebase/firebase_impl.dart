import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/envied/envied.dart';
import 'package:rishai/core/services/firebase/firebase_repo.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// import 'package:sign_in';
final firebase = getIt.get<FirebaseRepository>();

@Singleton(as: FirebaseRepository)
class FirebaseImplementation implements FirebaseRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> scopes = <String>['email'];
  late GoogleSignIn googleSignIn = Platform.isAndroid
      ? GoogleSignIn(
          // Optional clientId
          // clientId: 'your-client_id.apps.googleusercontent.com',

          scopes: scopes,
        )
      : GoogleSignIn(
          clientId: Env.googleClientId,
        );

  @override
  Future<User?> login() async {
    try {
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      return user;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  @override
  Future<User?> loginViaApple() async {
    try {
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Войдите в Firebase с использованием Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      if (userCredential.user?.displayName == null) {
        // log(userCredential.toString());
        await userCredential.user!.updateDisplayName(
            userCredential.user!.providerData.last.displayName);
      }
      return userCredential.user;
    } catch (e) {
      print('Error signing in with Apple: $e');
      rethrow;
    }
  }
}
