import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/pefs/prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefsRepo = getIt.get<PrefsRepository>();

@Singleton()
class PrefsRepository {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> watchedOnboard() async {
    await _prefs.setBool(onboardWatched, true);
  }

  Future<void> setLogin(bool result) async {
    await _prefs.setBool(isLoggedIn, result);
  }

  bool checkIsLoggedIn() {
    return _prefs.getBool(onboardWatched) ?? false;
  }

  bool checkForWatchedOnboard() {
    return _prefs.getBool(onboardWatched) ?? false;
  }

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(whoopAccessToken, accessToken);
    await _prefs.setString(whoopRefreshToken, refreshToken);
  }

  String fetchSavedRefreshToken() {
    return _prefs.getString(whoopRefreshToken) ?? '';
  }

  Future<void> flush() async {
    await _prefs.clear();
  }

  Future<DateTime?> calibratingDate() async {
    final remaining = _prefs.getInt(calibrating);
    if (remaining != null) {
      final remainingDate = DateTime.fromMillisecondsSinceEpoch(remaining);
      final diff = DateTime.now().difference(remainingDate);
      // print(diff);
      if (diff.isNegative) {
        return null;
      } else {
        return remainingDate;
      }
    }
    final DateTime week = DateTime.now().add(const Duration(days: 7));
    final int setDate = week.millisecondsSinceEpoch;
    await _prefs.setInt(calibrating, setDate);
    return week;
  }

  Future<void> setNotifcationTime(String? time) async {
    if (time != null) {
      await _prefs.setString(notesTime, time);
    } else {
      await _prefs.remove(notesTime);
    }
  }

  String? getNoteTime() {
    return _prefs.getString(notesTime);
  }

  Future<void> clearTokens() async {
    await _prefs.setString(whoopAccessToken, '');
    await _prefs.setString(whoopRefreshToken, '');
  }
}
