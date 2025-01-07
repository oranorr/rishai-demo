import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/firebase/firebase_impl.dart';
import 'package:rishai/features/login/data/dara_sources/remote/remote_data_source.dart';

@Singleton(as: LoginRemoteDataSource)
class RemoteDataSourceImpl implements LoginRemoteDataSource {
  @override
  Future<User?> authorizeViaGoogle() async {
    try {
      return await firebase.login();
    } on Exception catch (__) {
      rethrow;
    }
  }

  @override
  Future<User?> authorizeViaApple() async {
    try {
      return await firebase.loginViaApple();
    } on Exception catch (__) {
      rethrow;
    }
  }
}
